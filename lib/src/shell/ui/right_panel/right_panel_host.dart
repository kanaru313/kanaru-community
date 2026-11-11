import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../playback/state/queue_view_provider.dart';
import '../../../screens/now_playing/ui/queue_host.dart';
import '../../../screens/now_playing/ui/queue_panel.dart';
import '../../state/right_panel.dart';
import 'right_panel_header.dart';

/// Fixed width of the right panel.
const double rightPanelWidth = 420;

/// Time of the sideways slide between the Queue and the Chat content.
const Duration rightPanelSlideDuration = Duration(milliseconds: 340);

/// The shell's right panel: Queue or AI chat, one at a time, 420 dp wide, no
/// drag handle. It is a sibling of the left region, so it stays painted and
/// usable while Now Playing covers the left part.
///
/// Opening from closed and closing do not animate. Switching between the two
/// slides the content sideways in top-bar button order (Queue, then Chat):
/// Queue to Chat moves left, Chat to Queue moves right.
class RightPanelHost extends ConsumerWidget {
  const RightPanelHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind = ref.watch(rightPanelProvider);
    if (kind == RightPanelKind.closed) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(left: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SizedBox(
        width: rightPanelWidth,
        child: ClipRect(
          child: AnimatedSwitcher(
            duration: reduced ? Duration.zero : rightPanelSlideDuration,
            switchInCurve: Curves.easeInOutCubic,
            switchOutCurve: Curves.easeInOutCubic,
            layoutBuilder: (current, previous) =>
                Stack(fit: StackFit.expand, children: [...previous, ?current]),
            transitionBuilder: (child, animation) {
              final from = (child.key == const ValueKey(RightPanelKind.chat))
                  ? const Offset(1, 0)
                  : const Offset(-1, 0);
              return SlideTransition(
                position: Tween(
                  begin: from,
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
            child: switch (kind) {
              RightPanelKind.chat => const _ChatContent(
                key: ValueKey(RightPanelKind.chat),
              ),
              _ => const _QueueContent(key: ValueKey(RightPanelKind.queue)),
            },
          ),
        ),
      ),
    );
  }
}

class _QueueContent extends ConsumerWidget {
  const _QueueContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        RightPanelHeader(
          title: AppLocalizations.of(context).playbackNavQueue,
          onClose: ref.read(rightPanelProvider.notifier).close,
        ),
        const Expanded(child: _QueueBody()),
      ],
    );
  }
}

/// The queue, or a line when nothing is queued (the panel may be restored
/// open with an empty queue).
class _QueueBody extends ConsumerWidget {
  const _QueueBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final empty = ref.watch(
      queueViewProvider.select((v) => v.hasValue && v.requireValue.length == 0),
    );
    if (!empty) return const QueuePanel(host: QueueHost.panel);
    return Center(
      child: Text(
        AppLocalizations.of(context).playbackQueueEmpty,
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _ChatContent extends ConsumerWidget {
  const _ChatContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Null only while the panel closes after the surface went away.
    final surface = ref.watch(chatPanelSurfaceProvider);
    return Column(
      children: [
        RightPanelHeader(
          title: AppLocalizations.of(context).appAiChat,
          menu: surface?.menu?.call(context),
          onClose: ref.read(rightPanelProvider.notifier).close,
        ),
        Expanded(child: surface?.body(context) ?? const SizedBox.shrink()),
      ],
    );
  }
}
