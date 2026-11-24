import 'package:material_ui/material_ui.dart';

import '../../domain/lyrics_display_prefs.dart';

/// Translation under a synced line: this fraction of the line's size.
const double translationScale = 0.62;

/// The original of a replaced line: this fraction of the line's size.
const double replacedOriginalScale = 0.5;

/// Plain lyrics: the translation and the replaced original, as fractions of
/// the plain text size.
const double plainTranslationScale = 0.8;
const double plainReplacedOriginalScale = 0.7;

/// Share of `onSurface` the sung line's translation has.
const double _currentAlpha = 0.64;

/// Size of the translation of the sung line on the Now Playing card.
const double cardTranslationSize = 13;

TextStyle _scaled(TextStyle line, double scale, Color color) => line.copyWith(
  fontSize: (line.fontSize ?? 16) * scale,
  fontWeight: FontWeight.w500,
  color: color,
);

Color _syncedColor(BuildContext context, bool current, LyricsDim dim) {
  final onSurface = Theme.of(context).colorScheme.onSurface;
  // Other lines are as dim as the lyrics are, but never dimmer than the sung
  // line's translation (the "no dimming" level would make them brighter).
  final alpha = current
      ? _currentAlpha
      : dim.alpha < _currentAlpha
      ? dim.alpha
      : _currentAlpha;
  return onSurface.withValues(alpha: alpha);
}

/// The translation under (or the main text of a replaced) synced [line].
TextStyle lyricsTranslationStyle(
  BuildContext context, {
  required TextStyle line,
  required bool current,
  required LyricsDim dim,
}) => _scaled(line, translationScale, _syncedColor(context, current, dim));

/// The small dim original above the translation of a replaced synced line.
TextStyle lyricsReplacedOriginalStyle(
  BuildContext context, {
  required TextStyle line,
  required bool current,
  required LyricsDim dim,
}) => _scaled(line, replacedOriginalScale, _syncedColor(context, current, dim));

/// The translation under a plain-lyrics line.
TextStyle plainTranslationStyle(BuildContext context, TextStyle plain) =>
    _scaled(
      plain,
      plainTranslationScale,
      Theme.of(context).colorScheme.onSurfaceVariant,
    ).copyWith(fontWeight: plain.fontWeight);

/// The small original above the translation of a replaced plain line.
TextStyle plainReplacedOriginalStyle(BuildContext context, TextStyle plain) =>
    _scaled(
      plain,
      plainReplacedOriginalScale,
      Theme.of(context).colorScheme.onSurfaceVariant,
    ).copyWith(fontWeight: plain.fontWeight);

/// The translation of the sung line on the Now Playing card.
TextStyle cardTranslationStyle(BuildContext context, TextStyle line) =>
    line.copyWith(
      fontSize: cardTranslationSize,
      fontWeight: FontWeight.w500,
      height: 18 / cardTranslationSize,
      color: Theme.of(context).colorScheme.onSurface
          .withValues(alpha: _currentAlpha),
    );
