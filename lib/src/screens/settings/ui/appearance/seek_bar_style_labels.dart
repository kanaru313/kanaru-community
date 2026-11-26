import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../playback/domain/seek_bar_style.dart';

/// Style names, the same ones the Appearance row shows.
String seekBarStyleTitle(AppLocalizations l10n, SeekBarStyle style) =>
    switch (style) {
      SeekBarStyle.bars => l10n.settingsSeekBarStyleBars,
      SeekBarStyle.dots => l10n.settingsSeekBarStyleDots,
      SeekBarStyle.line => l10n.settingsSeekBarStyleLine,
      SeekBarStyle.mirror => l10n.settingsSeekBarStyleMirror,
      SeekBarStyle.squiggle => l10n.settingsSeekBarStyleSquiggle,
      SeekBarStyle.flat => l10n.settingsSeekBarFlat,
    };

String seekBarStyleCaption(AppLocalizations l10n, SeekBarStyle style) =>
    switch (style) {
      SeekBarStyle.bars => l10n.settingsSeekBarStyleBarsCaption,
      SeekBarStyle.dots => l10n.settingsSeekBarStyleDotsCaption,
      SeekBarStyle.line => l10n.settingsSeekBarStyleLineCaption,
      SeekBarStyle.mirror => l10n.settingsSeekBarStyleMirrorCaption,
      SeekBarStyle.squiggle => l10n.settingsSeekBarStyleSquiggleCaption,
      SeekBarStyle.flat => l10n.settingsSeekBarFlatCaption,
    };
