import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/state/database_providers.dart';
import '../../../platform/domain/setting.dart';
import '../../../platform/state/settings_providers.dart';
import '../../../plugins/domain/package/plugin_kind.dart';
import '../../../plugins/domain/package/translate_spec.dart'
    show translationLanguageCodes;
import '../../../plugins/state/plugin_page_provider.dart';
import '../../data/translation/translation_cache_store.dart';
import '../../data/translation/translation_prefs_store.dart';

/// How a translated line is shown.
enum TranslationDisplay {
  /// Under the original line.
  under,

  /// Instead of the original line.
  replace,
}

/// Show translations while lyrics play.
final Setting<bool> translationOnSetting = Setting<bool>(
  'lyrics.translation.on',
  false,
  decode: (json) {
    if (json is bool) return json;
    throw FormatException('not a bool: $json');
  },
  encode: (v) => v,
);

/// Install id of the chosen translate plugin; null = none chosen. Whether it
/// is usable is [effectiveTranslationServiceProvider]'s job.
final Setting<String?> translationServiceSetting = Setting<String?>(
  'lyrics.translation.service',
  null,
  decode: (json) {
    if (json == null || json is String) return json as String?;
    throw FormatException('not a string: $json');
  },
  encode: (v) => v,
);

/// Target language code; null = follow the app language. A stored code the
/// app does not know reads as null.
final Setting<String?> translationTargetSetting = Setting<String?>(
  'lyrics.translation.target',
  null,
  decode: (json) =>
      json is String && translationLanguageCodes.contains(json) ? json : null,
  encode: (v) => v,
);

final Setting<TranslationDisplay> translationDisplaySetting =
    Setting<TranslationDisplay>(
      'lyrics.translation.display',
      TranslationDisplay.under,
      decode: (json) => enumByName(TranslationDisplay.values, json),
      encode: (v) => v.name,
    );

final translationOnProvider = settingNotifierProvider(translationOnSetting);
final translationServiceProvider = settingNotifierProvider(
  translationServiceSetting,
);
final translationTargetProvider = settingNotifierProvider(
  translationTargetSetting,
);
final translationDisplayProvider = settingNotifierProvider(
  translationDisplaySetting,
);

/// The chosen service when it is an installed `translate` or `ai-translate`
/// plugin, else null (nothing chosen, removed, or another kind). Switching a
/// plugin between the two translate kinds keeps it. While the installed list
/// loads or fails this is loading / error, never data(null): "unknown" must
/// not read as "no service".
final effectiveTranslationServiceProvider = Provider<AsyncValue<String?>>((
  ref,
) {
  final id = ref.watch(translationServiceProvider);
  if (id == null) return const AsyncData(null);
  return ref.watch(installedByKindProvider).whenData((installed) {
    for (final kind in PluginKind.values.where((k) => k.isTranslation)) {
      for (final entry in installed.of(kind)) {
        if (entry.row.installId == id && entry.row.removedAt == null) {
          return id;
        }
      }
    }
    return null;
  });
});

final translationCacheStoreProvider = Provider<TranslationCacheStore>(
  (ref) => TranslationCacheStore(ref.watch(appDatabaseProvider)),
);

final translationPrefsStoreProvider = Provider<TranslationPrefsStore>(
  (ref) => TranslationPrefsStore(ref.watch(appDatabaseProvider)),
);
