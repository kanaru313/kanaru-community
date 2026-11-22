import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/domain/config/config_field.dart';
import '../../../plugins/state/config_form_provider.dart';
import 'config_env.dart';
import 'config_texts.dart';
import 'custom_choice_dialog.dart';
import 'custom_choice_picker.dart';

/// A single `select` field: a row (title, the chosen option under it, ›)
/// that opens a picker; choosing closes it and saves. With `custom` the
/// picker also lists the user's own choices, lets the user remove them and
/// add one more.
class SelectFieldEditor extends StatefulWidget {
  const SelectFieldEditor({
    super.key,
    required this.field,
    required this.stored,
    required this.env,
    this.ownValues = const {},
  });

  /// The field as the user sees it (a `custom` select already holds the
  /// user's choices).
  final SelectField field;

  /// What the user saved, or null (the default applies).
  final Object? stored;
  final Set<String> ownValues;
  final ConfigEnv env;

  @override
  State<SelectFieldEditor> createState() => _SelectFieldEditorState();
}

class _SelectFieldEditorState extends State<SelectFieldEditor>
    with ConfigCommitHost<SelectFieldEditor> {
  final _anchor = GlobalKey();

  /// The user removed every model: the row says so in red. A plugin that was
  /// just installed with no model only shows "not chosen" (and the page's
  /// "needs setup" band).
  bool _noneLeft = false;

  @override
  ConfigEnv get env => widget.env;

  @override
  String get fieldKey => widget.field.key;

  @override
  void dispose() {
    detachCommit();
    super.dispose();
  }

  String? get _selected {
    final v = widget.stored ?? widget.field.defaultValue;
    return v is String && widget.field.options.any((o) => o.value == v)
        ? v
        : null;
  }

  Future<void> _open() async {
    final field = widget.field;
    final title = field.title.isEmpty ? field.key : field.title;
    if (field.custom) {
      await showCustomChoicePicker(
        context,
        installId: widget.env.installId,
        field: field,
        title: title,
        anchor: _anchor,
        onChoose: _choose,
        onRemove: _remove,
        onAdd: _add,
      );
      return;
    }
    final chosen = await showSelectionPicker<String>(
      context,
      anchor: _anchor,
      title: Text(title),
      header: field.subtitle == null ? null : pickerCaption(context, field),
      selected: _selected,
      options: [
        for (final o in field.options)
          SelectionOption(
            value: o.value,
            title: Text(o.title),
            subtitle: o.subtitle == null ? null : Text(o.subtitle!),
            hint: o.subtitle,
          ),
      ],
    );
    if (chosen != null && mounted) _choose(chosen);
  }

  void _choose(String value) {
    commit.dismiss();
    if (value != _selected) commit.submit(value);
  }

  /// Removes one of the user's choices. Returns the refusal, if any.
  Future<ConfigWrite> _remove(String value) async {
    final last = widget.field.options.length == 1;
    final result = await widget.env.ops.removeChoice(
      widget.env.installId,
      widget.field.key,
      value,
    );
    if (mounted && result == ConfigWrite.written && last) {
      setState(() => _noneLeft = true);
    }
    return result;
  }

  /// Opens the "add model" box and adds the choice. Returns true when it was
  /// added (and selected), false when the user gave up, the refusal else.
  Future<ConfigWrite?> _add(BuildContext pickerContext) async {
    final entry = await showAddChoiceDialog(pickerContext);
    if (entry == null || !mounted) return null;
    final result = await widget.env.ops.addChoice(
      widget.env.installId,
      widget.field.key,
      entry.name,
      note: entry.note,
    );
    if (mounted && result == ConfigWrite.written) {
      setState(() => _noneLeft = false);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final field = widget.field;
    final selected = field.options
        .where((o) => o.value == _selected)
        .firstOrNull;
    final refusal = commit.refusal;
    final error = refusal != null
        ? configRefusalText(l10n, refusal)
        : _noneLeft && field.options.isEmpty
        ? l10n.pluginsCfgNoModel
        : null;
    final title = field.title.isEmpty ? field.key : field.title;
    return KeyedSubtree(
      key: _anchor,
      child: SetupValueRow(
        title: Text.rich(
          TextSpan(
            text: title,
            children: [
              if (field.required)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: scheme.error),
                ),
            ],
          ),
        ),
        enabled: !widget.env.locked,
        onTap: _open,
        value: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    selected?.title ?? l10n.pluginsCfgNotChosen,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (selected != null &&
                    widget.ownValues.contains(selected.value)) ...[
                  const KGap(KSpace.x2),
                  KChip.tag(label: Text(l10n.pluginsCfgOwnTag)),
                ],
              ],
            ),
            if (error != null)
              Text(error, style: text.bodySmall?.copyWith(color: scheme.error)),
          ],
        ),
      ),
    );
  }
}
