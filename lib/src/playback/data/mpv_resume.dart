import 'dart:math' as math;

import 'mpv_options.dart';

/// Seeks the freshly opened (paused) file to the resume offset [start],
/// clamped to its duration. Returns whether a seek was sent.
///
/// The offset is not given to media_kit as `Media(start:)`: media_kit keeps
/// that value for the life of its playlist and its `on_load` hook applies it
/// to every entry it later re-appends (repeat one) and, after a trim, to the
/// entry that follows. One seek after the file opened has no such effect.
///
/// Waits (briefly, polling) until mpv reports a duration, i.e. the file is
/// open. Gives up when mpv goes idle (the file failed to open), when
/// [disposed], or after [attempts] polls; the caller's own snapshot reports
/// the failure.
Future<bool> seekToResume(
  MpvConsole mpv,
  Duration start, {
  required bool Function() disposed,
  Duration pollEvery = const Duration(milliseconds: 50),
  int attempts = 100,
}) async {
  if (start <= Duration.zero) return false;
  for (var i = 0; i < attempts && !disposed(); i++) {
    final seconds = await _readDouble(mpv, 'duration');
    if (seconds != null && seconds > 0) {
      final target = math.min(start.inMicroseconds / 1e6, seconds);
      await mpv.command(['seek', target.toStringAsFixed(3), 'absolute']);
      return true;
    }
    if (await _readString(mpv, 'idle-active') == 'yes') return false;
    await Future<void>.delayed(pollEvery);
  }
  return false;
}

Future<String?> _readString(MpvProperties mpv, String name) async {
  try {
    return await mpv.get(name);
  } on Object {
    return null; // unavailable while nothing is loaded
  }
}

Future<double?> _readDouble(MpvProperties mpv, String name) async =>
    double.tryParse(await _readString(mpv, name) ?? '');
