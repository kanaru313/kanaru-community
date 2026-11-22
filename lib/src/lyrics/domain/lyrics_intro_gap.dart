import 'lyrics.dart';

/// A first sung line starting at or after this gets a gap line before it.
const Duration introGapThreshold = Duration(seconds: 5);

/// [lyrics] as shown: synced lyrics whose first line is sung and starts at
/// [introGapThreshold] or later get a gap line at time zero, so the intro is
/// the current line. Plain lyrics, a first line that is itself a gap and
/// earlier starts come back unchanged (the same object).
Lyrics withIntroGap(Lyrics lyrics) {
  if (!lyrics.synced || lyrics.lines.isEmpty) return lyrics;
  final first = lyrics.lines.first;
  if (first.isGap || first.time < introGapThreshold) return lyrics;
  return Lyrics(
    lines: [const LyricLine(Duration.zero, ''), ...lyrics.lines],
    synced: true,
    origin: lyrics.origin,
  );
}
