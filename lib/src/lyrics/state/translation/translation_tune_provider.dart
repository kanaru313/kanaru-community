import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../plugins/data/store/plugin_config_values.dart'
    show effectiveField, effectiveValue;
import '../../../plugins/domain/config/config_field.dart';
import '../../../plugins/state/plugin_store_providers.dart';

/// The settings of an AI translate plugin that "Tinh chỉnh AI" edits: the
/// `model` and `style` select fields with their stored values, and the
/// `customInstruction` note (all songs).
class TranslateTune {
  const TranslateTune({
    required this.installId,
    required this.pluginName,
    required this.pluginVersion,
    this.model,
    this.style,
    this.modelValue,
    this.styleValue,
    this.note = '',
    this.hasNote = false,
  });

  final String installId;
  final String pluginName;
  final int pluginVersion;

  /// The plugin's select fields (with the user's own choices); null when the
  /// plugin declares none.
  final SelectField? model;
  final SelectField? style;

  /// What the plugin reads now (stored value, else its default).
  final String? modelValue;
  final String? styleValue;

  /// The stored "Lời dặn thêm", empty when none.
  final String note;
  final bool hasNote;

  /// The title of [value] in [field]; the value itself for a choice the
  /// field does not list; null without a value.
  static String? titleOf(SelectField? field, String? value) {
    if (value == null || value.isEmpty) return null;
    for (final option in field?.options ?? const <ConfigOption>[]) {
      if (option.value == value) return option.title;
    }
    return value;
  }

  String? get modelTitle => titleOf(model, modelValue);
  String? get styleTitle => titleOf(style, styleValue);
}

/// The tune of the AI plugin [installId]; data null when it is not installed
/// or its manifest does not parse.
final translateTuneProvider = Provider.autoDispose
    .family<AsyncValue<TranslateTune?>, String>((ref, installId) {
      return ref.watch(pluginConfigStatusProvider(installId)).whenData((s) {
        final manifest = s?.manifest;
        if (s == null || manifest == null) return null;
        SelectField? selectOf(String key) {
          final field = manifest.config
              .whereType<SelectField>()
              .where((f) => f.key == key && f.format == SelectFormat.single)
              .firstOrNull;
          return field == null
              ? null
              : effectiveField(field, s.data.choices[key] ?? const [])
                    as SelectField;
        }

        final model = selectOf('model');
        final style = selectOf('style');
        final note = s.data.values['customInstruction'];
        final noteField = manifest.config
            .where((f) => f.key == 'customInstruction')
            .firstOrNull;
        String? valueOf(SelectField? f) {
          final v = f == null ? null : effectiveValue(f, s.data.values);
          return v is String ? v : null;
        }

        return TranslateTune(
          installId: installId,
          pluginName: s.row.name,
          pluginVersion: s.row.version,
          model: model,
          style: style,
          modelValue: valueOf(model),
          styleValue: valueOf(style),
          note: note is String ? note : '',
          hasNote: noteField != null,
        );
      });
    });

/// What differs between the translation on screen and the plugin's settings
/// now, for "Lựa chọn khác bản đang hiện".
class TranslateSettingsDiff {
  const TranslateSettingsDiff({
    this.model,
    this.style,
    this.note = false,
    this.version = false,
  });

  /// Before and after titles ("A → B"); null when that setting did not change.
  final (String, String)? model;
  final (String, String)? style;

  /// The "Lời dặn thêm" changed.
  final bool note;

  /// The plugin itself was updated.
  final bool version;

  bool get isEmpty => model == null && style == null && !note && !version;
}

/// Compares [madeWith] (`settingsJson` of the shown translation) with [now].
TranslateSettingsDiff translateSettingsDiff(
  String? madeWith,
  TranslateTune now,
) {
  Map<String, Object?> made = const {};
  try {
    final decoded = madeWith == null ? null : jsonDecode(madeWith);
    if (decoded is Map<String, Object?>) made = decoded;
  } on FormatException {
    // Unreadable: nothing can be compared, every part reads as changed.
  }
  (String, String)? change(SelectField? field, Object? before, String? after) {
    final b = before is String ? before : null;
    if (b == after) return null;
    return (
      TranslateTune.titleOf(field, b) ?? '–',
      TranslateTune.titleOf(field, after) ?? '–',
    );
  }

  final instruction = now.note.trim();
  final hash = instruction.isEmpty
      ? null
      : sha256.convert(utf8.encode(instruction)).toString();
  return TranslateSettingsDiff(
    model: change(now.model, made['model'], now.modelValue),
    style: change(now.style, made['style'], now.styleValue),
    note: made['instructionHash'] != hash,
    version: made['pluginVersion'] != now.pluginVersion,
  );
}
