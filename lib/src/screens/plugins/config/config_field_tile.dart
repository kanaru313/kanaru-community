import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../plugins/domain/config/config_field.dart';
import '../../../plugins/state/config_form_provider.dart';
import 'config_env.dart';
import 'list_field_editor.dart';
import 'map_field_editor.dart';
import 'multi_select_editor.dart';
import 'select_field_editor.dart';
import 'text_field_editor.dart';
import 'toggle_field_editor.dart';

/// The editor of one field of the form, by the field's kind, with the
/// spacing of the card. A locked form dims what is not a text box (those dim
/// themselves) and takes it out of reach.
class ConfigFieldTile extends StatelessWidget {
  const ConfigFieldTile({
    super.key,
    required this.field,
    required this.data,
    required this.env,
  });

  final ConfigField field;
  final ConfigFormData data;
  final ConfigEnv env;

  static const _padding = EdgeInsets.symmetric(
    horizontal: KSpace.x4,
    vertical: KSpace.x2,
  );

  @override
  Widget build(BuildContext context) {
    final stored = data.values[field.key];
    final value = data.valueOf(field);
    final editor = switch (field) {
      InputField f => Padding(
        padding: _padding,
        child: TextFieldEditor(field: f, stored: stored, env: env),
      ),
      ToggleField f => ToggleFieldEditor(
        field: f,
        value: value is bool && value,
        env: env,
      ),
      SelectField f when f.format == SelectFormat.single => SelectFieldEditor(
        field: f,
        stored: stored,
        env: env,
        ownValues: data.ownChoices[f.key] ?? const {},
      ),
      SelectField f => Padding(
        padding: _padding,
        child: MultiSelectEditor(
          field: f,
          chosen: [
            if (value is List)
              for (final v in value)
                if (v is String) v,
          ],
          env: env,
        ),
      ),
      ListField f => Padding(
        padding: _padding,
        child: ListFieldEditor(
          field: f,
          items: [
            if (value is List)
              for (final v in value) ?v,
          ],
          env: env,
        ),
      ),
      MapField f => Padding(
        padding: _padding,
        child: MapFieldEditor(
          field: f,
          entries: [
            if (value is Map)
              for (final e in value.entries) ('${e.key}', '${e.value}'),
          ],
          env: env,
        ),
      ),
    };
    final dims = env.locked && field is! InputField;
    if (!dims) return editor;
    return Opacity(
      opacity: 0.5,
      child: IgnorePointer(child: ExcludeFocus(child: editor)),
    );
  }
}
