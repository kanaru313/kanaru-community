import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'line_translation.dart';
import 'translation_placeholder.dart';

/// Space between the original and the translation under it.
const double _gap = 2;

/// A lyric line with its translation, drawn in the ambient text style (the
/// main line): the original with the translation under it, or a bar while it
/// is coming. When the translation replaces the line it is the main line and
/// the original a small dim line above; a line without a translation stays
/// its original. Both lyric views use it, so the layout is written once.
///
/// The added lines keep one size and weight and only change colour with the
/// sung line, so a line never changes height when it becomes current.
class TranslatedLineText extends StatelessWidget {
  const TranslatedLineText({
    super.key,
    required this.original,
    required this.translation,
    required this.translationStyle,
    required this.originalStyle,
    required this.textAlign,
    required this.duration,
  });

  final String original;
  final LineTranslation translation;

  /// The translation under the original.
  final TextStyle translationStyle;

  /// The small original above a replacing translation.
  final TextStyle originalStyle;
  final TextAlign textAlign;

  /// How long a colour change takes.
  final Duration duration;

  Widget _added(String text, TextStyle style, {TextDirection? direction}) =>
      AnimatedDefaultTextStyle(
        style: style,
        duration: duration,
        curve: KMotion.emphasized,
        textAlign: textAlign,
        child: Text(text, textDirection: direction),
      );

  @override
  Widget build(BuildContext context) {
    final text = translation.text;
    final waiting = translation.pending && original.trim().isNotEmpty;
    if (text == null && !waiting) return Text(original);
    final direction = translation.rtl ? TextDirection.rtl : null;
    final children = <Widget>[
      if (text != null && translation.replace) ...[
        _added(original, originalStyle),
        Text(text, textDirection: direction),
      ] else ...[
        Text(original),
        const SizedBox(height: _gap),
        if (text != null)
          _added(text, translationStyle, direction: direction)
        else
          TranslationPlaceholder(
            style: translationStyle,
            centered: textAlign == TextAlign.center,
          ),
      ],
    ];
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
    if (text == null) return column;
    return Semantics(
      label: '$original, $text',
      excludeSemantics: true,
      child: column,
    );
  }
}
