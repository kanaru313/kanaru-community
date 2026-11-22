import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/domain/config/config_field.dart';
import 'config_checks.dart';
import 'config_env.dart';
import 'config_texts.dart';
import 'field_heading.dart';

/// A multiple `select`: the title, its note and one chip per option (its note
/// is the tooltip). A tap saves at once, in manifest order. At `maxItems` the
/// chips not chosen are dimmed and "Tối đa n" says why. Fewer than `minItems`
/// is not saved: the chips keep what was picked and the line says so.
class MultiSelectEditor extends StatefulWidget {
  const MultiSelectEditor({
    super.key,
    required this.field,
    required this.chosen,
    required this.env,
  });

  final SelectField field;

  /// The stored values, else the default, else none.
  final List<String> chosen;
  final ConfigEnv env;

  @override
  State<MultiSelectEditor> createState() => _MultiSelectEditorState();
}

class _MultiSelectEditorState extends State<MultiSelectEditor>
    with ConfigCommitHost<MultiSelectEditor> {
  late Set<String> _chosen = {...widget.chosen};
  bool _touched = false;

  @override
  ConfigEnv get env => widget.env;

  @override
  String get fieldKey => widget.field.key;

  @override
  void didUpdateWidget(MultiSelectEditor old) {
    super.didUpdateWidget(old);
    if (!_sameList(old.chosen, widget.chosen) && !commit.busy) {
      _chosen = {...widget.chosen};
    }
  }

  bool _sameList(List<String> a, List<String> b) =>
      a.length == b.length && a.toSet().containsAll(b);

  @override
  void dispose() {
    detachCommit();
    super.dispose();
  }

  int? get _max {
    final max = widget.field.maxItems;
    return max;
  }

  void _toggle(String value) {
    commit.dismiss();
    final next = {..._chosen};
    next.contains(value) ? next.remove(value) : next.add(value);
    final ordered = [
      for (final o in widget.field.options)
        if (next.contains(o.value)) o.value,
    ];
    setState(() {
      _chosen = next;
      _touched = true;
    });
    final field = widget.field;
    final issue = checkChoices(field, ordered.length);
    if (issue == null || !issue.blocks) {
      commit.submit(configOverride(field, ordered, anyOrder: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final field = widget.field;
    final max = _max;
    final full = max != null && _chosen.length >= max;
    final refusal = commit.refusal;
    // A refused pick goes back to what is stored.
    if (refusal != null && !commit.busy) _chosen = {...widget.chosen};
    final issue = _touched ? checkChoices(field, _chosen.length) : null;
    final error = issue != null
        ? configIssueText(l10n, issue)
        : refusal == null
        ? null
        : configRefusalText(l10n, refusal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldHeading(
          title: field.title.isEmpty ? field.key : field.title,
          required: field.required,
          subtitle: field.subtitle,
          gap: KSpace.x2,
        ),
        Semantics(
          container: true,
          label: field.title,
          child: Wrap(
            spacing: KSpace.x2,
            runSpacing: KSpace.x2,
            children: [for (final o in field.options) _chip(o, full)],
          ),
        ),
        if (error != null)
          FieldErrorLine(error)
        else if (full)
          Padding(
            padding: const EdgeInsets.only(top: KSpace.x1),
            child: Text(
              l10n.pluginsCfgMaxChosen('$max'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  Widget _chip(ConfigOption option, bool full) {
    final on = _chosen.contains(option.value);
    final chip = KChip(
      dense: true,
      label: Text(option.title),
      selected: on,
      enabled: on || !full,
      onTap: () => _toggle(option.value),
    );
    final note = option.subtitle;
    return note == null ? chip : Tooltip(message: note, child: chip);
  }
}
