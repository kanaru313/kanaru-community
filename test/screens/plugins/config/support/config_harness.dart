import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:kanaru/src/plugins/domain/config/config_field.dart';
import 'package:kanaru/src/plugins/state/config_form_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_store_providers.dart';

/// Writes that go nowhere and always succeed.
class NoopConfigOps implements ConfigOps {
  const NoopConfigOps();

  @override
  Future<ConfigWrite> setValue(
    String installId,
    String key,
    Object? value,
  ) async => ConfigWrite.written;
  @override
  Future<ConfigWrite> addChoice(
    String installId,
    String key,
    String value, {
    String? note,
  }) async => ConfigWrite.written;
  @override
  Future<ConfigWrite> removeChoice(
    String installId,
    String key,
    String value,
  ) async => ConfigWrite.written;
}

/// The stored config of one plugin held in memory: the form reads it, and the
/// writes of the form change it the way the store does (`null` / `''`
/// removes a value, a choice added is selected, removing the selected one
/// selects the first left), so the form follows its own saves.
class ConfigHarness extends ChangeNotifier implements ConfigOps {
  ConfigHarness(
    List<ConfigField> fields, {
    Map<String, Object?>? values,
    Map<String, Set<String>>? own,
  }) : fields = [...fields],
       values = {...?values},
       own = {...?own};

  final List<ConfigField> fields;
  final Map<String, Object?> values;
  final Map<String, Set<String>> own;

  /// What reached the store, in order: `set:key=json`, `add:key=name`,
  /// `remove:key=name`.
  final calls = <String>[];

  /// The answer for the next write of a key; used once.
  final refusals = <String, ConfigWrite>{};

  /// Holds every write until it completes.
  Future<void>? gate;

  /// What the form provider answers; null = the data below.
  AsyncValue<ConfigFormData?>? answer;

  /// Builds the form again whenever the stored config provider does, as the
  /// real one (a Retry invalidates it). The test overrides that provider.
  bool followsStore = false;

  /// Same for the installed plugins stream the real form also reads.
  bool followsRows = false;

  ConfigFormData get data =>
      ConfigFormData(fields: fields, values: values, ownChoices: own);

  List<Override> get overrides => [
    configFormProvider.overrideWith((ref, id) {
      if (followsStore) ref.watch(pluginConfigProvider(id));
      if (followsRows) ref.watch(installedPluginsProvider);
      void changed() => ref.invalidateSelf();
      addListener(changed);
      ref.onDispose(() => removeListener(changed));
      return answer ?? AsyncData(data);
    }),
    configOpsProvider.overrideWithValue(this),
  ];

  /// A change made outside the form.
  void setOutside(String key, Object? value) {
    value == null ? values.remove(key) : values[key] = value;
    notifyListeners();
  }

  void refresh() => notifyListeners();

  Future<ConfigWrite?> _enter(String key) async {
    await gate;
    return refusals.remove(key);
  }

  @override
  Future<ConfigWrite> setValue(
    String installId,
    String key,
    Object? value,
  ) async {
    calls.add('set:$key=${jsonEncode(value)}');
    final refused = await _enter(key);
    if (refused != null) return refused;
    value == null || value == '' ? values.remove(key) : values[key] = value;
    notifyListeners();
    return ConfigWrite.written;
  }

  int _indexOf(String key) => fields.indexWhere((f) => f.key == key);

  @override
  Future<ConfigWrite> addChoice(
    String installId,
    String key,
    String value, {
    String? note,
  }) async {
    calls.add('add:$key=$value');
    final refused = await _enter(key);
    if (refused != null) return refused;
    final i = _indexOf(key);
    final f = fields[i] as SelectField;
    if (!f.options.any((o) => o.value == value)) {
      fields[i] = _withOptions(f, [
        ...f.options,
        ConfigOption(value: value, title: value, subtitle: note),
      ]);
      (own[key] ??= {}).add(value);
    }
    values[key] = value;
    notifyListeners();
    return ConfigWrite.written;
  }

  @override
  Future<ConfigWrite> removeChoice(
    String installId,
    String key,
    String value,
  ) async {
    calls.add('remove:$key=$value');
    final refused = await _enter(key);
    if (refused != null) return refused;
    final i = _indexOf(key);
    final f = fields[i] as SelectField;
    final kept = [
      for (final o in f.options)
        if (o.value != value) o,
    ];
    fields[i] = _withOptions(f, kept);
    own[key]?.remove(value);
    if (values[key] == value) {
      kept.isEmpty ? values.remove(key) : values[key] = kept.first.value;
    }
    notifyListeners();
    return ConfigWrite.written;
  }

  SelectField _withOptions(SelectField f, List<ConfigOption> options) =>
      SelectField(
        key: f.key,
        title: f.title,
        subtitle: f.subtitle,
        required: f.required,
        format: f.format,
        options: options,
        custom: f.custom,
        minItems: f.minItems,
        maxItems: f.maxItems,
        defaultValue: f.defaultValue,
      );
}
