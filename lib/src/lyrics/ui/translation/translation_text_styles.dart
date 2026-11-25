import 'package:material_ui/material_ui.dart';

import '../../domain/lyrics_display_prefs.dart';
import '../../domain/translation/translation_size.dart';

/// Share of `onSurface` the sung line's translation has.
const double _currentAlpha = 0.64;

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
  required TranslationSize size,
}) => _scaled(line, size.translation, _syncedColor(context, current, dim));

/// The small dim original above the translation of a replaced synced line.
TextStyle lyricsReplacedOriginalStyle(
  BuildContext context, {
  required TextStyle line,
  required bool current,
  required LyricsDim dim,
  required TranslationSize size,
}) => _scaled(line, size.replacedOriginal, _syncedColor(context, current, dim));

/// The translation under a plain-lyrics line.
TextStyle plainTranslationStyle(
  BuildContext context,
  TextStyle plain,
  TranslationSize size,
) => _scaled(
  plain,
  size.plainTranslation,
  Theme.of(context).colorScheme.onSurfaceVariant,
).copyWith(fontWeight: plain.fontWeight);

/// The small original above the translation of a replaced plain line.
TextStyle plainReplacedOriginalStyle(
  BuildContext context,
  TextStyle plain,
  TranslationSize size,
) => _scaled(
  plain,
  size.plainReplacedOriginal,
  Theme.of(context).colorScheme.onSurfaceVariant,
).copyWith(fontWeight: plain.fontWeight);

/// The translation of the sung line on the Now Playing card.
TextStyle cardTranslationStyle(
  BuildContext context,
  TextStyle line,
  TranslationSize size,
) => line.copyWith(
  fontSize: size.card,
  fontWeight: FontWeight.w500,
  height: size.cardLineHeight / size.card,
  color: Theme.of(context).colorScheme.onSurface
      .withValues(alpha: _currentAlpha),
);
