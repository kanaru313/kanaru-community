import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/domain/config/config_field.dart';
import '../../../plugins/state/config_form_provider.dart';
import 'config_checks.dart';
import 'config_texts.dart';

/// The picker of a `custom` select: the field's options, the user's own ones
/// marked "Tự thêm" with a ✕ that removes them (the picker stays open and
/// follows the stored choices), and a footer that adds one. [onChoose] saves
/// a pick and the picker closes; [onAdd] opens the add box and resolves to
/// null when the user gave up, else the store's answer (a written one closes
/// the picker, the choice is selected).
///
/// The frame, rows, ✕, footer and error line are `showSelectionPicker`'s; this
/// only feeds it the stored options and turns the store's answers into texts.
Future<void> showCustomChoicePicker(
  BuildContext context, {
  required String installId,
  required SelectField field,
  required String title,
  required GlobalKey anchor,
  required void Function(String value) onChoose,
  required Future<ConfigWrite> Function(String value) onRemove,
  required Future<ConfigWrite?> Function(BuildContext context) onAdd,
}) async {
  final l10n = AppLocalizations.of(context);
  final container = ProviderScope.containerOf(context);
  final provider = configFormProvider(installId);

  var current = field;
  SelectionPickerState<String> stateOf() {
    final data = container.read(provider).value;
    final live = data?.field(field.key);
    current = live is SelectField ? live : field;
    return SelectionPickerState(
      selected: switch (data?.valueOf(current)) {
        final String v => v,
        _ => null,
      },
      options: [
        for (final o in current.options)
          SelectionOption(
            value: o.value,
            title: _title(l10n, o, data?.isOwn(field.key, o.value) ?? false),
            subtitle: o.subtitle == null ? null : Text(o.subtitle!),
            hint: o.subtitle,
            removeTooltip: (data?.isOwn(field.key, o.value) ?? false)
                ? l10n.pluginsCfgRemoveModel
                : null,
            onRemove: (data?.isOwn(field.key, o.value) ?? false)
                ? () async {
                    final result = await onRemove(o.value);
                    return result == ConfigWrite.written
                        ? null
                        : configRefusalText(l10n, result);
                  }
                : null,
          ),
      ],
    );
  }

  final live = ValueNotifier(stateOf());
  final sub = container.listen(provider, (_, _) => live.value = stateOf());
  try {
    final chosen = await showSelectionPicker<String>(
      context,
      anchor: anchor,
      title: Text(title),
      header: field.subtitle == null ? null : pickerCaption(context, field),
      options: live.value.options,
      selected: live.value.selected,
      live: live,
      errorText: configRefusalText(l10n, ConfigWrite.failed),
      footerAction: SelectionPickerAction(
        label: l10n.pluginsCfgAddModel,
        onPressed: (pickerContext) async {
          if (current.options.length >= configMaxItems) {
            return SelectionActionResult.error(
              configIssueText(
                l10n,
                const ConfigIssue(ConfigIssueKind.tooManyItems, configMaxItems),
              ),
            );
          }
          final result = await onAdd(pickerContext);
          return switch (result) {
            null => const SelectionActionResult.stay(),
            ConfigWrite.written => const SelectionActionResult.close(),
            _ => SelectionActionResult.error(configRefusalText(l10n, result)),
          };
        },
      ),
    );
    if (chosen != null) onChoose(chosen);
  } finally {
    sub.close();
    live.dispose();
  }
}

/// The option's name, with the "own" tag after it for the user's choices.
Widget _title(AppLocalizations l10n, ConfigOption option, bool own) => Row(
  children: [
    Flexible(
      child: Text(option.title, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
    if (own) ...[
      const KGap(KSpace.x2),
      KChip.tag(label: Text(l10n.pluginsCfgOwnTag)),
    ],
  ],
);
