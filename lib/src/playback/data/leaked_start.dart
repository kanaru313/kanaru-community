/// Whether the position read after an advance is the previous entry's resume
/// offset leaking into the new entry (media_kit's `on_load` hook can apply
/// it), so the engine should seek back to 0.
///
/// True only when the position is within [tolerance] of the offset and the
/// user did not seek since the advance: a later, unrelated position or a
/// user's seek must be left alone.
bool isLeakedStart({
  required Duration resumeStart,
  required double positionSeconds,
  required bool seekedSinceAdvance,
  Duration tolerance = const Duration(milliseconds: 750),
}) {
  if (resumeStart <= Duration.zero || seekedSinceAdvance) return false;
  final offset = resumeStart.inMicroseconds / 1e6;
  return (positionSeconds - offset).abs() <= tolerance.inMicroseconds / 1e6;
}
