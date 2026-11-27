import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../ai/domain/settings/builtin_templates.dart';
import '../../../../ai/domain/settings/prompt_template.dart';
import '../../../../ai/domain/variables/template_analysis.dart';
import '../../../../ai/state/ai_settings_providers.dart';
import '../../../../ai/state/prompt_template_ops.dart';
import '../../settings_routes.dart';
import 'ai_catalog_labels.dart';

final _log = Logger('settings.ai_prompts');

/// "Prompt mẫu": the prompts shown as chips on the chat input, in the order
/// the user sets. Reorder and switches apply at once; tapping a row opens its
/// editor, "Thêm prompt" opens an empty one.
class AiPromptsSection extends ConsumerWidget {
  const AiPromptsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final title = l10n.aiSetPromptsTitle;
    final rows = _rows(l10n, ref.watch(aiPromptsProvider));
    return SetupSection(
      title: Text(title),
      hint: l10n.aiSetPromptsHint,
      hintTooltip: l10n.settingsSectionHintTooltip(title),
      hintTitle: title,
      children: [
        if (rows.isEmpty)
          SetupNote(child: Text(l10n.aiSetPromptsEmpty))
        else
          ReorderableToggleList<int>(
            dragLabel: l10n.aiSetPromptDrag,
            keepOneOn: false,
            items: [
              for (final r in rows)
                _item(
                  context,
                  l10n,
                  r,
                  () => context.push(SettingsPaths.aiPrompt(r.index)),
                ),
            ],
            onReorder: (from, to) => _reorder(ref, rows, from, to),
            onToggle: (index, enabled) => _run(
              'switching a prompt',
              () => ref
                  .read(promptTemplateOpsProvider)
                  .toggle(index, enabled: enabled),
            ),
          ),
        SetupAddRow(
          icon: KIcons.add,
          label: Text(l10n.aiSetPromptAdd),
          onTap: () => context.push(SettingsPaths.aiPromptNew),
        ),
        SetupRowFrame(
          leading: const Icon(KIcons.reset),
          title: Text(l10n.aiSetPromptRestore),
          subtitle: Text(l10n.aiSetPromptRestoreDesc),
          onTap: () => _restore(context, ref),
        ),
      ],
    );
  }

  /// The templates this app version can show. A stored item it cannot read,
  /// or a builtin it has no text for, stays in the list but out of sight.
  List<_PromptRow> _rows(AppLocalizations l10n, List<PromptTemplate> list) {
    final rows = <_PromptRow>[];
    for (var i = 0; i < list.length; i++) {
      final t = list[i];
      if (t.isUnknown) continue;
      final key = t.key;
      final builtin = key == null ? null : builtinTemplateText(l10n, key);
      final label = t.label ?? builtin?.label;
      final body = t.body ?? builtin?.body;
      if (label == null || body == null) continue;
      rows.add(
        _PromptRow(index: i, enabled: t.enabled, label: label, body: body),
      );
    }
    return rows;
  }

  ReorderableToggleItem<int> _item(
    BuildContext context,
    AppLocalizations l10n,
    _PromptRow r,
    VoidCallback onOpen,
  ) {
    // One rule with the editor: an unknown variable is an error.
    final bad = analyzeTemplate(r.body, (_) => true).unknown.firstOrNull;
    return ReorderableToggleItem<int>(
      value: r.index,
      enabled: r.enabled,
      title: bad == null
          ? Text(r.label)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(r.label)),
                const KGap(KSpace.x2),
                KChip.tag(
                  label: Text(l10n.aiSetPromptBad),
                  tone: KTagTone.problem,
                ),
              ],
            ),
      switchLabel: l10n.aiSetPromptSwitch(r.label),
      tapLabel: l10n.aiSetPromptTap(r.label),
      // The problem replaces the line (no subtitle while there is one).
      subtitle: bad == null ? r.body : null,
      problem: bad == null ? null : l10n.aiSetPromptBadLine('{{${bad.name}}}'),
      onTap: onOpen,
    );
  }

  /// Moves the shown row [from] to [to] (the index it ends at among the shown
  /// rows) and sends the move in list indices: [PromptTemplateOps.reorder]
  /// takes the `ReorderableListView` form, one past the row it goes after.
  Future<void> _reorder(
    WidgetRef ref,
    List<_PromptRow> rows,
    int from,
    int to,
  ) async {
    if (from == to || from < 0 || to < 0) return;
    if (from >= rows.length || to >= rows.length) return;
    final target = rows[to].index + (to > from ? 1 : 0);
    await _run(
      'reordering the prompts',
      () =>
          ref.read(promptTemplateOpsProvider).reorder(rows[from].index, target),
    );
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    // Taken before the await: the context may be gone when the write ends.
    final messenger = ScaffoldMessenger.maybeOf(context);
    final have = {for (final t in ref.read(aiPromptsProvider)) t.key};
    final missing = BuiltinTemplateKeys.all
        .where((k) => !have.contains(k))
        .length;
    final ok = await _run(
      'restoring the default prompts',
      ref.read(promptTemplateOpsProvider).restoreDefaults,
    );
    if (!ok || messenger == null || !messenger.mounted) return;
    showAppSnackBarOn(
      messenger,
      missing == 0
          ? l10n.aiSetPromptRestoredNone
          : l10n.aiSetPromptRestored(missing),
    );
  }

  /// Runs an edit; the settings store reports a failing write on the page
  /// banner, so a failure here is only logged.
  Future<bool> _run(String what, Future<void> Function() edit) async {
    try {
      await edit();
      return true;
    } on Object catch (e, st) {
      _log.warning('$what failed', e, st);
      return false;
    }
  }
}

/// A shown prompt: its place in the stored list and its texts.
class _PromptRow {
  const _PromptRow({
    required this.index,
    required this.enabled,
    required this.label,
    required this.body,
  });

  final int index;
  final bool enabled;
  final String label;
  final String body;
}
