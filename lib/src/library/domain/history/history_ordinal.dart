/// The "nth play of this song" number of every play of one year, from counts
/// already read, so no per-row subquery is needed.
///
/// [trackIds] are the track ids of the year's plays, newest first (the order
/// `played_at DESC, id DESC`). [playCount] is each track's live play count
/// over all time, [afterYear] its live plays after the year. Walking newest to
/// oldest, the plays of a track later than this one are the plays after the
/// year plus the ones already seen in the year, so
/// `ordinal = playCount - afterYear - laterInYear`. Two plays in the same
/// millisecond follow the list order. A track with inconsistent counts yields
/// at least 1 rather than 0 or a negative number.
List<int> assignOrdinals(
  List<int> trackIds, {
  required Map<int, int> playCount,
  required Map<int, int> afterYear,
}) {
  final laterInYear = <int, int>{};
  final ordinals = List<int>.filled(trackIds.length, 1);
  for (var i = 0; i < trackIds.length; i++) {
    final t = trackIds[i];
    final later = laterInYear[t] ?? 0;
    final n = (playCount[t] ?? 0) - (afterYear[t] ?? 0) - later;
    ordinals[i] = n < 1 ? 1 : n;
    laterInYear[t] = later + 1;
  }
  return ordinals;
}
