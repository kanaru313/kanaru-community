import '../../platform/domain/setting.dart';
import '../../platform/state/settings_providers.dart';
import '../domain/local_lyrics_pick.dart';
import '../domain/lyrics_display_prefs.dart';
import '../domain/online/source_prefs.dart';

/// A setting stored as the name of an enum member; an unknown stored name
/// falls back to [fallback] (logged by the notifier).
Setting<T> _enumSetting<T extends Enum>(
  String key,
  List<T> values,
  T fallback,
) => Setting<T>(
  key,
  fallback,
  decode: (json) => enumByName(values, json),
  encode: (v) => v.name,
);

final Setting<LyricsFontScale> lyricsFontScaleSetting = _enumSetting(
  'lyrics.font_scale',
  LyricsFontScale.values,
  LyricsFontScale.medium,
);

final Setting<LyricsAlign> lyricsAlignSetting = _enumSetting(
  'lyrics.align',
  LyricsAlign.values,
  LyricsAlign.start,
);

final Setting<LyricsAutoReturn> lyricsAutoReturnSetting = _enumSetting(
  'lyrics.auto_return',
  LyricsAutoReturn.values,
  LyricsAutoReturn.off,
);

final Setting<LyricsDim> lyricsDimSetting = _enumSetting(
  'lyrics.dim',
  LyricsDim.values,
  LyricsDim.light,
);

/// Which local source wins on equal quality.
final Setting<LocalFirst> lyricsLocalFirstSetting = _enumSetting(
  'lyrics.local_first',
  LocalFirst.values,
  LocalFirst.tag,
);

/// Look lyrics up online for a track that has none (the sources are the
/// plugins switched on in [lyricsOnlineSourcesSetting]).
final Setting<bool> lyricsAutoSearchSetting = Setting<bool>(
  'lyrics.auto_search',
  true,
  decode: (json) {
    if (json is bool) return json;
    throw FormatException('not a bool: $json');
  },
  encode: (v) => v,
);

/// The user's order and switches of the lyrics plugins, device-local. Plugins
/// not listed follow in install order (see `applySourcePrefs`).
final Setting<List<SourcePref>> lyricsOnlineSourcesSetting =
    Setting<List<SourcePref>>(
      'lyrics.online_sources',
      const [],
      decode: decodeSourcePrefs,
      encode: (prefs) => [for (final p in prefs) p.toJson()],
    );

final lyricsFontScaleProvider = settingNotifierProvider(lyricsFontScaleSetting);
final lyricsAlignProvider = settingNotifierProvider(lyricsAlignSetting);
final lyricsAutoReturnProvider = settingNotifierProvider(
  lyricsAutoReturnSetting,
);
final lyricsDimProvider = settingNotifierProvider(lyricsDimSetting);
final lyricsLocalFirstProvider = settingNotifierProvider(
  lyricsLocalFirstSetting,
);
final lyricsAutoSearchProvider = settingNotifierProvider(
  lyricsAutoSearchSetting,
);
final lyricsOnlineSourcesProvider = settingNotifierProvider(
  lyricsOnlineSourcesSetting,
);
