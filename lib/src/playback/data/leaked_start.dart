import 'mpv_append.dart';

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

/// Puts the position back to 0 when the resume offset [leaked] was applied to
/// the entry mpv advanced to. The offset is applied while the file opens, so
/// this waits (briefly) until mpv reports a position. [seekedSinceAdvance]
/// is read at that moment, so a user seek during the wait is left alone.
Future<void> undoLeakedStart(
  MpvConsole mpv, {
  required Duration leaked,
  required bool Function() seekedSinceAdvance,
  required bool Function() disposed,
  Duration pollEvery = const Duration(milliseconds: 50),
}) async {
  if (leaked <= Duration.zero) return;
  for (var i = 0; i < 10 && !disposed(); i++) {
    double? at;
    try {
      at = double.tryParse(await mpv.get('time-pos'));
    } on Object {
      at = null; // not open yet
    }
    if (at != null) {
      if (isLeakedStart(
        resumeStart: leaked,
        positionSeconds: at,
        seekedSinceAdvance: seekedSinceAdvance(),
      )) {
        await mpv.command(['seek', '0', 'absolute']);
      }
      return;
    }
    await Future<void>.delayed(pollEvery);
  }
}
