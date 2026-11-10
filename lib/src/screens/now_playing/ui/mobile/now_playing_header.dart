import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../playback/state/playback_providers.dart';
import '../play_context_text.dart';

/// Height of the mobile page header.
const double nowPlayingHeaderHeight = 56;

/// `[⌄] · position over source · [⋮]`. The part between the buttons is the
/// drag handle the page owner attaches a gesture to ([dragHandle]).
class NowPlayingHeader extends ConsumerWidget {
  const NowPlayingHeader({
    super.key,
    required this.onClose,
    required this.onMore,
    required this.dragHandle,
  });

  final VoidCallback onClose;
  final VoidCallback onMore;

  /// Wraps the title area with the drag-to-close gesture.
  final Widget Function(Widget child) dragHandle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final place = ref.watch(
      nowPlayingProvider.select((n) => (n.value?.index, n.value?.length)),
    );
    final source = ref.watch(
      nowPlayingProvider.select((n) => n.value?.context),
    );
    final (index, length) = place;
    return SizedBox(
      height: nowPlayingHeaderHeight,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(KIcons.collapse),
            tooltip: l10n.playbackMinimize,
            onPressed: onClose,
          ),
          Expanded(
            child: dragHandle(
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (index != null)
                      Text(
                        '${index + 1}/$length',
                        style: text.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    Text(
                      playContextText(l10n, source),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(KIcons.moreVert),
            tooltip: l10n.playbackMore,
            onPressed: onMore,
          ),
        ],
      ),
    );
  }
}
