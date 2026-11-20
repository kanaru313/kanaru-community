import 'dart:async';

import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/track_info.dart';
import '../../../playback/ui/sleep_timer/sleep_timer_entries.dart';
import '../../../playback/ui/sleep_timer/sleep_timer_modal.dart';
import 'now_playing_playlist_actions.dart';
import 'track_navigation.dart';

/// One entry of the "More" menu of Now Playing.
class NowPlayingMoreItem {
  const NowPlayingMoreItem({
    required this.label,
    required this.icon,
    this.onTap,
    this.pro = false,
    this.soon = true,
    this.liveLabel,
  });

  final String label;
  final IconData icon;

  /// Null = disabled. With [soon] it is not built yet; without, the item
  /// exists but does not apply to this track (no album, no artist).
  final VoidCallback? onTap;

  /// Not built yet: shows "Coming soon" (or the Pro badge).
  final bool soon;

  /// Shows the Pro badge (the feature is Pro and not built yet).
  final bool pro;

  /// Replaces the plain [label] with a widget that follows state (the sleep
  /// timer's "· còn 23:41"). It brings its own text style and semantics.
  final WidgetBuilder? liveLabel;
}

/// Opens the sleep timer from the mobile sheet. The sheet has popped by the
/// time this runs, so its own context is gone: the modal opens on the root
/// navigator captured while the items were built.
Future<void> _openSleepTimerOnRoot(NavigatorState root) async {
  if (!root.mounted) return;
  // No input focus to give back on a phone: the node only satisfies the modal.
  final focus = FocusNode(debugLabel: 'sleep timer return');
  try {
    await showSleepTimer(root.context, returnFocus: focus);
  } finally {
    // The modal asks for focus in a post-frame callback of its own.
    WidgetsBinding.instance.addPostFrameCallback((_) => focus.dispose());
  }
}

/// The two groups of the "More" menu, shared by the mobile sheet and the
/// desktop dropdown: sleep timer, add to playlist, go to album, go to artist
/// | lyrics source, translate, visual effects (Pro), track info. Add to
/// playlist and the two navigation items work now; [beforeNavigate] closes
/// what covers the library first (the picker opens over Now Playing, so it
/// needs no such call). [openSleepTimer] replaces the default way of opening
/// the sleep timer, for a screen that pins its chrome and owns the focus to
/// return to (the desktop menu); without it the modal opens on the root
/// navigator.
List<List<NowPlayingMoreItem>> nowPlayingMoreItems(
  BuildContext context,
  TrackInfo? info, {
  VoidCallback? beforeNavigate,
  VoidCallback? openSleepTimer,
}) {
  final l10n = AppLocalizations.of(context);
  final root = Navigator.of(context, rootNavigator: true);
  return [
    [
      NowPlayingMoreItem(
        label: l10n.playbackSleepTimer,
        icon: KIcons.sleepTimer,
        soon: false,
        liveLabel: sleepTimerMenuLabelBuilder,
        onTap: openSleepTimer ?? () => unawaited(_openSleepTimerOnRoot(root)),
      ),
      NowPlayingMoreItem(
        label: l10n.playbackAddToPlaylist,
        icon: KIcons.playlistAdd,
        soon: false,
        onTap: info == null ? null : () => addCurrentToPlaylist(context, info),
      ),
      NowPlayingMoreItem(
        label: l10n.playbackGoAlbum,
        icon: KIcons.album,
        soon: false,
        onTap: canGoToAlbum(info)
            ? () => goToAlbum(context, info!, beforeNavigate: beforeNavigate)
            : null,
      ),
      NowPlayingMoreItem(
        label: l10n.playbackGoArtist,
        icon: KIcons.artists,
        soon: false,
        onTap: canGoToArtist(info)
            ? () => goToArtist(context, info!, beforeNavigate: beforeNavigate)
            : null,
      ),
    ],
    [
      NowPlayingMoreItem(label: l10n.playbackLyricsSource, icon: KIcons.lyrics),
      NowPlayingMoreItem(
        label: l10n.playbackTranslateLyrics,
        icon: KIcons.language,
      ),
      NowPlayingMoreItem(
        label: l10n.playbackVisualEffects,
        icon: KIcons.image,
        pro: true,
      ),
      NowPlayingMoreItem(label: l10n.playbackTrackInfo, icon: KIcons.info),
    ],
  ];
}
