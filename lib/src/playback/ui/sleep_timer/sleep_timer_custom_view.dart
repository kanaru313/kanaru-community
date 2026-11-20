import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../state/sleep_timer_provider.dart';
import 'sleep_timer_clock_builder.dart';
import 'sleep_timer_draft.dart';
import 'sleep_timer_focus.dart';
import 'sleep_timer_number_field.dart';
import 'sleep_timer_parts.dart';
import 'sleep_timer_preset_chips.dart';
import 'sleep_timer_texts.dart';

/// Second screen: minutes or a number of tracks, set by the buttons, the
/// number, the ruler or a chip, then started with "Bắt đầu" (or Enter).
class SleepTimerCustomView extends ConsumerWidget {
  const SleepTimerCustomView({
    super.key,
    required this.draft,
    required this.focus,
    required this.onDraft,
    required this.onBack,
    required this.onRunning,
    required this.onStart,
    required this.onCancel,
  });

  final SleepTimerDraft draft;
  final SleepTimerFocus focus;
  final ValueChanged<SleepTimerDraft> onDraft;
  final VoidCallback onBack;
  final VoidCallback onRunning;
  final VoidCallback onStart;
  final VoidCallback onCancel;

  bool get _tracks => draft.kind == SleepTimerKind.tracks;

  /// One step; a button that turns off by it hands focus to its pair.
  void _step(int direction) {
    final next = draft.stepped(direction);
    onDraft(next);
    if (!next.canStepDown && focus.customMinus.hasFocus) {
      focus.customPlus.requestFocus();
    } else if (!next.canStepUp && focus.customPlus.hasFocus) {
      focus.customMinus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texts = SleepTimerTexts.of(context);
    final l10n = texts.l10n;
    final range = draft.range;
    final running = ref.watch(sleepTimerProvider.select((s) => s.active));
    return Padding(
      padding: sleepTimerPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SleepTimerHeader(
            title: l10n.sleepTimerCustomTitle,
            onBack: onBack,
            backTooltip: l10n.tooltipBack,
            trailing: running ? _RunningChip(onTap: onRunning) : null,
          ),
          const SizedBox(height: KSpace.x3),
          KSegmented<SleepTimerKind>(
            semanticLabel: l10n.sleepTimerKindLabel,
            value: draft.kind,
            segments: [
              KSegment(
                value: SleepTimerKind.minutes,
                label: l10n.sleepTimerKindMinutes,
              ),
              KSegment(
                value: SleepTimerKind.tracks,
                label: l10n.sleepTimerKindTracks,
              ),
            ],
            onChanged: (kind) => onDraft(draft.withKind(kind)),
          ),
          const SizedBox(height: KSpace.x3),
          Row(
            children: [
              KStepButton(
                icon: KIcons.remove,
                focusNode: focus.customMinus,
                semanticLabel: _tracks
                    ? l10n.sleepTimerRemoveTrack
                    : l10n.sleepTimerRemoveMinutes(range.step),
                onPressed: draft.canStepDown ? () => _step(-1) : null,
              ),
              Expanded(
                child: SleepTimerNumberField(
                  value: draft.value,
                  range: range,
                  focusNode: focus.number,
                  semanticsLabel: _tracks
                      ? l10n.sleepTimerKindTracks
                      : l10n.sleepTimerFieldMinutes,
                  onChanged: (v) => onDraft(draft.withValue(v)),
                  onSubmit: onStart,
                ),
              ),
              KStepButton(
                icon: KIcons.add,
                focusNode: focus.customPlus,
                semanticLabel: _tracks
                    ? l10n.sleepTimerAddTrack
                    : l10n.sleepTimerAddMinutes(range.step),
                onPressed: draft.canStepUp ? () => _step(1) : null,
              ),
            ],
          ),
          // Room for the caret of the number above: it never reaches the unit.
          const SizedBox(height: KSpace.x1),
          Text(
            _tracks
                ? texts.unitTracks(draft.value)
                : texts.unitMinutes(draft.value),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: KSpace.x2),
          KRuler(
            min: range.min,
            max: range.rulerMax,
            value: draft.rulerValue,
            majorEvery: range.rulerMajorEvery,
            labelEvery: range.rulerLabelEvery,
            semanticLabel: _tracks
                ? l10n.sleepTimerKindTracks
                : l10n.sleepTimerFieldMinutes,
            valueLabel: (v) => _tracks
                ? l10n.sleepTimerTracksCount(v)
                : texts.durationWords(v),
            tickLabel: _tracks ? null : (v) => _rulerTick(texts, v),
            onChanged: (v) => onDraft(draft.withValue(v)),
            onSubmit: onStart,
          ),
          const SizedBox(height: KSpace.x2),
          Center(
            child: _tracks
                ? KPill(
                    icon: KIcons.songs,
                    label: texts.stopsAfterTracks(draft.tracks),
                  )
                : SleepTimerClockBuilder(
                    builder: (context, now) => KPill(
                      icon: KIcons.sleepAt,
                      label: texts.stopsAt(now, draft.minutes),
                    ),
                  ),
          ),
          const SizedBox(height: KSpace.x3),
          SleepTimerPresetChips(
            // A new row per kind: it opens scrolled to its chosen chip.
            key: ValueKey(draft.kind),
            presets: range.presets,
            selected: draft.matchingPreset,
            label: (p) => _tracks ? '$p' : texts.chipLabel(p),
            tooltip: (p) => _tracks
                ? l10n.sleepTimerTracksCount(p)
                : texts.durationWords(p),
            onSelected: (p) => onDraft(draft.withValue(p)),
          ),
          SleepTimerFooter(
            children: [
              KModalButton(
                label: l10n.sleepTimerCancel,
                emphasis: KModalEmphasis.text,
                onPressed: onCancel,
              ),
              KModalButton(label: l10n.sleepTimerStart, onPressed: onStart),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ruler number of a minute: "45", "1 giờ", "1:15".
String _rulerTick(SleepTimerTexts texts, int minutes) {
  if (minutes < 60) return '$minutes';
  if (minutes % 60 == 0) return texts.l10n.sleepTimerHours(minutes ~/ 60);
  return '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';
}

/// "Đang chạy · 23:41": back to the running screen. Its own consumer, so only
/// the chip follows the seconds.
class _RunningChip extends ConsumerWidget {
  const _RunningChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texts = SleepTimerTexts.of(context);
    final state = ref.watch(sleepTimerProvider);
    return KChip(
      dense: true,
      icon: const Icon(KIcons.sleepTimerActive),
      label: Text(
        texts.l10n.sleepTimerRunningWith(texts.pillLabel(state)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }
}
