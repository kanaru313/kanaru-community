import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/domain/config/config_field.dart';
import 'config_checks.dart';
import 'config_env.dart';
import 'config_texts.dart';

/// A `toggle` field: a switch row that saves at once. A refused write puts
/// the switch back to the stored value and says why under the row.
class ToggleFieldEditor extends StatefulWidget {
  const ToggleFieldEditor({
    super.key,
    required this.field,
    required this.value,
    required this.env,
  });

  final ToggleField field;

  /// The stored value, else the default, else off.
  final bool value;
  final ConfigEnv env;

  @override
  State<ToggleFieldEditor> createState() => _ToggleFieldEditorState();
}

class _ToggleFieldEditorState extends State<ToggleFieldEditor>
    with ConfigCommitHost<ToggleFieldEditor> {
  late bool _on = widget.value;

  @override
  ConfigEnv get env => widget.env;

  @override
  String get fieldKey => widget.field.key;

  @override
  void didUpdateWidget(ToggleFieldEditor old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && !commit.busy) _on = widget.value;
  }

  @override
  void dispose() {
    detachCommit();
    super.dispose();
  }

  void _toggle(bool value) {
    commit.dismiss();
    setState(() => _on = value);
    // On the default there is no override to keep.
    commit.submit(configOverride(widget.field, value));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final refusal = commit.refusal;
    // A refused pick goes back to what is stored.
    if (refusal != null && !commit.busy) _on = widget.value;
    final field = widget.field;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KSwitchRow(
          title: Text(field.title.isEmpty ? field.key : field.title),
          subtitle: field.subtitle == null ? null : Text(field.subtitle!),
          value: _on,
          switchLabel: field.title,
          onChanged: widget.env.locked ? null : _toggle,
        ),
        if (refusal != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KSpace.x4,
              0,
              KSpace.x4,
              KSpace.x2,
            ),
            child: Text(
              configRefusalText(l10n, refusal),
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.error),
            ),
          ),
      ],
    );
  }
}
