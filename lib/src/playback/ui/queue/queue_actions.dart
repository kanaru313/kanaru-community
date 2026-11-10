import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/cleanup_kind.dart';
import '../../domain/queue_cleanup.dart';
import '../../domain/queue_state.dart';
import '../../state/playback_providers.dart';
import '../../state/queue_view_provider.dart';
import 'queue_remove_action.dart';

/// The queue's icon-only action buttons: Shuffle, Add tracks (soon), Clean up
/// and, unless the host places it elsewhere, Save as playlist (soon).
///
/// [menuUp]: the clean-up dropdown opens upward (mobile footer); desktop opens
/// it downward.
class QueueActions extends StatelessWidget {
  const QueueActions({super.key, this.menuUp = false, this.includeSave = true});

  final bool menuUp;
  final bool includeSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const QueueShuffleButton(),
        const QueueSoonButton.add(),
        QueueCleanupButton(menuUp: menuUp),
        if (includeSave) const QueueSoonButton.save(),
      ],
    );
  }
}

/// Shuffles the upcoming tracks and turns shuffle on.
class QueueShuffleButton extends ConsumerWidget {
  const QueueShuffleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    icon: const Icon(KIcons.shuffle),
    tooltip: AppLocalizations.of(context).playbackShuffle,
    onPressed: () => ref.read(playerControllerProvider).reshuffleUpcoming(),
  );
}

/// A queue action that is not built yet: dimmed, "Soon" in the tooltip.
class QueueSoonButton extends StatelessWidget {
  const QueueSoonButton.add({super.key}) : _save = false;
  const QueueSoonButton.save({super.key}) : _save = true;

  final bool _save;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = _save
        ? l10n.playbackQueueSavePlaylist
        : l10n.playbackQueueAddTracks;
    return IconButton(
      icon: Icon(_save ? KIcons.playlistAdd : KIcons.libraryAdd),
      tooltip: '$label · ${l10n.appComingSoon}',
      onPressed: null,
    );
  }
}

/// "Remove from queue" dropdown with four choices and the number each
/// removes; a choice that removes nothing is dimmed. The current track is
/// never removed.
class QueueCleanupButton extends ConsumerStatefulWidget {
  const QueueCleanupButton({super.key, this.menuUp = false});

  final bool menuUp;

  @override
  ConsumerState<QueueCleanupButton> createState() => _QueueCleanupButtonState();
}

class _QueueCleanupButtonState extends ConsumerState<QueueCleanupButton> {
  CleanupCounts? _counts;

  /// Counts are worked out when the menu opens, not on every queue change.
  void _measure() {
    final view = ref.read(queueViewProvider).value;
    if (view == null) return;
    setState(() {
      _counts = cleanupCounts(
        QueueState(items: view.items, current: view.current),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    // Keeps the queue view subscribed, so it has a value when the menu opens.
    ref.watch(queueViewProvider.select((v) => v.hasValue));
    final counts = _counts;
    Widget item(String label, CleanupKind kind, int? n) => MenuItemButton(
      style: const ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(220, 48)),
      ),
      onPressed: n == null || n == 0
          ? null
          : () =>
                cleanupQueue(context, ref.read(playerControllerProvider), kind),
      trailingIcon: Text('${n ?? 0}'),
      child: Text(label),
    );
    return MenuAnchor(
      onOpen: _measure,
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHighest),
        alignment: widget.menuUp
            ? AlignmentDirectional.topStart
            : AlignmentDirectional.bottomStart,
      ),
      menuChildren: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KSpace.x4,
            vertical: KSpace.x2,
          ),
          child: Text(
            l10n.playbackQueueCleanupTitle,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        item(
          l10n.playbackCleanupDuplicates,
          CleanupKind.duplicates,
          counts?.duplicates,
        ),
        item(l10n.playbackCleanupBefore, CleanupKind.before, counts?.before),
        item(l10n.playbackCleanupAfter, CleanupKind.after, counts?.after),
        item(
          l10n.playbackCleanupAll,
          CleanupKind.allButCurrent,
          counts?.allButCurrent,
        ),
      ],
      builder: (context, controller, _) => IconButton(
        icon: const Icon(KIcons.cleaning),
        tooltip: l10n.playbackQueueCleanup,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}
