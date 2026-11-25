import 'dart:async';

import 'package:logging/logging.dart';

import '../../media/domain/track_id.dart';
import '../data/waveform_repository.dart';
import '../domain/waveform.dart';

final _log = Logger('waveform_loader');

/// The two queue entries whose waveform is wanted: the current one first,
/// then the next in play order.
class WaveformWant {
  const WaveformWant({
    this.currentEntry,
    this.currentTrack,
    this.nextEntry,
    this.nextTrack,
  });

  static const none = WaveformWant();

  final int? currentEntry;
  final TrackId? currentTrack;
  final int? nextEntry;
  final TrackId? nextTrack;

  @override
  bool operator ==(Object other) =>
      other is WaveformWant &&
      other.currentEntry == currentEntry &&
      other.currentTrack == currentTrack &&
      other.nextEntry == nextEntry &&
      other.nextTrack == nextTrack;

  @override
  int get hashCode =>
      Object.hash(currentEntry, currentTrack, nextEntry, nextTrack);
}

/// The local file of a track, or null when it has none to decode.
typedef WaveformPathOf = Future<String?> Function(TrackId id);

/// Decides what to decode and when; the memory behind the Now Playing seek
/// bar. It decodes only while somebody watches [watch] (a seek bar is
/// mounted): with Now Playing closed nothing is decoded.
///
/// One native job runs at a time, the current entry before the next one.
/// A job for an entry that is neither is cancelled, and every job is when the
/// watcher goes away. Results for files are kept in a small LRU, so going
/// back to a track is instant.
class WaveformLoader {
  WaveformLoader({
    required this.repository,
    required this.pathOf,
    this.memoryEntries = 8,
  });

  final WaveformRepository repository;
  final WaveformPathOf pathOf;
  final int memoryEntries;

  final _memory = <String, WaveformResult>{};

  /// The memory is keyed by the cache key (path, size, mtime), so a file that
  /// changed on disk is not answered from an old result.
  WaveformResult? _remembered(String? key) {
    if (key == null) return null;
    final hit = _memory.remove(key);
    if (hit != null) _memory[key] = hit;
    return hit;
  }

  void _remember(String? key, WaveformResult result) {
    if (key == null) return;
    _memory.remove(key);
    _memory[key] = result;
    while (_memory.length > memoryEntries) {
      _memory.remove(_memory.keys.first);
    }
  }

  /// The local file of [id]; a lookup that fails means no local file.
  Future<String?> _safePath(TrackId id) async {
    try {
      return await pathOf(id);
    } on Object catch (e) {
      // Only the type: the message may name a path.
      _log.warning('no local file for a track: ${e.runtimeType}');
      return null;
    }
  }

  /// The views for [wants], until the returned stream is cancelled.
  Stream<WaveformView> watch(Stream<WaveformWant> wants) {
    late final _Session session;
    final out = StreamController<WaveformView>(onCancel: () => session.close());
    session = _Session(this, out);
    out.onListen = () => session.listen(wants);
    return out.stream;
  }
}

class _Session {
  _Session(this._loader, this._out);

  final WaveformLoader _loader;
  final StreamController<WaveformView> _out;
  StreamSubscription<WaveformWant>? _wants;
  WaveformWant _want = WaveformWant.none;
  bool _closed = false;

  /// Entries whose attempt failed for a reason that says nothing about the
  /// file (timeout, busy disk), in this session. They show [WaveformStatus.none]
  /// and are not tried again until a new session (a new view). The one set
  /// serves both the display and "do not start again".
  final _failed = <int>{};
  int? _runningEntry;
  WaveformLoad? _running;

  /// The entry whose job this session cancelled because it is no longer
  /// wanted; that is not a failure, so the entry may be tried again.
  int? _cancelledEntry;
  bool _pumping = false;

  /// The decision of what the bar shows first for the current entry; the
  /// jobs wait for it, so a cached waveform is never decoded.
  Future<void> _showing = Future.value();

  /// The path of the current entry once resolved, and the entry it is for.
  int? _viewEntry;

  void listen(Stream<WaveformWant> wants) {
    _wants = wants.listen(_onWant);
  }

  Future<void> close() async {
    _closed = true;
    _running?.cancel();
    await _wants?.cancel();
  }

  void _emit(WaveformView view) {
    if (!_closed && !_out.isClosed) _out.add(view);
  }

  void _onWant(WaveformWant want) {
    final previous = _want;
    _want = want;
    final running = _runningEntry;
    if (running != null &&
        running != want.currentEntry &&
        running != want.nextEntry) {
      _cancelledEntry = running;
      _running?.cancel();
    }
    if (want.currentEntry != previous.currentEntry ||
        want.currentTrack != previous.currentTrack) {
      _showing = _showCurrent(want);
    }
    unawaited(_pump());
  }

  /// Decides at the entry change what the bar shows first: the levels when
  /// they are known (memory or disk cache), none when no answer can come
  /// (no local file, a known negative, a failure earlier in this session),
  /// else computing.
  Future<void> _showCurrent(WaveformWant want) async {
    final entry = want.currentEntry;
    final track = want.currentTrack;
    if (entry == null || track == null) {
      _viewEntry = null;
      _emit(WaveformView.none);
      return;
    }
    if (_failed.contains(entry)) {
      _viewEntry = entry;
      _emit(_viewOf(entry, null, none: true));
      return;
    }
    final path = await _loader._safePath(track);
    if (_closed || _want.currentEntry != entry) return;
    WaveformResult? known;
    if (path != null) {
      final key = await _loader.repository.cacheKey(path);
      known = _loader._remembered(key) ?? await _loader.repository.peek(path);
      if (_closed || _want.currentEntry != entry) return;
      // A job (the prefetch of this entry) may have ended while we waited.
      known ??= _loader._remembered(key);
      if (known != null && known is! RetryLater) _loader._remember(key, known);
    }
    _viewEntry = entry;
    // No file to decode: no job will ever run for this entry. A failure that
    // landed while we waited also leaves no answer coming.
    _emit(
      _viewOf(
        entry,
        known,
        none: path == null || (known == null && _failed.contains(entry)),
      ),
    );
  }

  /// [none] forces the status for an entry that has no answer coming.
  WaveformView _viewOf(
    int entry,
    WaveformResult? result, {
    bool none = false,
  }) => switch (result) {
    Ready(:final levels, :final durationMs) => WaveformView(
      entryId: entry,
      status: WaveformStatus.ready,
      levels: levels,
      durationMs: durationMs,
    ),
    NoWaveform() => WaveformView(entryId: entry, status: WaveformStatus.none),
    _ => WaveformView(
      entryId: entry,
      status: none ? WaveformStatus.none : WaveformStatus.computing,
    ),
  };

  /// Runs the next wanted job, if none runs. Serial: one native job at a time.
  Future<void> _pump() async {
    if (_pumping) return;
    _pumping = true;
    try {
      while (!_closed) {
        await _showing;
        final next = await _nextTarget();
        if (next == null || _closed) return;
        final (entry, path) = next;
        final key = await _loader.repository.cacheKey(path);
        final load = _loader.repository.load(path);
        _running = load;
        _runningEntry = entry;
        final result = await load.result;
        _running = null;
        _runningEntry = null;
        final cancelledByUs = _cancelledEntry == entry;
        if (cancelledByUs) _cancelledEntry = null;
        // A retry waits for a new view; an entry dropped because the queue
        // moved on is no failure.
        final failed = result is RetryLater && !cancelledByUs;
        if (failed) _failed.add(entry);
        if (_closed) return;
        if (result is! RetryLater) _loader._remember(key, result);
        if ((result is! RetryLater || failed) &&
            _want.currentEntry == entry &&
            _viewEntry == entry) {
          _emit(_viewOf(entry, result, none: failed));
        }
      }
    } finally {
      _pumping = false;
    }
  }

  /// The first of current, next that has a file, no known result and has not
  /// failed yet; with its path.
  Future<(int, String)?> _nextTarget() async {
    for (final (entry, track) in [
      (_want.currentEntry, _want.currentTrack),
      (_want.nextEntry, _want.nextTrack),
    ]) {
      if (entry == null || track == null || _failed.contains(entry)) continue;
      final path = await _loader._safePath(track);
      if (_closed) return null;
      if (path == null) continue;
      if (_loader._remembered(await _loader.repository.cacheKey(path)) !=
          null) {
        continue;
      }
      if (entry != _want.currentEntry && entry != _want.nextEntry) continue;
      return (entry, path);
    }
    return null;
  }
}
