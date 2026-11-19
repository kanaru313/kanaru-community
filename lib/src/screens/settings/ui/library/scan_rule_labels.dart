import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../library/domain/scan/scan_rule_values.dart';
import '../playback/listen_rule_sheet.dart' show listenDuration;

/// Stops of the minimum-duration slider: 0 (off) to 3 minutes in 5 s steps.
final List<int> minDurationStopsMs = [
  for (var ms = 0; ms <= maxMinDurationMs; ms += minDurationStepMs) ms,
];

/// "Off", "30 seconds", "1 minute 30 seconds" for a minimum duration.
String minDurationLabel(AppLocalizations l10n, int ms) =>
    ms == 0 ? l10n.settingsPlaybackOff : listenDuration(l10n, ms);

/// "Off", "100 KB", "1 MB", "1.5 MB" for a minimum size in bytes.
String minSizeLabel(AppLocalizations l10n, int bytes) {
  if (bytes == 0) return l10n.settingsPlaybackOff;
  if (bytes < bytesPerMb) {
    return l10n.settingsLibrarySizeKb(bytes ~/ bytesPerKb);
  }
  return l10n.settingsLibrarySizeMb(bytes / bytesPerMb);
}

/// Display name of a format group. File formats are proper names, the same in
/// every language.
String formatGroupName(String id) => switch (id) {
  'mp3' => 'MP3',
  'flac' => 'FLAC',
  'm4a' => 'M4A / AAC / ALAC',
  'ogg' => 'Ogg / Opus',
  'wav' => 'WAV',
  'aiff' => 'AIFF',
  'ape' => 'APE',
  'wavpack' => 'WavPack',
  'dsd' => 'DSD',
  _ => id,
};
