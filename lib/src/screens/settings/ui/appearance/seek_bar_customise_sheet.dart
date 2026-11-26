import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../playback/domain/seek_bar_options.dart';
import '../../../../playback/domain/seek_bar_style.dart';
import '../../../../playback/state/seek_bar_style_provider.dart';
import 'seek_bar_preview_card.dart';
import 'seek_bar_preview_clock.dart';
import 'seek_bar_style_labels.dart' show seekBarStyleTitle;

/// Opens the customise sheet of [style] (bottom sheet on the mobile shell,
/// side sheet on desktop), moved by the page's [clock].
Future<void> showSeekBarCustomiseSheet(
  BuildContext context, {
  required SeekBarStyle style,
  required SeekPreviewClock clock,
  FocusNode? returnFocus,
}) => showKAdaptiveSheet<void>(
  context,
  returnFocus: returnFocus,
  builder: (_) => SeekBarCustomiseSheet(style: style, clock: clock),
);

/// Options of one style group in a [KCustomiseSheetFrame]: its own preview
/// bar, one segmented row per option and a reset of that group only. A change
/// is written at once; the preview follows the stored value.
class SeekBarCustomiseSheet extends ConsumerWidget {
  const SeekBarCustomiseSheet({
    super.key,
    required this.style,
    required this.clock,
  });

  final SeekBarStyle style;
  final SeekPreviewClock clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final group = switch (style) {
      SeekBarStyle.squiggle => _squiggle(ref, l10n),
      SeekBarStyle.flat => _flat(ref, l10n),
      SeekBarStyle.bars ||
      SeekBarStyle.dots ||
      SeekBarStyle.line ||
      SeekBarStyle.mirror => _wave(ref, l10n),
    };
    return KCustomiseSheetFrame(
      title: l10n.settingsSeekBarCustomiseTitle(seekBarStyleTitle(l10n, style)),
      closeTooltip: l10n.settingsSeekBarCustomiseClose,
      onClose: () => Navigator.of(context).maybePop(),
      preview: SeekDemoBar(clock: clock, style: style),
      caption: group.caption,
      resetLabel: l10n.settingsSeekBarReset,
      resetEnabled: !group.isDefault,
      onReset: group.reset,
      children: group.rows,
    );
  }

  _Group _wave(WidgetRef ref, AppLocalizations l10n) {
    final notifier = ref.read(waveSeekOptionsProvider.notifier);
    final o = ref.watch(waveSeekOptionsProvider);
    return _Group(
      isDefault: o.isDefault,
      reset: () => notifier.set(WaveSeekOptions.defaults),
      rows: [
        _row(l10n.settingsSeekBarRowDensity, o.density, {
          WaveDensity.loose: l10n.settingsSeekBarOptLoose,
          WaveDensity.mid: l10n.settingsSeekBarOptMid,
          WaveDensity.dense: l10n.settingsSeekBarOptThick,
        }, (v) => notifier.set(o.copyWith(density: v))),
        _row(l10n.settingsSeekBarRowPlayed, o.played, {
          WavePlayed.single: l10n.settingsSeekBarOptSingle,
          WavePlayed.gradient: l10n.settingsSeekBarOptGradient,
          WavePlayed.height: l10n.settingsSeekBarOptByHeight,
        }, (v) => notifier.set(o.copyWith(played: v))),
        _row(l10n.settingsSeekBarRowRest, o.rest, {
          WaveRest.dim: l10n.settingsSeekBarOptDim,
          WaveRest.outline: l10n.settingsSeekBarOptOutline,
          WaveRest.hidden: l10n.settingsSeekBarOptHidden,
        }, (v) => notifier.set(o.copyWith(rest: v))),
        _row(l10n.settingsSeekBarRowFeedback, o.feedback, {
          WaveFeedback.jelly: l10n.settingsSeekBarOptJelly,
          WaveFeedback.lens: l10n.settingsSeekBarOptLens,
          WaveFeedback.off: l10n.settingsSeekBarOptOff,
        }, (v) => notifier.set(o.copyWith(feedback: v))),
      ],
    );
  }

  _Group _squiggle(WidgetRef ref, AppLocalizations l10n) {
    final notifier = ref.read(squiggleSeekOptionsProvider.notifier);
    final o = ref.watch(squiggleSeekOptionsProvider);
    return _Group(
      isDefault: o.isDefault,
      reset: () => notifier.set(SquiggleSeekOptions.defaults),
      // The music motion falls back to drift while a track has no waveform.
      caption: o.motion == SquiggleMotion.music
          ? l10n.settingsSeekBarDriftNote
          : null,
      rows: [
        _row(l10n.settingsSeekBarRowAmplitude, o.amplitude, {
          SquiggleAmplitude.low: l10n.settingsSeekBarOptLow,
          SquiggleAmplitude.mid: l10n.settingsSeekBarOptMid,
          SquiggleAmplitude.high: l10n.settingsSeekBarOptHigh,
        }, (v) => notifier.set(o.copyWith(amplitude: v))),
        _row(l10n.settingsSeekBarRowWavelength, o.wavelength, {
          SquiggleWavelength.short: l10n.settingsSeekBarOptShort,
          SquiggleWavelength.mid: l10n.settingsSeekBarOptMid,
          SquiggleWavelength.long: l10n.settingsSeekBarOptLong,
        }, (v) => notifier.set(o.copyWith(wavelength: v))),
        _row(l10n.settingsSeekBarRowMotion, o.motion, {
          SquiggleMotion.drift: l10n.settingsSeekBarOptDrift,
          SquiggleMotion.music: l10n.settingsSeekBarOptMusic,
          SquiggleMotion.still: l10n.settingsSeekBarOptStill,
        }, (v) => notifier.set(o.copyWith(motion: v))),
        _thumbRow(l10n, o.thumb, (v) => notifier.set(o.copyWith(thumb: v))),
      ],
    );
  }

  _Group _flat(WidgetRef ref, AppLocalizations l10n) {
    final notifier = ref.read(flatSeekOptionsProvider.notifier);
    final o = ref.watch(flatSeekOptionsProvider);
    return _Group(
      isDefault: o.isDefault,
      reset: () => notifier.set(FlatSeekOptions.defaults),
      rows: [
        _row(l10n.settingsSeekBarRowThickness, o.thickness, {
          FlatThickness.thin: l10n.settingsSeekBarOptThin,
          FlatThickness.mid: l10n.settingsSeekBarOptMid,
          FlatThickness.thick: l10n.settingsSeekBarOptThick,
        }, (v) => notifier.set(o.copyWith(thickness: v))),
        _thumbRow(l10n, o.thumb, (v) => notifier.set(o.copyWith(thumb: v))),
        _row(l10n.settingsSeekBarRowPlayed, o.played, {
          FlatPlayed.single: l10n.settingsSeekBarOptSingle,
          FlatPlayed.gradient: l10n.settingsSeekBarOptGradient,
        }, (v) => notifier.set(o.copyWith(played: v))),
        _row(l10n.settingsSeekBarRowEffect, o.effect, {
          FlatEffect.off: l10n.settingsSeekBarOptOff,
          FlatEffect.shine: l10n.settingsSeekBarOptShine,
          FlatEffect.comet: l10n.settingsSeekBarOptComet,
          FlatEffect.sparks: l10n.settingsSeekBarOptSparks,
        }, (v) => notifier.set(o.copyWith(effect: v))),
      ],
    );
  }

  Widget _thumbRow(
    AppLocalizations l10n,
    SeekThumb value,
    ValueChanged<SeekThumb> onChanged,
  ) => _row(l10n.settingsSeekBarRowThumb, value, {
    SeekThumb.bar: l10n.settingsSeekBarOptThumbBar,
    SeekThumb.dot: l10n.settingsSeekBarOptThumbDot,
    SeekThumb.none: l10n.settingsSeekBarOptThumbNone,
  }, onChanged);

  Widget _row<T>(
    String title,
    T value,
    Map<T, String> labels,
    ValueChanged<T> onChanged,
  ) => KSegmentedRow<T>(
    title: title,
    value: value,
    onChanged: onChanged,
    segments: [
      for (final e in labels.entries) KSegment<T>(value: e.key, label: e.value),
    ],
  );
}

/// The rows of one style group with what the frame needs around them.
class _Group {
  const _Group({
    required this.rows,
    required this.isDefault,
    required this.reset,
    this.caption,
  });

  final List<Widget> rows;
  final bool isDefault;
  final VoidCallback reset;
  final String? caption;
}
