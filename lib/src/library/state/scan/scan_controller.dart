import 'dart:async';

import 'package:logging/logging.dart';

import '../../data/scan/scan_pipeline_types.dart';
import '../../domain/scan_status.dart';
import 'native_resume.dart';
import 'scan_capabilities.dart';
import 'scan_miss_queue.dart';
import 'scan_status_throttle.dart';

export 'scan_miss_queue.dart' show TimerFactory;

final _log = Logger('library.scan');

/// Runs one scan pass over every enabled music folder.
typedef ScanPassRunner = Future<ScanOutcome> Function(
  ScanSession session,
  ScanHooks hooks, {
  required bool full,
});

/// Re-extracts the covers of the given keys (quiet: no status).
typedef CoverMissRunner = Future<ScanOutcome> Function(
  ScanSession session,
  ScanHooks hooks,
  Set<String> keys,
);

/// Runs scans one at a time and publishes their status.
///
/// Requests made while a scan runs collapse into one follow-up pass. Nothing
/// happens at construction: no timer, no I/O. Ports are reached only through
/// the runner functions, when a pass starts.
class ScanController
    implements LibraryScanCommands, ScanStartupWork, ScanOrigin {
  ScanController({
    required this.runPass,
    required this.runCoverMisses,
    required this.isSetupDone,
    required this.collectGarbage,
    required this.collectCoverFiles,
    Stream<String>? coverMisses,
    DateTime Function()? clock,
    TimerFactory? timer,
    this.startupDelay = const Duration(seconds: 2),
    this.garbageDelay = const Duration(seconds: 10),
    this.missDebounce = const Duration(seconds: 2),
    Duration statusInterval = const Duration(milliseconds: 300),
  }) : _clock = clock ?? DateTime.now,
       _timer = timer ?? Timer.new {
    _status = ScanStatusThrottle(
      interval: statusInterval,
      clock: _clock,
      timer: _timer,
    );
    _misses = CoverMissQueue(
      misses: coverMisses,
      accepting: () => !_disposed && isSetupDone(),
      timer: _timer,
      debounce: missDebounce,
      onDue: _kick,
    );
    _resume = NativeResume(
      session: _session,
      disposed: () => _disposed,
      scan: _requestScan,
    );
  }

  /// Runs one pass over the enabled folders (reads its ports when called).
  final ScanPassRunner runPass;
  final CoverMissRunner runCoverMisses;

  /// Reads `library.setup_done` from the store at call time.
  final bool Function() isSetupDone;
  final Future<void> Function() collectGarbage;

  /// Removes custom cover files no row refers to; runs right after
  /// [collectGarbage], on the same schedule. A failure is logged only.
  final Future<void> Function() collectCoverFiles;
  final Duration startupDelay, garbageDelay, missDebounce;
  final DateTime Function() _clock;
  final TimerFactory _timer;
  late final ScanStatusThrottle _status;
  late final CoverMissQueue _misses;
  late final NativeResume _resume;

  final ScanSession _session = ScanSession();
  bool _disposed = false;
  bool _looping = false;

  bool _scanQueued = false;
  bool _queuedFull = false;

  /// A scan was accepted in this session (the startup scan is then not needed).
  bool _scanRequested = false;
  bool _startupCalled = false;

  /// A caller of [rescan] asked for the scan that is queued or running.
  bool _callerScan = false;
  bool _finishWasRequested = false;
  Timer? _startupTimer, _garbageTimer;

  /// Tracks new in the scans since the last published summary; kept across
  /// a pass that failed with a native call still pending, so the automatic
  /// scan that follows publishes the sum.
  int _added = 0;

  /// [_added] belongs to a failed pass that left a native call pending, and
  /// waits for the automatic resume. A request from outside drops it.
  bool _keptForResume = false;

  bool _garbageWanted = false;
  bool _garbageSinceStartup = false;

  @override
  bool get lastFinishWasRequested => _finishWasRequested;

  /// Status stream; a new listener first gets the latest value.
  Stream<ScanStatus> get status => _status.stream;

  @override
  Future<void> rescan({bool full = false}) async {
    try {
      if (_disposed) return;
      if (!isSetupDone()) {
        _log.info('rescan(full: $full) ignored: setup is not done');
        return;
      }
      // A request from outside while nothing runs starts a fresh summary:
      // a count kept for an automatic resume that never came is dropped.
      if (_keptForResume || !_looping) _resetAdded();
      _callerScan = true;
      _requestScan(full: full);
    } on Object catch (e, st) {
      _log.severe('rescan failed', e, st);
    }
  }

  /// Called once by Home after its first frame. When setup is done and no
  /// scan was requested yet, scans after a short delay; collects orphan
  /// tracks a little later. Starts nothing while setup is not done.
  @override
  void ensureStartupWork() {
    if (_disposed || _startupCalled) return;
    _startupCalled = true;
    _garbageSinceStartup = false;
    try {
      if (!isSetupDone()) return;
    } on Object catch (e, st) {
      _log.severe('could not read the setup flag', e, st);
      return;
    }
    if (!_scanRequested) {
      _startupTimer = _timer(startupDelay, () {
        _startupTimer = null;
        if (!_disposed && !_scanRequested) _requestScan();
      });
    }
    _garbageTimer = _timer(startupDelay + garbageDelay, () {
      _garbageTimer = null;
      if (_disposed || _garbageSinceStartup) return;
      // Through the loop, so it never runs next to a scan.
      _garbageWanted = true;
      _kick();
    });
  }

  void _requestScan({bool full = false}) {
    _scanRequested = true;
    _scanQueued = true;
    _queuedFull = _queuedFull || full;
    _kick();
  }

  void _resetAdded() {
    _added = 0;
    _keptForResume = false;
  }

  void _kick() {
    if (_looping || _disposed) return;
    _looping = true;
    unawaited(_loop());
  }

  ScanHooks get _hooks =>
      ScanHooks(onStatus: _status.progress, shouldStop: () => _disposed);

  Future<void> _loop() async {
    try {
      while (!_disposed) {
        if (_scanQueued) {
          final full = _queuedFull;
          _scanQueued = false;
          _queuedFull = false;
          final requested = _callerScan;
          _callerScan = false;
          // The pass that runs now is the resume the count waited for.
          _keptForResume = false;
          final out = await _guarded(
            () => runPass(_session, _hooks, full: full),
          );
          if (_disposed) break;
          _added += out.added;
          _resume.watch(out);
          if (_scanQueued) continue; // a follow-up covers the rest
          final counts = out.counts;
          if (out.failureKind != null) {
            _status.finish(ScanFailed(out.failureKind!));
            if (out.pending.isEmpty) {
              _resetAdded();
            } else {
              _keptForResume = true;
            }
          } else if (counts != null) {
            // Set before publishing, so a reader of the status sees it.
            _finishWasRequested = requested;
            _status.finish(
              ScanFinished(
                tracks: counts.tracks,
                albums: counts.albums,
                artists: counts.artists,
                added: _added,
                at: _clock(),
              ),
            );
            _resetAdded();
            await _runGarbage();
          }
        } else if (_misses.ready) {
          final keys = _misses.take();
          final out = await _guarded(
            () => runCoverMisses(_session, _hooks, keys),
          );
          if (_disposed) break;
          _resume.watch(out);
          if (out.failureKind != null) {
            _log.warning('cover re-extract ended: ${out.failureKind}');
          }
        } else {
          break;
        }
      }
      if (_garbageWanted && !_disposed) await _runGarbage();
    } finally {
      _looping = false;
      if (!_disposed && (_scanQueued || _misses.ready)) {
        _kick();
      }
    }
  }

  /// Turns an unexpected error into a failed outcome.
  Future<ScanOutcome> _guarded(Future<ScanOutcome> Function() run) async {
    try {
      return await run();
    } on Object catch (e, st) {
      _log.severe('scan failed unexpectedly', e, st);
      return ScanOutcome()..failureKind = 'io';
    }
  }

  Future<void> _runGarbage() async {
    _garbageWanted = false;
    _garbageSinceStartup = true;
    try {
      await collectGarbage();
    } on Object catch (e, st) {
      _log.severe('garbage collection failed', e, st);
    }
    try {
      await collectCoverFiles();
    } on Object catch (e, st) {
      _log.severe('custom cover cleanup failed', e, st);
    }
  }

  /// Stops any running scan before its next batch and releases timers.
  void dispose() {
    _disposed = true;
    _startupTimer?.cancel();
    _garbageTimer?.cancel();
    _misses.dispose();
    _status.dispose();
  }
}
