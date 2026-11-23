import '../../domain/online/lyrics_match.dart';

/// "4:12": a track length.
String formatTrackLength(Duration length) {
  final seconds = length.inSeconds;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

/// How a result's length compares with the song's.
enum ResultDeltaKind { match, longer, shorter }

/// The difference of a result's length against the song's: "khớp" when it is
/// within [maxDurationDelta] (also the automatic match threshold), else the
/// whole seconds it is longer or shorter, rounded up so a 3.4 s gap never
/// reads as the "+3 s" that the threshold calls a match.
class ResultDelta {
  const ResultDelta(this.kind, this.seconds);

  final ResultDeltaKind kind;

  /// Zero for [ResultDeltaKind.match].
  final int seconds;

  @override
  bool operator ==(Object other) =>
      other is ResultDelta && other.kind == kind && other.seconds == seconds;

  @override
  int get hashCode => Object.hash(kind, seconds);
}

/// The [ResultDelta] of [result] against [song]; null when either length is
/// unknown (the row then shows no difference).
ResultDelta? resultDelta(Duration? result, Duration? song) {
  if (result == null || song == null) return null;
  final diff = result - song;
  if (diff.abs() <= maxDurationDelta) {
    return const ResultDelta(ResultDeltaKind.match, 0);
  }
  final seconds = (diff.abs().inMilliseconds / 1000).ceil();
  return ResultDelta(
    diff.isNegative ? ResultDeltaKind.shorter : ResultDeltaKind.longer,
    seconds,
  );
}
