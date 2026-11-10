import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/track_info.dart';
import 'track_navigation.dart';

/// One entry of the "More" menu of Now Playing.
class NowPlayingMoreItem {
  const NowPlayingMoreItem({
    required this.label,
    required this.icon,
    this.onTap,
    this.pro = false,
    this.soon = true,
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
}

/// The two groups of the "More" menu, shared by the mobile sheet and the
/// desktop dropdown: sleep timer, add to playlist, go to album, go to artist
/// | lyrics source, translate, visual effects (Pro), track info. Only the
/// two navigation items work now; [beforeNavigate] closes what covers the
/// library first.
List<List<NowPlayingMoreItem>> nowPlayingMoreItems(
  BuildContext context,
  TrackInfo? info, {
  VoidCallback? beforeNavigate,
}) {
  final l10n = AppLocalizations.of(context);
  return [
    [
      NowPlayingMoreItem(
        label: l10n.playbackSleepTimer,
        icon: KIcons.sleepTimer,
      ),
      NowPlayingMoreItem(
        label: l10n.playbackAddToPlaylist,
        icon: KIcons.playlistAdd,
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
