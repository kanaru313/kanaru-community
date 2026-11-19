import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../platform/domain/setting.dart';
import '../../../platform/domain/settings_store.dart';
import '../../../platform/state/settings_providers.dart';
import '../../domain/scan/read_rules.dart';

/// `library.artist_separators`: what separates the names of an artist tag.
/// A damaged list (not strings, an entry the entry check would refuse) means
/// the default list as a whole; an empty list is valid (no splitting).
final Setting<List<String>> artistSeparatorsSetting = Setting(
  'library.artist_separators',
  defaultArtistSeparators,
  decode: decodeSplitEntries,
  encode: (v) => v,
);

/// `library.artist_keep_whole`: names that hold a separator and stay one
/// artist. Decoded like [artistSeparatorsSetting].
final Setting<List<String>> artistKeepWholeSetting = Setting(
  'library.artist_keep_whole',
  defaultArtistKeepWhole,
  decode: decodeSplitEntries,
  encode: (v) => v,
);

/// `library.language_source`: where a track's language comes from.
final Setting<LanguageSource> languageSourceSetting = Setting(
  'library.language_source',
  LanguageSource.tagThenDetected,
  // `detectedOnly` is not available yet (the reader detects only untagged
  // files): a stored value behaves as the default.
  decode: (json) {
    final source = enumByName(LanguageSource.values, json);
    return source == LanguageSource.detectedOnly
        ? LanguageSource.tagThenDetected
        : source;
  },
  encode: (v) => v.name,
);

/// `library.read_rules_applied`: for each music folder (source uid), the
/// fingerprint of the read rules its rows were last read with. Written by the
/// scanner only.
final Setting<Map<String, String>> readRulesAppliedSetting = Setting(
  'library.read_rules_applied',
  const <String, String>{},
  decode: decodeReadRulesApplied,
  encode: (v) => v,
);

/// The applied map of [json]. Not a map: throws (the default is used);
/// an entry that is not a string is left out, so that folder counts as read
/// with the default rules.
Map<String, String> decodeReadRulesApplied(Object? json) {
  if (json is! Map) throw FormatException('not a map: $json');
  return {
    for (final e in json.entries)
      if (e.key is String && e.value is String)
        e.key as String: e.value as String,
  };
}

final artistSeparatorsProvider = settingNotifierProvider(
  artistSeparatorsSetting,
);
final artistKeepWholeProvider = settingNotifierProvider(artistKeepWholeSetting);
final languageSourceProvider = settingNotifierProvider(languageSourceSetting);

/// The read rules as the settings hold them now. A pass reads it once when
/// it starts.
final currentReadRulesProvider = Provider<LibraryReadRules>(
  (ref) => LibraryReadRules(
    separators: ref.watch(artistSeparatorsProvider),
    keepWhole: ref.watch(artistKeepWholeProvider),
    languageSource: ref.watch(languageSourceProvider),
  ),
);

/// The applied map from [store]; a missing or damaged value is empty.
Map<String, String> readAppliedFingerprints(SettingsStore store) {
  final raw = store.read(readRulesAppliedSetting.key);
  if (raw == null) return const {};
  try {
    return decodeReadRulesApplied(raw);
  } on FormatException {
    return const {};
  }
}

/// Records that [sourceUid] was read with [fingerprint], keeping every other
/// entry. The read and the write happen with no await between them, so two
/// folders finishing together cannot lose each other's entry.
Future<void> recordReadRulesApplied(
  SettingsStore store,
  String sourceUid,
  String fingerprint,
) {
  final merged = {...readAppliedFingerprints(store), sourceUid: fingerprint};
  return store.write(readRulesAppliedSetting.key, merged);
}
