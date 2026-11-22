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
/// Composed here because `showSelectionPicker` has no row action, footer or
/// live options yet.
Future<void> showCustomChoicePicker(
  BuildContext context, {
  required String installId,
  required SelectField field,
  required String title,
  required GlobalKey anchor,
  required void Function(String value) onChoose,
  required Future<ConfigWrite> Function(String value) onRemove,
  required Future<ConfigWrite?> Function(BuildContext context) onAdd,
}) {
  Widget body(BuildContext context, {required bool compact}) => _PickerBody(
    installId: installId,
    field: field,
    title: title,
    compact: compact,
    onChoose: onChoose,
    onRemove: onRemove,
    onAdd: onAdd,
  );
  if (FormFactor.of(context) == FormFactor.mobile) {
    return showKSheet<void>(context, builder: (c) => body(c, compact: false));
  }
  final rect = kAnchorRectOf(anchor);
  if (rect == null) {
    return showKDialog<void>(
      context,
      builder: (c) => Dialog(
        shape: KShape.of(KRadius.xl, continuous: true),
        clipBehavior: Clip.antiAlias,
        child: body(c, compact: false),
      ),
    );
  }
  return showKAnchoredPanel<void>(
    context,
    anchor: rect,
    builder: (c) => SizedBox(
      width: KLayout.anchoredPickerMaxWidth,
      child: body(c, compact: true),
    ),
  );
}

class _PickerBody extends ConsumerStatefulWidget {
  const _PickerBody({
    required this.installId,
    required this.field,
    required this.title,
    required this.compact,
    required this.onChoose,
    required this.onRemove,
    required this.onAdd,
  });

  final String installId;
  final SelectField field;
  final String title;
  final bool compact;
  final void Function(String value) onChoose;
  final Future<ConfigWrite> Function(String value) onRemove;
  final Future<ConfigWrite?> Function(BuildContext context) onAdd;

  @override
  ConsumerState<_PickerBody> createState() => _PickerBodyState();
}

class _PickerBodyState extends ConsumerState<_PickerBody> {
  bool _busy = false;
  String? _error;

  Future<void> _remove(String value) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.onRemove(value);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = result == ConfigWrite.written
          ? null
          : configRefusalText(l10n, result);
    });
  }

  Future<void> _add(SelectField field) async {
    final l10n = AppLocalizations.of(context);
    if (field.options.length >= configMaxItems) {
      setState(
        () => _error = configIssueText(
          l10n,
          const ConfigIssue(ConfigIssueKind.tooManyItems, configMaxItems),
        ),
      );
      return;
    }
    setState(() => _error = null);
    final result = await widget.onAdd(context);
    if (!mounted || result == null) return;
    if (result == ConfigWrite.written) {
      Navigator.of(context).pop();
    } else {
      setState(() => _error = configRefusalText(l10n, result));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final data = ref.watch(configFormProvider(widget.installId)).value;
    final live = data?.field(widget.field.key);
    final field = live is SelectField ? live : widget.field;
    final selected = data?.valueOf(field);
    final caption = field.subtitle;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KSpace.x6,
            KSpace.x4,
            KSpace.x6,
            KSpace.x2,
          ),
          child: Text(
            widget.title,
            style:
                (widget.compact
                        ? theme.textTheme.titleSmall
                        : theme.textTheme.titleMedium)
                    ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (caption != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KSpace.x6,
              0,
              KSpace.x6,
              KSpace.x2,
            ),
            child: Text(
              caption,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: KSpace.x2),
            children: [
              for (final o in field.options)
                _row(
                  context,
                  l10n,
                  o,
                  data?.isOwn(field.key, o.value) ?? false,
                  selected == o.value,
                ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KSpace.x6,
              KSpace.x1,
              KSpace.x6,
              KSpace.x2,
            ),
            child: Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        PickerFooter(
          buttons: [
            TextButton.icon(
              onPressed: _busy ? null : () => _add(field),
              icon: const Icon(KIcons.add),
              label: Text(l10n.pluginsCfgAddModel),
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    AppLocalizations l10n,
    ConfigOption option,
    bool own,
    bool selected,
  ) {
    return Row(
      children: [
        Expanded(
          child: SelectionRow(
            dense: widget.compact,
            selected: selected,
            enabled: !_busy,
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    option.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (own) ...[
                  const KGap(KSpace.x2),
                  KChip.tag(label: Text(l10n.pluginsCfgOwnTag)),
                ],
              ],
            ),
            subtitle: option.subtitle == null ? null : Text(option.subtitle!),
            hint: option.subtitle,
            onTap: () {
              widget.onChoose(option.value);
              Navigator.of(context).pop();
            },
          ),
        ),
        if (own)
          KIconButton(
            icon: KIcons.close,
            tooltip: l10n.pluginsCfgRemoveModel,
            onPressed: _busy ? null : () => _remove(option.value),
          ),
      ],
    );
  }
}
