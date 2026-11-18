import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/playlists/playlist_ids.dart';
import '../../state/custom_cover_providers.dart';
import '../../state/playlists/playlist_page_controller.dart';
import '../detail/detail_header.dart';
import '../detail/detail_tint.dart';
import '../library_locations.dart';
import '../playlist_common/playlist_labels.dart';
import '../../../../l10n/gen/app_localizations.dart';
import 'page/playlist_hero.dart';
import 'page/playlist_page_states.dart';
import 'page/playlist_songs_slivers.dart';

/// One playlist, or Favorites (uid `favorites`): the frame with the cover
/// tint, the hero (a left column on a wide page) and the songs.
///
/// Favorites is also a sidebar item: on desktop its header stays a root
/// header (no back button) in every state; on mobile every playlist page is
/// a child of the tab and has one.
class PlaylistPage extends ConsumerWidget {
  const PlaylistPage({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorites = uid == PlaylistUids.favorites;
    final showBack =
        !(isFavorites && FormFactor.of(context) == FormFactor.desktop);
    final async = ref.watch(playlistPageProvider(uid).select((s) => s.detail));
    final detail = async.value;
    if (detail == null) {
      return async.hasValue
          ? PlaylistNotFound(showBack: showBack)
          : PlaylistPending(showBack: showBack, failed: async.hasError);
    }
    final summary = detail.summary;
    final tint = isFavorites
        ? null
        : watchDetailTint(ref, (
            kind: CustomCoverKind.playlist,
            itemKey: uid,
          ), summary.autoCoverKeys.firstOrNull);
    return DetailFrame(
      title: playlistDisplayName(AppLocalizations.of(context), summary),
      fallback: LibraryLocations.playlists,
      tint: tint,
      showBack: showBack,
      child: PlaylistSongsHost(
        detail: detail,
        builder: (context, slivers, serving, play) => KDetailLayout(
          header: PlaylistHero(detail: detail, serving: serving, onPlay: play),
          slivers: slivers,
        ),
      ),
    );
  }
}
