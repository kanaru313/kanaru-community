import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart' hide RepeatMode;

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/repeat_mode.dart';
import '../../state/queue_totals_provider.dart';
import '../../state/queue_view_provider.dart';

/// "1 h 5 min", "42 min" or "under 1 min".
String formatRemaining(AppLocalizations l10n, Duration d) {
  final minutes = d.inMinutes;
  if (minutes < 1) return l10n.playbackRemainingUnderMinute;
  if (minutes < 60) return l10n.playbackRemainingMinutes(minutes);
  return l10n.playbackRemainingHoursMinutes(minutes ~/ 60, minutes % 60);
}

/// The count line of the queue head.
/// Mobile: `8/23 · 1 h 5 min left`. Panel (desktop): `23 tracks · 1 h 5 min left`, the playing position in the
/// tooltip so the line fits the 420 dp panel.
/// The time comes from `queueRemainingProvider` (one SQL sum), never from
/// adding up row infos; until it arrives the line has no time part. Under a
/// repeat mode (the queue never ends) it has none either; a counted repeat on
/// top of "stop at the end" keeps it.
class QueueCounts extends ConsumerWidget {
  const QueueCounts({super.key, required this.mobile});

  final bool mobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final total = ref.watch(queueViewProvider.select((v) => v.value?.length));
    final current = ref.watch(
      queueViewProvider.select((v) => v.value?.current),
    );
    // Under any repeat the queue never runs out, so there is no time left.
    final endless = ref.watch(
      queueViewProvider.select(
        (v) => (v.value?.repeat ?? RepeatMode.off) != RepeatMode.off,
      ),
    );
    if (total == null || total == 0) return const SizedBox.shrink();
    final remaining = endless ? null : ref.watch(queueRemainingProvider).value;
    final position = (current ?? -1) + 1;
    final left = remaining == null ? null : formatRemaining(l10n, remaining);
    final text = mobile
        ? (left == null
              ? '$position/$total'
              : l10n.playbackQueueMobileCounts(position, total, left))
        : (left == null
              ? l10n.playbackQueuePanelShort(total)
              : l10n.playbackQueuePanelCounts(total, left));
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    if (mobile) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    return KOverflowTooltip(
      text: text,
      message: l10n.playbackQueuePlayingAt(position),
      style: style,
    );
  }
}

/// The ⋮ dropdown of the queue head. It only holds "Select several": it runs
/// [onSelectMany] (the host selects the current song), and is enabled only
/// while a song is current. Without a callback it stays dimmed ("Coming soon").
class QueueMoreMenu extends ConsumerWidget {
  const QueueMoreMenu({super.key, this.onSelectMany});

  final VoidCallback? onSelectMany;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasCurrent = ref.watch(
      queueViewProvider.select((v) => v.value?.current != null),
    );
    final onPressed = hasCurrent ? onSelectMany : null;
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHighest),
      ),
      menuChildren: [
        MenuItemButton(
          style: const ButtonStyle(
            minimumSize: WidgetStatePropertyAll(Size(0, 48)),
          ),
          onPressed: onPressed,
          trailingIcon: onSelectMany == null ? Text(l10n.appComingSoon) : null,
          child: Text(l10n.playbackQueueSelectMany),
        ),
      ],
      builder: (context, controller, _) => IconButton(
        icon: const Icon(KIcons.moreVert),
        tooltip: l10n.playbackMore,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}
