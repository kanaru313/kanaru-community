import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../playback/state/playback_providers.dart';
import '../../../../playback/state/track_info_providers.dart';
import '../../../../playback/ui/sleep_timer/sleep_timer_entries.dart';
import '../../../../playback/ui/sleep_timer/sleep_timer_modal.dart';
import '../../../../playback/ui/transport_buttons.dart';
import '../../../../playback/ui/volume_control.dart';
import '../favorite_button.dart';
import '../now_playing_playlist_actions.dart';
import 'desktop_more_menu.dart';
import 'now_playing_chrome.dart';

/// Height of the header strip across the top of Now Playing.
const double desktopNowPlayingHeaderHeight = 64;

/// Left: close, show/hide the cover column | favourite, add to playlist,
/// translate chip (soon). Right: repeat, sleep timer, volume, more.
/// There is no Shuffle (it is on the queue panel and the player bar) and no
/// window buttons (they are on the top bar).
///
/// The More menu and the sleep timer modal pin [chrome] while open, so
/// whoever hides the header keeps it shown.
class DesktopNowPlayingHeader extends ConsumerStatefulWidget {
  const DesktopNowPlayingHeader({
    super.key,
    required this.onClose,
    required this.columnShown,
    required this.onToggleColumn,
    required this.chrome,
  });

  final VoidCallback onClose;
  final bool columnShown;
  final VoidCallback onToggleColumn;
  final NowPlayingChrome chrome;

  @override
  ConsumerState<DesktopNowPlayingHeader> createState() =>
      _DesktopNowPlayingHeaderState();
}

class _DesktopNowPlayingHeaderState
    extends ConsumerState<DesktopNowPlayingHeader> {
  /// Opens the modal with the header pinned. A header that left the tree
  /// meanwhile (Now Playing closed) leaves its controller alone: the screen
  /// disposes it.
  Future<void> _openSleepTimer(
    BuildContext context,
    FocusNode returnFocus,
  ) async {
    final chrome = widget.chrome..pinFloating();
    try {
      await showSleepTimer(context, returnFocus: returnFocus);
    } finally {
      if (mounted) chrome.unpinFloating();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final soon = l10n.appComingSoon;
    final trackId = ref.watch(
      nowPlayingProvider.select((n) => n.value?.trackId),
    );
    final info = trackId == null
        ? null
        : ref.watch(trackInfoProvider(trackId)).value;
    return SizedBox(
      height: desktopNowPlayingHeaderHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KSpace.x3),
        child: Row(
          children: [
            KIconButton(
              icon: KIcons.collapse,
              tooltip: l10n.playbackMinimize,
              onPressed: widget.onClose,
            ),
            KIconButton(
              icon: KIcons.sidebarCover,
              selected: widget.columnShown,
              tooltip: l10n.playbackToggleCoverColumn,
              onPressed: widget.onToggleColumn,
            ),
            const SizedBox(
              height: KSpace.x6,
              child: VerticalDivider(width: KSpace.x4),
            ),
            if (trackId != null) FavoriteButton(trackId: trackId),
            KIconButton(
              icon: KIcons.playlistAdd,
              tooltip: l10n.playbackAddToPlaylist,
              onPressed: info == null
                  ? null
                  : () => addCurrentToPlaylist(context, info),
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
                          const Icon(KIcons.language, size: KIconSize.xs),
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
            SleepTimerDesktopEntry(opener: _openSleepTimer),
            const VolumeControl(),
            DesktopMoreMenu(chrome: widget.chrome),
          ],
        ),
      ),
    );
  }
}
