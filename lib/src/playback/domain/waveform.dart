import 'dart:typed_data';

/// What loading the waveform of one file gave.
sealed class WaveformResult {
  const WaveformResult();
}

/// Levels (0..255, at most 1000) and the length of audio they were measured
/// on. The repository never returns empty levels: a track too short to draw
/// is [NoWaveform].
final class Ready extends WaveformResult {
  const Ready(this.levels, this.durationMs);

  final Uint8List levels;
  final int durationMs;
}

/// This file has no waveform and never will (format not decoded, damaged,
/// over the limits, a decoder crash). Remembered in the cache.
///
/// [timedOutAt] is set for a negative that came from timeouts rather than
/// from the file itself; such a negative expires (see `WaveformCache`).
final class NoWaveform extends WaveformResult {
  const NoWaveform({this.timedOutAt});

  final DateTime? timedOutAt;
}

/// Nothing is known (cancelled, timed out, busy disk, a failure that says
/// nothing about the file). Never cached; tried again only for a new entry or
/// a new view.
final class RetryLater extends WaveformResult {
  const RetryLater();
}

/// What the Now Playing seek bar draws for one queue entry.
class WaveformView {
  const WaveformView({
    required this.entryId,
    this.levels,
    this.durationMs = 0,
    this.instant = false,
  });

  /// Nothing is playing.
  static const none = WaveformView(entryId: null);

  /// The entry the levels belong to; a view of another entry is not drawn.
  final int? entryId;

  /// Null while loading or when the file has no waveform: the bar is flat.
  final Uint8List? levels;

  /// Length of audio the levels were measured on.
  final int durationMs;

  /// The levels were known when the entry changed: show them without a fade.
  final bool instant;
}

/// A waveform job running in the native library.
typedef WaveformRun = ({Future<Ready> result, void Function() cancel});

/// Starts a native waveform job for the file at a path. The result throws
/// the library's error on failure.
typedef WaveformStarter = WaveformRun Function(String path);
