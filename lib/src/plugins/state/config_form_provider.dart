import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/install/config_writes.dart';
import '../data/store/plugin_config_store.dart' show ConfigWrite;
import '../data/store/plugin_config_values.dart';
import '../domain/config/config_field.dart';
import 'plugin_actions_provider.dart';
import 'plugin_store_providers.dart';

// The form reads the write result through this file, never from
// `plugins/data`.
export '../data/store/plugin_config_store.dart' show ConfigWrite;

/// The values a plugin's settings form shows: the manifest's fields as the
/// user sees them (a `custom` select already holds the choices the user
/// added), the stored values and which choices are the user's own.
class ConfigFormData {
  const ConfigFormData({
    required this.fields,
    required this.values,
    this.ownChoices = const {},
  });

  /// Fields in manifest order, selects with the user's choices merged in.
  final List<ConfigField> fields;

  /// Field key to the value the user stored; a field without one is absent.
  final Map<String, Object?> values;

  /// Field key to the values of the choices the user added there.
  final Map<String, Set<String>> ownChoices;

  /// What the form shows for [field]: the stored value, else the default.
  Object? valueOf(ConfigField field) => values[field.key] ?? field.defaultValue;

  /// Whether [value] of the select [key] is a choice the user added.
  bool isOwn(String key, String value) =>
      ownChoices[key]?.contains(value) ?? false;

  ConfigField? field(String key) {
    for (final f in fields) {
      if (f.key == key) return f;
    }
    return null;
  }
}

/// The settings form of the live plugin [installId], from the same stored
/// config the page's "needs setup" band reads, so both change together. Data
/// null when the plugin is gone or its manifest does not parse. A database
/// error is the error state.
final configFormProvider = Provider.autoDispose
    .family<AsyncValue<ConfigFormData?>, String>(
      (ref, installId) =>
          ref.watch(pluginConfigStatusProvider(installId)).whenData((status) {
            final manifest = status?.manifest;
            if (status == null || manifest == null) return null;
            final choices = status.data.choices;
            return ConfigFormData(
              fields: [
                for (final f in manifest.config)
                  effectiveField(f, choices[f.key] ?? const []),
              ],
              values: status.data.values,
              ownChoices: {
                for (final e in choices.entries)
                  e.key: {for (final c in e.value) c.value},
              },
            );
          }),
    );

/// What the form does to the stored config. Every call goes through the
/// store's write queue, so none interleaves with an update or a remove. No
/// method throws: a failure is a [ConfigWrite] value. Tests replace it.
abstract interface class ConfigOps {
  /// Sets [key] (null or `''` removes it, so the default applies again).
  Future<ConfigWrite> setValue(String installId, String key, Object? value);

  /// Adds a choice to the `custom` select [key] and selects it.
  Future<ConfigWrite> addChoice(
    String installId,
    String key,
    String value, {
    String? note,
  });

  /// Removes one of the user's own choices of the select [key].
  Future<ConfigWrite> removeChoice(String installId, String key, String value);
}

class _QueuedConfigOps implements ConfigOps {
  _QueuedConfigOps(this._writes);

  final PluginConfigWrites _writes;

  @override
  Future<ConfigWrite> setValue(String installId, String key, Object? value) =>
      _writes.setValue(installId, key, value);

  @override
  Future<ConfigWrite> addChoice(
    String installId,
    String key,
    String value, {
    String? note,
  }) => _writes.addCustomChoice(installId, key, value, subtitle: note);

  @override
  Future<ConfigWrite> removeChoice(
    String installId,
    String key,
    String value,
  ) => _writes.removeCustomChoice(installId, key, value);
}

final configOpsProvider = Provider<ConfigOps>(
  (ref) => _QueuedConfigOps(ref.watch(pluginActionsProvider).configWrites),
);
