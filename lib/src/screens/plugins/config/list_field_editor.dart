import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/domain/config/config_field.dart';
import 'config_checks.dart';
import 'config_env.dart';
import 'config_texts.dart';
import 'field_heading.dart';

/// A `list` field: one box per item with ✕, and [+ Thêm]. Blank rows are not
/// items. A row saves when it loses focus, on Enter and when removed. An item
/// that does not fit the list's format gets a red outline and one line under
/// the list; nothing is saved until every item fits.
class ListFieldEditor extends StatefulWidget {
  const ListFieldEditor({
    super.key,
    required this.field,
    required this.items,
    required this.env,
  });

  final ListField field;

  /// The stored items, else the default, else none.
  final List<Object> items;
  final ConfigEnv env;

  @override
  State<ListFieldEditor> createState() => _ListFieldEditorState();
}

class _ListFieldEditorState extends State<ListFieldEditor>
    with ConfigCommitHost<ListFieldEditor> {
  ListCheck? _check;

  @override
  ConfigEnv get env => widget.env;

  @override
  String get fieldKey => widget.field.key;

  @override
  void dispose() {
    detachCommit();
    super.dispose();
  }

  void _onCommit(List<String> rows) {
    commit.dismiss();
    final check = checkList(widget.field, rows);
    setState(() => _check = check);
    if (check.canSend) commit.submit(configOverride(widget.field, check.value));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final field = widget.field;
    final check = _check;
    final refusal = commit.refusal;
    final error = check?.issue != null
        ? configIssueText(l10n, check!.issue!)
        : refusal == null
        ? null
        : configRefusalText(l10n, refusal);
    final max = field.maxItems == null || field.maxItems! > configMaxItems
        ? configMaxItems
        : field.maxItems!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldHeading(
          title: field.title.isEmpty ? field.key : field.title,
          required: field.required,
          subtitle: field.subtitle,
        ),
        KFieldRows.list(
          values: [for (final item in widget.items) _text(item)],
          onCommit: _onCommit,
          hint: field.placeholder ?? '',
          addLabel: l10n.pluginsCfgAddRow,
          removeTooltip: l10n.pluginsCfgRemoveRow,
          keyboard: field.format == ListFormat.url ? TextInputType.url : null,
          maxRows: max,
          enabled: !widget.env.locked,
          error: error,
          invalidRows: check?.bad ?? const {},
        ),
      ],
    );
  }

  String _text(Object item) => item is num ? configNumberText(item) : '$item';
}
