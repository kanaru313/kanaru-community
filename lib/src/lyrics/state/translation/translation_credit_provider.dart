import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../media/domain/track_id.dart';
import '../../../plugins/domain/config/config_field.dart';
import '../../../plugins/state/plugin_store_providers.dart';
import '../../domain/translation/translation_status.dart';
import 'translation_providers.dart';

/// Who made the translation on screen, for the line after the lyrics.
class TranslationCredit {
  const TranslationCredit({
    required this.plugin,
    required this.target,
    this.model,
    this.style,
    this.other = false,
    this.linesDone = 0,
    this.linesTotal = 0,
  });

  /// Name of the plugin that made it.
  final String plugin;

  /// The language it was made for (a code of `translationLanguageCodes`).
  final String target;

  /// Model and style titles of an AI plugin's run; null for any other.
  final String? model;
  final String? style;

  /// A saved translation of a plugin other than the chosen one.
  final bool other;

  /// A run that stopped half way: [linesDone] of [linesTotal] lines are
  /// translated (both 0 when the run completed).
  final int linesDone;
  final int linesTotal;

  bool get partial => linesTotal > 0 && linesDone < linesTotal;

  @override
  bool operator ==(Object other) =>
      other is TranslationCredit &&
      other.plugin == plugin &&
      other.target == target &&
      other.model == model &&
      other.style == style &&
      other.other == this.other &&
      other.linesDone == linesDone &&
      other.linesTotal == linesTotal;

  @override
  int get hashCode =>
      Object.hash(plugin, target, model, style, other, linesDone, linesTotal);
}

/// The credit of the translation shown for [id]; null when the lyrics show
/// none (nothing translated, "same language", the plugin is gone). It reads
/// the track's translation, so it asks for one like any lyrics view.
final translationCreditProvider = Provider.autoDispose
    .family<TranslationCredit?, TrackId>((ref, id) {
      final view = ref.watch(trackTranslationProvider(id));
      final installId = view.installId;
      if (installId == null || view.map.isEmpty) return null;
      final other = view.status is StatusOther;
      final partial = view.status is StatusFailed;
      final status = view.status;
      final shown =
          other ||
          partial ||
          status is StatusReady ||
          (status is StatusLoading && status.background);
      if (!shown) return null;
      final row = ref.watch(installedPluginProvider(installId)).value;
      if (row == null) return null;
      final fields = ref.watch(pluginRowsProvider).manifestOf(row)?.config;
      final settings = _settingsOf(view.settingsJson);
      return TranslationCredit(
        plugin: row.name,
        target: ref.watch(effectiveTranslationTargetProvider(id)),
        model: other ? null : _titleOf(fields, 'model', settings['model']),
        style: other ? null : _titleOf(fields, 'style', settings['style']),
        other: other,
        linesDone: partial ? view.linesDone : 0,
        linesTotal: partial ? view.linesTotal : 0,
      );
    });

Map<String, Object?> _settingsOf(String? json) {
  if (json == null) return const {};
  try {
    final value = jsonDecode(json);
    return value is Map<String, Object?> ? value : const {};
  } on FormatException {
    return const {};
  }
}

/// The title of the option [value] of the select field [key], else [value]
/// itself (a choice the user added); null for a plugin without that field or
/// a run without a value.
String? _titleOf(List<ConfigField>? fields, String key, Object? value) {
  if (value is! String || value.isEmpty) return null;
  final field = fields?.whereType<SelectField>().where((f) => f.key == key);
  if (field == null || field.isEmpty) return null;
  for (final option in field.first.options) {
    if (option.value == value) return option.title;
  }
  return value;
}
