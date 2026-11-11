import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../playback/state/playback_providers.dart';
import '../../../../playback/ui/transport_buttons.dart';
import '../../../../playback/ui/volume_control.dart';
import '../favorite_button.dart';
import 'desktop_more_menu.dart';

/// Height of the header strip across the top of Now Playing.
const double desktopNowPlayingHeaderHeight = 64;

/// Left: close, show/hide the cover column | favourite, add to playlist (soon),
/// translate chip (soon). Right: repeat, sleep timer (soon), volume, more.
/// There is no Shuffle (it is on the queue panel and the player bar) and no
/// window buttons (they are on the top bar).
///
/// [floatingOpen] is true while the More menu is open, so whoever hides the
/// header keeps it shown.
class DesktopNowPlayingHeader extends ConsumerStatefulWidget {
  const DesktopNowPlayingHeader({
    super.key,
    required this.onClose,
    required this.columnShown,
    required this.onToggleColumn,
    required this.floatingOpen,
  });

  final VoidCallback onClose;
  final bool columnShown;
  final VoidCallback onToggleColumn;
  final ValueNotifier<bool> floatingOpen;

  @override
  ConsumerState<DesktopNowPlayingHeader> createState() =>
      _DesktopNowPlayingHeaderState();
}

class _DesktopNowPlayingHeaderState
    extends ConsumerState<DesktopNowPlayingHeader> {
  @override
  void dispose() {
    // The menu leaves with the header: give the pin back.
    widget.floatingOpen.value = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final soon = l10n.appComingSoon;
    final trackId = ref.watch(
      nowPlayingProvider.select((n) => n.value?.trackId),
    );
    return SizedBox(
      height: desktopNowPlayingHeaderHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KSpace.x3),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(KIcons.collapse),
              tooltip: l10n.playbackMinimize,
              onPressed: widget.onClose,
            ),
            IconButton(
              icon: const Icon(KIcons.sidebarCover),
              isSelected: widget.columnShown,
              tooltip: l10n.playbackToggleCoverColumn,
              onPressed: widget.onToggleColumn,
            ),
            const SizedBox(
              height: KSpace.x6,
              child: VerticalDivider(width: KSpace.x4),
            ),
            if (trackId != null) FavoriteButton(trackId: trackId),
            IconButton(
              icon: const Icon(KIcons.playlistAdd),
              tooltip: '${l10n.playbackAddToPlaylist} · $soon',
              onPressed: null,
            ),
            Padding(
              padding: const EdgeInsets.only(left: KSpace.x1),
              child: Tooltip(
                message: '${l10n.playbackTranslate} · $soon',
                child: Opacity(
                  opacity: 0.5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: KRadius.full,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: KSpace.x3,
                        vertical: KSpace.x2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: KSpace.x1,
                        children: [
                          const Icon(KIcons.language, size: 18),
                          Text(l10n.playbackTranslate),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            const RepeatButton(),
            IconButton(
              icon: const Icon(KIcons.sleepTimer),
              tooltip: '${l10n.playbackSleepTimer} · $soon',
              onPressed: null,
            ),
            const VolumeControl(),
            DesktopMoreMenu(
              onOpenChanged: (open) => widget.floatingOpen.value = open,
            ),
          ],
        ),
      ),
    );
  }
}
