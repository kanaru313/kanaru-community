import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../ai/domain/variables/template_analysis.dart';
import '../../../../ai/domain/variables/variable_catalog.dart';
import '../settings_scaffold.dart';
import 'ai_catalog_labels.dart';
import 'prompt_editor_delete_block.dart';
import 'prompt_editor_fields.dart';
import 'prompt_editor_preview.dart';
import 'prompt_editor_text.dart';

/// The blocks of the prompt editor, top to bottom: Nhãn (no title), Prompt
/// with the insert chips, Xem trước and, for a saved prompt ([onDelete] set),
/// Xoá prompt.
List<Widget> promptEditorSections(
  BuildContext context, {
  required TextEditingController label,
  required FocusNode labelFocus,
  required TextEditingController body,
  required FocusNode bodyFocus,
  required TemplateAnalysis analysis,
  required PromptLine? line,
  required ValueChanged<AiVariable> onInsert,
  required bool builtin,
  required VoidCallback? onDelete,
}) {
  final l10n = AppLocalizations.of(context);
  final title = l10n.aiSetEdBodyTitle;
  final previewTitle = l10n.aiSetEdPreviewTitle;
  return [
    SettingsBlock(
      children: [PromptLabelField(controller: label, focusNode: labelFocus)],
    ),
    SetupSection(
      title: Text(title),
      hint: l10n.aiSetEdBodyHint(variableToken(AiVariable.input)),
      hintTooltip: l10n.settingsSectionHintTooltip(title),
      hintTitle: title,
      children: [
        PromptBodyField(
          controller: body,
          focusNode: bodyFocus,
          line: line,
          onInsert: onInsert,
        ),
      ],
    ),
    SetupSection(
      title: Text(previewTitle),
      hint: l10n.aiSetEdPreviewHint,
      hintTooltip: l10n.settingsSectionHintTooltip(previewTitle),
      hintTitle: previewTitle,
      children: [PromptPreview(body: body.text, analysis: analysis)],
    ),
    if (onDelete != null)
      PromptDeleteBlock(builtin: builtin, onDelete: onDelete),
  ];
}
