import 'package:material_ui/material_ui.dart';

import '../../domain/variables/template_analysis.dart';
import '../../domain/variables/variable_catalog.dart';

/// Whether an input method is composing text (an unfinished word, not a bare
/// cursor). While it does, the field must not act on Enter or on `{{`.
bool isComposing(TextEditingValue value) =>
    value.composing.isValid && !value.composing.isCollapsed;

/// The text field's controller: it paints the `{{variables}}` of the text.
///
/// A variable of a group that is off, or one the last send could not fill
/// ([missing]), is painted as a warning. The range an input method is
/// composing keeps its underline inside a painted variable, as the default
/// rendering draws it.
class ComposerTextController extends TextEditingController {
  ComposerTextController.fromValue(super.value) : super.fromValue();

  /// Whether the privacy group of a variable is on; set by the field.
  ToolGroupSwitches groupEnabled = (_) => true;

  /// Names of variables the last send refused for lack of data; set by the
  /// field. Shown as warnings until the text changes.
  Set<String> missing = const {};

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final ok = TextStyle(
      color: scheme.primary,
      backgroundColor: scheme.primaryContainer.withValues(alpha: 0.5),
    );
    final warn = TextStyle(
      color: scheme.onTertiaryContainer,
      backgroundColor: scheme.tertiaryContainer,
    );
    return buildComposerSpan(
      text: text,
      composing: withComposing ? value.composing : TextRange.empty,
      style: style,
      spans: analyzeTemplate(text, groupEnabled).spans,
      styleOf: (s) => switch (s.kind) {
        TemplateSpanKind.unknown => null,
        TemplateSpanKind.groupOff => warn,
        TemplateSpanKind.ok => missing.contains(s.name) ? warn : ok,
      },
    );
  }
}

/// The text cut at every variable and composing edge, each piece styled by
/// the variable it sits in and underlined while composing.
TextSpan buildComposerSpan({
  required String text,
  required TextRange composing,
  required TextStyle? style,
  required List<TemplateSpan> spans,
  required TextStyle? Function(TemplateSpan span) styleOf,
}) {
  final length = text.length;
  final composed = composing.isValid && !composing.isCollapsed
      ? TextRange(
          start: composing.start.clamp(0, length),
          end: composing.end.clamp(0, length),
        )
      : null;
  final cuts = <int>{
    0,
    length,
    for (final s in spans) ...[s.start, s.end],
    ?composed?.start,
    ?composed?.end,
  }.toList()..sort();
  final children = <TextSpan>[];
  for (var i = 0; i + 1 < cuts.length; i++) {
    final from = cuts[i];
    final to = cuts[i + 1];
    if (from == to) continue;
    TextStyle? piece;
    for (final s in spans) {
      if (s.start <= from && to <= s.end) {
        piece = styleOf(s);
        break;
      }
    }
    if (composed != null && composed.start <= from && to <= composed.end) {
      piece = (piece ?? const TextStyle()).merge(
        const TextStyle(decoration: TextDecoration.underline),
      );
    }
    children.add(TextSpan(text: text.substring(from, to), style: piece));
  }
  return TextSpan(style: style, children: children);
}
