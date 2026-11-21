import '../../platform/domain/setting.dart';
import '../../platform/state/settings_providers.dart';
import '../domain/local_lyrics_pick.dart';
import '../domain/lyrics_display_prefs.dart';

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

final lyricsFontScaleProvider = settingNotifierProvider(lyricsFontScaleSetting);
final lyricsAlignProvider = settingNotifierProvider(lyricsAlignSetting);
final lyricsAutoReturnProvider = settingNotifierProvider(
  lyricsAutoReturnSetting,
);
final lyricsDimProvider = settingNotifierProvider(lyricsDimSetting);
final lyricsLocalFirstProvider = settingNotifierProvider(
  lyricsLocalFirstSetting,
);
