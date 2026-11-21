import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../../domain/config/config_field.dart';
import '../../domain/config/config_value_rules.dart';
import 'plugin_config_values.dart';
import 'plugin_rows.dart';
import 'plugin_store_rules.dart';

export 'plugin_config_values.dart'
    show CustomChoice, CustomChoices, PluginConfigData;

/// How a config write ended.
enum ConfigWrite {
  written,

  /// No live plugin, or its form has no such field (or the field is not a
  /// `custom` select, for the choice writes).
  unknownKey,

  /// The value does not fit the field.
  invalidValue,

  /// The values (or the choices) would pass the 64 KiB cap.
  tooLarge,

  /// The database failed; nothing was written.
  failed,
}

/// The config the user set for each plugin, plain text in `plugin_data`:
/// `config_json` holds the values, `custom_choices_json` the choices the user
/// added to `custom` selects (those never reach a script).
///
/// The form is always the live row's current manifest, so a value left
/// behind by a form change is never read. Writes read, change and save in
/// one transaction, and are meant to run on the store's serial write queue.
class PluginConfigStore {
  PluginConfigStore(this._db, this._rows);

  final AppDatabase _db;
  final PluginRows _rows;

  /// Sets [key] to [value] (a string, number, bool, list or map, as the
  /// field asks). Null or an empty string removes the value, so the default
  /// applies again; an empty list or map is a value. A `custom` select also
  /// accepts the choices the user added.
  Future<ConfigWrite> setValue(String installId, String key, Object? value) =>
      _edit(installId, key, (field, values, choices) {
        final effective = effectiveField(field, choices[key] ?? const []);
        final cleared = value == null || value == '';
        if (!cleared && !valueFits(effective, value)) {
          return ConfigWrite.invalidValue;
        }
        cleared ? values.remove(key) : values[key] = value;
        return null;
      });

  /// Adds [value] to the choices of the `custom` select [key] and selects it,
  /// in one write. A name that is already a choice (the plugin's or an
  /// earlier one) is only selected. The name and the note are stripped of
  /// control characters and trimmed; an empty name, a name over
  /// [customChoiceMaxValue] code points, a note over [customChoiceMaxSubtitle],
  /// or a list that would pass [configMaxItems] (the plugin's options and the
  /// user's together) is `invalidValue`.
  Future<ConfigWrite> addCustomChoice(
    String installId,
    String key,
    String value, {
    String? subtitle,
  }) => _edit(installId, key, (field, values, choices) {
    if (!isCustomSelect(field)) return ConfigWrite.unknownKey;
    final name = cleanChoiceText(value);
    final note = subtitle == null ? '' : cleanChoiceText(subtitle);
    if (name.isEmpty ||
        name.runes.length > customChoiceMaxValue ||
        note.runes.length > customChoiceMaxSubtitle) {
      return ConfigWrite.invalidValue;
    }
    final known = (effectiveField(
      field,
      choices[key] ?? const [],
    ) as SelectField).options;
    if (!known.any((o) => o.value == name)) {
      if (known.length >= configMaxItems) return ConfigWrite.invalidValue;
      choices[key] = [
        ...?choices[key],
        CustomChoice(name, note.isEmpty ? null : note),
      ];
    }
    values[key] = name;
    return null;
  });

  /// Removes [value] from the user's own choices of the `custom` select
  /// [key]. If it was the selected value the first remaining option is
  /// selected, or the selection is cleared when none is left. A value that is
  /// not one of the user's choices is `invalidValue`.
  Future<ConfigWrite> removeCustomChoice(
    String installId,
    String key,
    String value,
  ) => _edit(installId, key, (field, values, choices) {
    if (!isCustomSelect(field)) return ConfigWrite.unknownKey;
    final own = choices[key] ?? const <CustomChoice>[];
    if (!own.any((c) => c.value == value)) return ConfigWrite.invalidValue;
    final kept = [
      for (final c in own)
        if (c.value != value) c,
    ];
    kept.isEmpty ? choices.remove(key) : choices[key] = kept;
    if (values[key] == value) {
      final first =
          (effectiveField(field, kept) as SelectField).options.firstOrNull;
      first == null ? values.remove(key) : values[key] = first.value;
    }
    return null;
  });

  /// What is stored for [installId] (empty for a removed or unknown plugin).
  Future<PluginConfigData> read(String installId) async {
    final row = await (_db.select(
      _db.pluginData,
    )..where((t) => t.installId.equals(installId))).getSingleOrNull();
    return row == null
        ? const PluginConfigData()
        : PluginConfigData(
            values: decodeValues(row.configJson),
            choices: decodeChoices(row.customChoicesJson),
          );
  }

  /// [read] again after every change of the plugin's config, but only when
  /// the stored text really changed.
  Stream<PluginConfigData> watch(String installId) =>
      (_db.select(_db.pluginData)..where((t) => t.installId.equals(installId)))
          .watchSingleOrNull()
          .map(
            (row) => (row?.configJson ?? '{}', row?.customChoicesJson ?? '{}'),
          )
          .distinct()
          .map(
            (texts) => PluginConfigData(
              values: decodeValues(texts.$1),
              choices: decodeChoices(texts.$2),
            ),
          );

  /// Everything a script may read, typed: the stored values, then the form's
  /// defaults for the rest. A value that does not fit its field is left out
  /// (it does not fall back to the default). Empty for a plugin that is not
  /// live or whose manifest does not parse.
  Future<Map<String, Object>> configForRun(String installId) async {
    final row = await _rows.liveById(installId);
    final manifest = row == null ? null : _rows.manifestOf(row);
    if (manifest == null) return const {};
    return resolveRunConfig(manifest.config, await read(installId));
  }

  /// Moves the stored config to follow a form change from [before] to
  /// [after] (an update): a value is kept only if its field still exists with
  /// the same mode and format and the value still fits; choices stay only on
  /// a field that is still a `custom` select. [ConfigWrite.unknownKey] means
  /// the plugin is no longer live. Call it in the transaction of
  /// the package switch (`PluginRows.transaction`).
  Future<ConfigWrite> adaptToForm(
    String installId,
    List<ConfigField> before,
    List<ConfigField> after,
  ) => _db.transaction(() async {
    if (await _rows.liveById(installId) == null) return ConfigWrite.unknownKey;
    final data = await read(installId);
    final kept = adaptConfig(before, after, data.values, data.choices);
    if (jsonEncode(kept.values) != jsonEncode(data.values) ||
        encodeChoices(kept.choices) != encodeChoices(data.choices)) {
      return _save(installId, kept.values, kept.choices);
    }
    return ConfigWrite.written;
  });

  /// The shared read, change, save of one field. [change] returns a failure,
  /// or null to save what it did to [values] and [choices].
  Future<ConfigWrite> _edit(
    String installId,
    String key,
    ConfigWrite? Function(
      ConfigField field,
      Map<String, Object?> values,
      Map<String, List<CustomChoice>> choices,
    )
    change,
  ) => _db.transaction(() async {
    final row = await _rows.liveById(installId);
    final manifest = row == null ? null : _rows.manifestOf(row);
    final field = manifest?.config.where((f) => f.key == key).firstOrNull;
    if (field == null) return ConfigWrite.unknownKey;
    final data = await read(installId);
    final values = {...data.values};
    final choices = {
      for (final e in data.choices.entries) e.key: [...e.value],
    };
    final failure = change(field, values, choices);
    return failure ?? await _save(installId, values, choices);
  });

  /// Writes both columns while the plugin is live: an insert that selects
  /// nothing for a missing or removed plugin, so a write that lost a race with
  /// a remove changes nothing.
  Future<ConfigWrite> _save(
    String installId,
    Map<String, Object?> values,
    CustomChoices choices,
  ) async {
    final valuesText = jsonEncode(values);
    final choicesText = encodeChoices(choices);
    if (utf8Length(valuesText) > maxConfigJsonBytes ||
        utf8Length(choicesText) > maxConfigJsonBytes) {
      return ConfigWrite.tooLarge;
    }
    final changed = await _db.customUpdate(
      'INSERT INTO plugin_data (install_id, config_json, custom_choices_json) '
      'SELECT install_id, ?1, ?2 FROM plugins '
      'WHERE install_id = ?3 AND removed_at IS NULL '
      'ON CONFLICT(install_id) DO UPDATE SET '
      'config_json = excluded.config_json, '
      'custom_choices_json = excluded.custom_choices_json',
      variables: [
        Variable<String>(valuesText),
        Variable<String>(choicesText),
        Variable<String>(installId),
      ],
      updates: {_db.pluginData},
      updateKind: UpdateKind.update,
    );
    return changed == 0 ? ConfigWrite.unknownKey : ConfigWrite.written;
  }
}
