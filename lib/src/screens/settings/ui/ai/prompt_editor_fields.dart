import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../ai/domain/settings/prompt_template.dart';
import '../../../../ai/domain/variables/variable_catalog.dart';
import 'ai_catalog_labels.dart';
import 'prompt_editor_text.dart';

/// A text controller that never holds more than [maxChars] code points: an
/// edit or a paste that would pass the limit is dropped and the text and
/// caret stay as they were (the end is never cut), the way a stored template
/// counts its limits.
class LimitedController extends TextEditingController {
  LimitedController({required this.maxChars, super.text});

  final int maxChars;

  @override
  set value(TextEditingValue newValue) {
    if (newValue.text.runes.length > maxChars) return;
    super.value = newValue;
  }

  /// Puts [insert] at the caret (at the end without one), replacing the
  /// selection, and leaves the caret after it. Nothing happens when the text
  /// would pass the limit.
  void insertAtCaret(String insert) {
    final sel = selection;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    value = TextEditingValue(
      text: text.replaceRange(start, end, insert),
      selection: TextSelection.collapsed(offset: start + insert.length),
    );
  }
}

/// The "Nhãn" field: the text on the chip.
class PromptLabelField extends StatelessWidget {
  const PromptLabelField({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(KSpace.x4),
      child: KTextFieldRow(
        controller: controller,
        focusNode: focusNode,
        label: l10n.aiSetEdLabel,
        hint: l10n.aiSetEdLabelPlaceholder,
        helper: l10n.aiSetEdLabelHelp,
        maxLength: promptLabelMaxChars,
      ),
    );
  }
}

/// The "Prompt" field and the "Chèn biến" chips under it. The line under the
/// field follows [line]: an error replaces it (red), a warning is its own
/// yellow line, nothing leaves the helper.
class PromptBodyField extends StatelessWidget {
  const PromptBodyField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.line,
    required this.onInsert,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final PromptLine? line;
  final ValueChanged<AiVariable> onInsert;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final shown = line;
    return Padding(
      padding: const EdgeInsets.all(KSpace.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KTextFieldRow(
            controller: controller,
            focusNode: focusNode,
            label: l10n.aiSetEdBodyTitle,
            hint: l10n.aiSetEdBodyPlaceholder(
              variableToken(AiVariable.nowPlaying),
              variableToken(AiVariable.lyrics),
            ),
            helper: l10n.aiSetEdBodyHelp,
            rows: 6,
            maxLength: promptBodyMaxChars,
            error: shown is PromptLineError ? shown.text : null,
            warning: shown is PromptLineWarning ? shown.text : null,
          ),
          const KGap(KSpace.x3),
          Semantics(
            container: true,
            label: l10n.aiSetEdVars,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      KIcons.variable,
                      size: KIconSize.xs,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: KSpace.x1),
                    Text(
                      '${l10n.aiSetEdVars}:',
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                for (final v in variableCatalog)
                  Tooltip(
                    message: variableDescription(l10n, v),
                    child: KChip.token(
                      label: Text(variableToken(v)),
                      semanticLabel: variableToken(v),
                      onTap: () => onInsert(v),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
