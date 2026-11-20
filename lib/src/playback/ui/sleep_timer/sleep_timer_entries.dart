import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../state/playback_providers.dart';
import '../../state/sleep_timer_provider.dart';
import 'sleep_timer_return_focus.dart';
import 'sleep_timer_texts.dart';

export 'sleep_timer_return_focus.dart'
    show SleepTimerOpener, openSleepTimerModal;

// Where the timer is opened from and how a running one shows. The modal says
// by itself when it closes on a timer that ended ("ended" announcement), and
// the entries never announce an expiry: with a player bar, a header and the
// modal on screen at once, each of them speaking would say it two or three
// times. The pause that ends the timer is audible.

/// The desktop entry (player bar, Now Playing header): the timer icon while
/// off, a pill with what is left while running. One focus node serves both
/// looks, so focus stays on the entry when a start or Tắt swaps one for the
/// other, and returns to it when the modal closes. It is empty while no track
/// is loaded.
///
/// [opener] replaces the plain modal opening, for a screen that pins its
/// chrome while the modal is open.
class SleepTimerDesktopEntry extends ConsumerStatefulWidget {
  const SleepTimerDesktopEntry({
    super.key,
    this.placement = KPillPlacement.standard,
    this.opener,
  });

  final KPillPlacement placement;
  final SleepTimerOpener? opener;

  @override
  ConsumerState<SleepTimerDesktopEntry> createState() =>
      _SleepTimerDesktopEntryState();
}

class _SleepTimerDesktopEntryState
    extends ConsumerState<SleepTimerDesktopEntry> {
  final _focus = SleepEntryFocus(debugLabel: 'sleep timer entry');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _open() => _focus.open(context, widget.opener ?? openSleepTimerModal);

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(hasCurrentTrackProvider)) return const SizedBox.shrink();
    // Only the on / off flip rebuilds this; the pill below follows the ticks.
    final running = ref.watch(sleepTimerProvider.select((s) => s.active));
    if (!running) {
      return KIconButton(
        icon: KIcons.sleepTimer,
        tooltip: SleepTimerTexts.of(context).l10n.playbackSleepTimer,
        focusNode: _focus.node,
        onPressed: _open,
      );
    }
    return _RunningPill(
      focusNode: _focus.node,
      placement: widget.placement,
      onPressed: _open,
    );
  }
}

class _RunningPill extends ConsumerWidget {
  const _RunningPill({
    required this.focusNode,
    required this.placement,
    required this.onPressed,
  });

  final FocusNode focusNode;
  final KPillPlacement placement;
  final VoidCallback onPressed;

  /// The widest text the label can take in this run, so the pill keeps its
  /// width while it ticks.
  static String _widest(SleepTimerTexts texts, SleepTimerState s) {
    switch (s.mode) {
      case SleepTimerMode.minutes:
        final longest = s.setLength > s.remaining ? s.setLength : s.remaining;
        return longest >= const Duration(hours: 1) ? '0:00:00' : '00:00';
      case SleepTimerMode.tracks:
        return texts.l10n.sleepTimerTracksCount(
          math.max(s.tracksAtStart, s.tracksLeft),
        );
      default:
        return texts.pillLabel(s);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sleepTimerProvider);
    if (!s.active) return const SizedBox.shrink();
    final texts = SleepTimerTexts.of(context);
    return KPill(
      icon: KIcons.sleepTimerActive,
      label: texts.pillLabel(s),
      widestLabel: _widest(texts, s),
      held: s.countingPaused,
      placement: placement,
      focusNode: focusNode,
      tooltip: texts.entryStatusTooltip(s),
      semanticLabel: texts.entryLabel(s, minutePrecision: true),
      onPressed: onPressed,
    );
  }
}

/// The mobile entry: a round button with a progress ring, only while a timer
/// runs (the timer is started from the ⋮ menu). The ring fills with what is
/// left of a minutes timer; the other modes show a dot.
///
/// Focus returns to this button when the modal closes. When Tắt removes it,
/// focus goes to [fallbackFocus] (the ⋮ button).
class SleepTimerRingButton extends ConsumerStatefulWidget {
  const SleepTimerRingButton({super.key, this.fallbackFocus, this.opener});

  final FocusNode? fallbackFocus;
  final SleepTimerOpener? opener;

  @override
  ConsumerState<SleepTimerRingButton> createState() =>
      _SleepTimerRingButtonState();
}

class _SleepTimerRingButtonState extends ConsumerState<SleepTimerRingButton> {
  final _focus = SleepEntryFocus(debugLabel: 'sleep timer ring');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _open() {
    _focus.fallback = widget.fallbackFocus;
    _focus.open(context, widget.opener ?? openSleepTimerModal);
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(hasCurrentTrackProvider)) return const SizedBox.shrink();
    final s = ref.watch(sleepTimerProvider);
    if (!s.active) return const SizedBox.shrink();
    final texts = SleepTimerTexts.of(context);
    final length = s.setLength.inMilliseconds;
    return KIconButton(
      shape: KIconButtonShape.circle,
      tooltip: texts.entryLabel(s),
      semanticLabel: texts.entryLabel(s, minutePrecision: true),
      focusNode: _focus.node,
      onPressed: _open,
      child: KProgressRingIcon(
        icon: KIcons.sleepTimer,
        progress: s.mode == SleepTimerMode.minutes && length > 0
            ? s.remaining.inMilliseconds / length
            : null,
        held: s.countingPaused,
      ),
    );
  }
}

/// The label of the ⋮ item: "Hẹn giờ ngủ · còn 23:41" ticking while a timer
/// runs, "Hẹn giờ ngủ" while off. A screen reader reads minutes ("còn 24
/// phút"), so it does not talk every second.
class SleepTimerMenuLabel extends ConsumerWidget {
  const SleepTimerMenuLabel({super.key, this.style});

  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sleepTimerProvider);
    final texts = SleepTimerTexts.of(context);
    return Semantics(
      label: texts.menuLabel(s, minutePrecision: true),
      excludeSemantics: true,
      child: Text(
        texts.menuLabel(s),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}

/// [SleepTimerMenuLabel] as a `WidgetBuilder`, for a menu item's live label.
Widget sleepTimerMenuLabelBuilder(BuildContext context) =>
    const SleepTimerMenuLabel();
