import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/domain/config/config_field.dart';
import 'config_checks.dart';
import 'config_env.dart';
import 'config_texts.dart';
import 'field_heading.dart';

/// A `map` field: rows of Tên and Giá trị with ✕, and [+ Thêm]. Blank rows
/// are ignored. A bad or repeated name is told under that row's name box and
/// the whole table is not saved until none is left.
class MapFieldEditor extends StatefulWidget {
  const MapFieldEditor({
    super.key,
    required this.field,
    required this.entries,
    required this.env,
  });

  final MapField field;

  /// The stored table, else the default, else none (order kept).
  final List<(String, String)> entries;
  final ConfigEnv env;

  @override
  State<MapFieldEditor> createState() => _MapFieldEditorState();
}

class _MapFieldEditorState extends State<MapFieldEditor>
    with ConfigCommitHost<MapFieldEditor> {
  MapCheck? _check;

  @override
  ConfigEnv get env => widget.env;

  @override
  String get fieldKey => widget.field.key;

  @override
  void dispose() {
    detachCommit();
    super.dispose();
  }

  void _onCommit(List<(String, String)> rows) {
    commit.dismiss();
    final check = checkMap(widget.field, rows);
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
        KFieldRows.map(
          values: widget.entries,
          onCommit: _onCommit,
          nameLabel: l10n.pluginsCfgNameLabel,
          valueLabel: l10n.pluginsCfgValueLabel,
          addLabel: l10n.pluginsCfgAddRow,
          removeTooltip: l10n.pluginsCfgRemoveRow,
          maxRows: max,
          enabled: !widget.env.locked,
          error: error,
          rowErrors: {
            for (final e
                in (check?.rowIssues ?? const <int, ConfigIssue>{}).entries)
              e.key: configIssueText(l10n, e.value),
          },
        ),
      ],
    );
  }
}
