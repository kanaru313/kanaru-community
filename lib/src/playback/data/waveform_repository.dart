import 'dart:async';

import 'package:logging/logging.dart';

import '../../rust/api/error.dart';
import '../domain/waveform.dart';
import 'waveform_cache.dart';

final _log = Logger('waveform');

/// One load in progress; [cancel] frees the native decoder at its next packet
/// and ends the load with [RetryLater].
class WaveformLoad {
  WaveformLoad(this.result, this._cancel);

  final Future<WaveformResult> result;
  final void Function() _cancel;

  void cancel() => _cancel();
}

/// Waveform levels of local files: the disk cache first, then a native job.
///
/// Permanent failures (the format is not decoded, the file is damaged or over
/// the limits, the decoder crashed) are cached as negatives so the file is
/// not decoded again. Transient ones (cancelled, timed out, busy disk) are
/// never cached. A job that runs longer than [timeout] is cancelled, which
/// frees the single native waveform thread at its next packet.
class WaveformRepository {
  WaveformRepository({
    required this.cache,
    required this.start,
    this.timeout = const Duration(seconds: 20),
    this.maxTimeout = const Duration(seconds: 55),
    this.bytesPerSecond = 8 * 1024 * 1024,
  });

  final WaveformCache cache;
  final WaveformStarter start;

  /// The least a decode may take before it is given up.
  final Duration timeout;

  /// The most, however big the file. Under the native deadline (60 s), so
  /// the Dart side gives up first.
  final Duration maxTimeout;

  /// Decode speed assumed for the size of the file: a long track gets more
  /// time than a short one (the file size stands for its duration).
  final int bytesPerSecond;

  bool _swept = false;

  /// The native job that has not settled yet. The native side has one waveform
  /// thread, so a new job starts only after this one finished or was
  /// cancelled and ended: a stuck job holds one worker, never more.
  Future<void>? _nativeBusy;

  /// Timeouts in a row per cache key; two make the file a negative.
  final _timeouts = <String, int>{};

  /// Time a decode of a file of [size] bytes may take.
  Duration timeoutFor(int size) {
    final scaled =
        timeout + Duration(milliseconds: size * 1000 ~/ bytesPerSecond);
    return scaled > maxTimeout ? maxTimeout : scaled;
  }

  /// The cache key of the file at [path], or null when it cannot be read.
  Future<String?> cacheKey(String path) async {
    final stat = await statForKey(path);
    return stat == null ? null : waveformCacheKey(path, stat.$1, stat.$2);
  }

  /// What the cache holds for [path], without decoding: null when nothing.
  Future<WaveformResult?> peek(String path) async {
    final key = await cacheKey(path);
    return key == null ? null : cache.read(key);
  }

  /// Loads the waveform of [path]: cache hit, or a native decode.
  WaveformLoad load(String path) {
    var cancelled = false;
    final cancelSignal = Completer<void>();
    void Function()? cancelNative;
    Future<WaveformResult> run() async {
      final stat = await statForKey(path);
      if (stat == null) return const RetryLater();
      final key = waveformCacheKey(path, stat.$1, stat.$2);
      if (!_swept) {
        _swept = true;
        unawaited(cache.sweep());
      }
      final hit = await cache.read(key);
      if (hit != null) return hit;
      if (cancelled) return const RetryLater();
      final limit = timeoutFor(stat.$1);
      final busy = _nativeBusy;
      if (busy != null) {
        await Future.any([
          busy,
          cancelSignal.future,
          Future<void>.delayed(limit),
        ]);
        if (cancelled || _nativeBusy != null) return const RetryLater();
      }
      final (result, timedOut) = await _decode(
        path,
        limit,
        (c) => cancelNative = c,
      );
      if (timedOut) {
        final count = (_timeouts[key] ?? 0) + 1;
        if (count < 2) {
          _timeouts[key] = count;
          return result;
        }
        // Timed out twice in a row: this file is not worth another try.
        _timeouts.remove(key);
        final negative = NoWaveform(timedOutAt: cache.now());
        await cache.write(key, negative);
        return negative;
      }
      _timeouts.remove(key);
      await cache.write(key, result);
      return result;
    }

    final future = run();
    return WaveformLoad(future, () {
      cancelled = true;
      if (!cancelSignal.isCompleted) cancelSignal.complete();
      cancelNative?.call();
    });
  }

  /// The result, and whether the decode ran out of time.
  Future<(WaveformResult, bool)> _decode(
    String path,
    Duration limit,
    void Function(void Function()) onStart,
  ) async {
    final WaveformRun job;
    try {
      job = start(path);
    } on Object catch (e) {
      // The library is not loaded (a bare test) or refused to start.
      _log.warning('waveform job did not start: ${e.runtimeType}');
      return (const RetryLater(), false);
    }
    onStart(job.cancel);
    late final Future<void> busy;
    busy = job.result.then<void>((_) {}, onError: (_) {}).whenComplete(() {
      if (identical(_nativeBusy, busy)) _nativeBusy = null;
    });
    _nativeBusy = busy;
    try {
      final ready = await job.result.timeout(
        limit,
        onTimeout: () {
          job.cancel();
          throw TimeoutException('waveform decode timed out');
        },
      );
      return (ready.levels.isEmpty ? const NoWaveform() : ready, false);
    } on NativeError catch (e) {
      // The native deadline counts as a timeout, like the Dart one.
      return (_fromNativeError(e), e.kind == NativeErrorKind.timeout);
    } on TimeoutException {
      _log.info('waveform decode timed out');
      return (const RetryLater(), true);
    } on Object catch (e) {
      _log.warning('waveform decode failed: ${e.runtimeType}');
      return (const RetryLater(), false);
    }
  }

  /// Transient errors and kinds that say nothing lasting about the file are
  /// retried later; the permanent kinds become a cached negative.
  WaveformResult _fromNativeError(NativeError e) {
    _log.info('waveform error: ${e.kind.name}');
    if (e.transient) return const RetryLater();
    switch (e.kind) {
      case NativeErrorKind.unsupported:
      case NativeErrorKind.corrupt:
      case NativeErrorKind.tooLarge:
      case NativeErrorKind.panic:
        return const NoWaveform();
      case NativeErrorKind.io:
      case NativeErrorKind.notFound:
      case NativeErrorKind.permissionDenied:
      case NativeErrorKind.cancelled:
      case NativeErrorKind.timeout:
        // The file may come back or become readable: nothing is remembered.
        return const RetryLater();
    }
  }
}
