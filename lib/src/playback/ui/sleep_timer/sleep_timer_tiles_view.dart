import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../state/sleep_estimates.dart';
import '../../state/sleep_timer_provider.dart';
import 'sleep_timer_clock_builder.dart';
import 'sleep_timer_draft.dart';
import 'sleep_timer_focus.dart';
import 'sleep_timer_parts.dart';
import 'sleep_timer_texts.dart';

/// First screen: every tile and row starts a timer at once ([onStart] starts,
/// announces and closes the modal); "Tuỳ chỉnh…" and "Sau số bài…" open the
/// custom screen; while a timer runs a card leads back to it.
class SleepTimerTilesView extends ConsumerWidget {
  const SleepTimerTilesView({
    super.key,
    required this.focus,
    required this.onStart,
    required this.onCustom,
    required this.onRunning,
    required this.onCancel,
    this.closing = false,
  });

  final SleepTimerFocus focus;
  final void Function(void Function(SleepTimer timer) start) onStart;
  final ValueChanged<SleepTimerKind> onCustom;
  final VoidCallback onRunning;
  final VoidCallback onCancel;

  /// The modal is animating out: the running card stays hidden, so a start
  /// from a tile does not flash it in.
  final bool closing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texts = SleepTimerTexts.of(context);
    final l10n = texts.l10n;
    final running = ref.watch(sleepTimerProvider.select((s) => s.active));
    // Action rows span the whole sheet (they keep their own gutter), so only
    // the other content is padded.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KSpace.x2),
      child: KStartArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Gutter(SleepTimerHeader(title: l10n.playbackSleepTimer)),
            _Gutter(SleepTimerCaption(l10n.sleepTimerHint)),
            if (running && !closing) ...[
              const SizedBox(height: KSpace.x3),
              Focus(
                focusNode: focus.runningCard,
                child: _RunningCard(onTap: onRunning),
              ),
            ],
            _Gutter(SleepTimerSection(l10n.sleepTimerSectionDuration)),
            _Gutter(
              SleepTimerClockBuilder(
                builder: (context, now) => KStartTileGrid(
                  children: [
                    for (final m in sleepMinutesRange.presets)
                      KStartTile(
                        title: texts.minutesLabel(m),
                        detail: texts.tileUntil(now, m),
                        semanticLabel: texts.tileStartLabel(now, m),
                        focusNode: m == sleepMinutesRange.defaultValue
                            ? focus.tile45
                            : null,
                        onPressed: () => onStart((t) => t.startMinutes(m)),
                      ),
                    KStartTile(
                      title: l10n.sleepTimerCustom,
                      detail: l10n.sleepTimerCustomRange(
                        sleepMinutesRange.min,
                        sleepMinutesRange.max,
                      ),
                      semanticLabel: l10n.sleepTimerCustom,
                      opensMore: true,
                      onPressed: () => onCustom(SleepTimerKind.minutes),
                    ),
                  ],
                ),
              ),
            ),
            _Gutter(SleepTimerSection(l10n.sleepTimerSectionTracks)),
            _EndOfTrackRow(onStart: onStart),
            _EndOfAlbumRow(onStart: onStart),
            _EndOfQueueRow(onStart: onStart),
            SelectionRow.action(
              title: Text(l10n.sleepTimerAfterTracks),
              subtitle: Text(
                l10n.sleepTimerAfterTracksRange(
                  sleepTracksRange.min,
                  sleepTracksRange.max,
                ),
              ),
              opensMore: true,
              onTap: () => onCustom(SleepTimerKind.tracks),
            ),
            _Gutter(
              SleepTimerFooter(
                children: [
                  KModalButton(
                    label: l10n.sleepTimerCancel,
                    emphasis: KModalEmphasis.text,
                    onPressed: onCancel,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Side padding of the content of this screen that is not an action row.
class _Gutter extends StatelessWidget {
  const _Gutter(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: KSpace.x4),
    child: child,
  );
}

/// "Đang chạy · Ngủ sau 23:41 ›": back to the running screen. Its own
/// consumer, so only this card follows the seconds.
class _RunningCard extends ConsumerWidget {
  const _RunningCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texts = SleepTimerTexts.of(context);
    final state = ref.watch(sleepTimerProvider);
    return SelectionRow.action(
      title: Text(texts.l10n.sleepTimerRunningWith(texts.statusText(state))),
      leading: const Icon(KIcons.sleepTimerActive),
      running: true,
      onTap: onTap,
    );
  }
}

class _EndOfTrackRow extends ConsumerWidget {
  const _EndOfTrackRow({required this.onStart});

  final void Function(void Function(SleepTimer timer) start) onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texts = SleepTimerTexts.of(context);
    final left = ref.watch(currentTrackLeftProvider);
    return SelectionRow.action(
      title: Text(texts.l10n.sleepTimerEndOfTrack),
      subtitle: left == null
          ? null
          : Text(texts.leftTime(Duration(seconds: left))),
      leading: const Icon(KIcons.songs),
      onTap: () => onStart((t) => t.startEndOfTrack()),
    );
  }
}

class _EndOfAlbumRow extends ConsumerWidget {
  const _EndOfAlbumRow({required this.onStart});

  final void Function(void Function(SleepTimer timer) start) onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texts = SleepTimerTexts.of(context);
    final run = ref.watch(albumRunProvider).value;
    final noAlbum = run?.noAlbum ?? false;
    return SelectionRow.action(
      title: Text(texts.l10n.sleepTimerEndOfAlbum),
      subtitle: run == null || noAlbum ? null : Text(texts.albumRunLine(run)),
      disabledReason: noAlbum ? texts.l10n.sleepTimerNoAlbum : null,
      leading: const Icon(KIcons.album),
      onTap: () => onStart((t) => t.startEndOfAlbum()),
    );
  }
}

class _EndOfQueueRow extends ConsumerWidget {
  const _EndOfQueueRow({required this.onStart});

  final void Function(void Function(SleepTimer timer) start) onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texts = SleepTimerTexts.of(context);
    final left = ref.watch(queueLeftProvider);
    return SelectionRow.action(
      title: Text(texts.l10n.sleepTimerEndOfQueue),
      subtitle: left == null
          ? null
          : Text(texts.leftTracks(left.tracks, time: left.time)),
      leading: const Icon(KIcons.queue),
      onTap: () => onStart((t) => t.startEndOfQueue()),
    );
  }
}
