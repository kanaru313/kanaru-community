import '../../../platform/domain/setting.dart';
import '../../../platform/state/settings_providers.dart';

/// Whether the full-lyrics modal of the song info page shows the `m:ss` column
/// (off by default, remembered between openings). Kept here, not with the
/// Now Playing lyrics settings: it only belongs to this modal.
final Setting<bool> lyricsInfoShowTimestampsSetting = Setting<bool>(
  'lyrics.info_show_timestamps',
  false,
  decode: (json) =>
      json is bool ? json : throw const FormatException('not a bool'),
  encode: (v) => v,
);

final lyricsInfoShowTimestampsProvider = settingNotifierProvider(
  lyricsInfoShowTimestampsSetting,
);
