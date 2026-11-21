import 'package:material_ui/material_ui.dart';

import '../domain/lyrics_display_prefs.dart';

/// Synced line: every line has the same size and weight; only the colour and
/// the scale (done by the line widget) tell the current one. Others are
/// `onSurface` at the user's dim level.
TextStyle lyricsLineStyle(
  BuildContext context, {
  required double size,
  required bool current,
  required LyricsDim dim,
}) {
  final scheme = Theme.of(context).colorScheme;
  return Theme.of(context).textTheme.bodyLarge!.copyWith(
    fontSize: size,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0,
    color: current
        ? scheme.onSurface
        : scheme.onSurface.withValues(alpha: dim.alpha),
  );
}

/// Plain lyrics: smaller, regular, all the same colour (no highlight).
TextStyle lyricsPlainStyle(BuildContext context, {required double size}) {
  return Theme.of(context).textTheme.bodyLarge!.copyWith(
    fontSize: size,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
    color: Theme.of(context).colorScheme.onSurface,
  );
}

/// The note above plain lyrics.
TextStyle? lyricsNoteStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

/// [LyricsAlign] as a text alignment.
TextAlign lyricsTextAlign(LyricsAlign align) =>
    align == LyricsAlign.center ? TextAlign.center : TextAlign.start;
