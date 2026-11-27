import '../../../../l10n/gen/app_localizations.dart';
import '../../../playback/domain/seek_bar_style.dart';
import '../../../plugins/domain/package/seekbar_spec.dart';
import '../../settings/ui/appearance/seek_bar_style_labels.dart';

/// The built-in style a seek bar plugin draws on: its `track` family.
SeekBarStyle seekbarBaseStyle(SeekbarSpec spec) => switch (spec.track) {
  WaveTrack(:final kind) => switch (kind) {
    WaveKind.bars => SeekBarStyle.bars,
    WaveKind.dots => SeekBarStyle.dots,
    WaveKind.line => SeekBarStyle.line,
    WaveKind.mirror => SeekBarStyle.mirror,
  },
  SquigTrack() => SeekBarStyle.squiggle,
  FlatTrack() => SeekBarStyle.flat,
};

/// Whether the plugin can hold ★ (its base needs no waveform).
bool seekbarCanHoldStar(SeekbarSpec spec) =>
    !waveSeekBarStyles.contains(seekbarBaseStyle(spec));

/// The base style's name, as the Thanh tua page writes it.
String seekbarBaseTitle(AppLocalizations l10n, SeekbarSpec spec) =>
    seekBarStyleTitle(l10n, seekbarBaseStyle(spec));

/// "Nền" fact: the base name, with the ★ note when the plugin can hold it.
String seekbarBaseFact(AppLocalizations l10n, SeekbarSpec spec) =>
    seekbarCanHoldStar(spec)
    ? l10n.pluginsSkBaseStar(seekbarBaseTitle(l10n, spec))
    : seekbarBaseTitle(l10n, spec);

/// "plugin.json + 1 ảnh PNG" for the asset files [names] (paths or bare file
/// names; only the extension is read).
String seekbarFilesText(AppLocalizations l10n, Iterable<String> names) {
  var png = 0;
  var webp = 0;
  var lottie = 0;
  for (final name in names) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) {
      png++;
    } else if (lower.endsWith('.webp')) {
      webp++;
    } else if (lower.endsWith('.json')) {
      lottie++;
    }
  }
  final parts = [
    if (png > 0) l10n.pluginsSkImagesPng(png),
    if (webp > 0) l10n.pluginsSkImagesWebp(webp),
    if (lottie > 0) l10n.pluginsSkImagesLottie,
  ];
  return parts.isEmpty
      ? 'plugin.json'
      : l10n.pluginsSkFilesWithImages(parts.join(' + '));
}
