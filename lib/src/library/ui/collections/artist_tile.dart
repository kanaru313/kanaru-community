import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/library_keys.dart';
import '../../../media/domain/play_context.dart';
import '../../domain/browse/browse_items.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/song_scope.dart';
import '../browse/item_covers.dart';
import '../browse/library_labels.dart';
import '../browse/library_navigation.dart';
import '../browse/play_actions.dart';
import '../library_locations.dart';
import '../menus/menu_origin.dart';
import '../menus/more_button.dart';
import '../menus/open_menu.dart';

final _log = Logger('library.artist_tile');

void _open(BuildContext context, ArtistSummary artist) {
  final key = ArtistKey.decode(artist.key);
  if (key == null) {
    _log.warning('undecodable artist key: ${artist.key}');
    return;
  }
  openLibraryPage(context, LibraryLocations.artist(key));
}

void _menu(
  BuildContext context,
  ArtistSummary artist,
  MenuOrigin origin, {
  bool viaKeyboard = false,
}) {
  final key = ArtistKey.decode(artist.key);
  if (key == null) {
    _log.warning('undecodable artist key: ${artist.key}');
    return;
  }
  openArtistMenu(context, key, origin: origin, viaKeyboard: viaKeyboard);
}

/// Artist row: round photo, name / `N albums` / `M songs • length`, ▶ plays
/// every song of the artist. The photo is the cover of the artist's newest
/// album that has one (the summary carries it), else a letter placeholder.
class ArtistTile extends ConsumerWidget {
  const ArtistTile({
    super.key,
    required this.artist,
    this.origin = const MenuOrigin.list(),
  });

  final ArtistSummary artist;

  /// The page the tile is on, so its menu never links back to it.
  final MenuOrigin origin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return KContextRegion(
      onOpen: (at) => _menu(context, artist, origin, viaKeyboard: at == null),
      child: KMediaCard(
        title: artist.name,
        line2: l10n.libraryAlbumCount(artist.albumCount),
        line3:
            '${l10n.librarySongCount(artist.trackCount)} • '
            '${formatTotalDuration(l10n, artist.durationMs)}',
        leading: ArtistCover(
          itemKey: artist.key,
          name: artist.name,
          coverKey: artist.coverKey,
          dimension: KMediaCard.coverSize,
        ),
        circleLeading: true,
        onAction: () => _play(ref, context),
        actionLabel: l10n.libraryPlayArtist,
        trailing: LibraryMoreButton(
          onPressed: ({required viaKeyboard}) =>
              _menu(context, artist, origin, viaKeyboard: viaKeyboard),
        ),
        onTap: () => _open(context, artist),
      ),
    );
  }

  Future<void> _play(WidgetRef ref, BuildContext context) async {
    final key = ArtistKey.decode(artist.key);
    if (key == null) {
      _log.warning('undecodable artist key: ${artist.key}');
      return;
    }
    await playScope(
      ref,
      context,
      SongScope.artist(key),
      BrowseList.detailSongs,
      PlayContext(PlayContextKind.artist, ref: artist.key, label: artist.name),
    );
  }
}

/// Artist tile of the grid: round photo, name, `N songs`.
class ArtistCard extends StatelessWidget {
  const ArtistCard({
    super.key,
    required this.artist,
    this.origin = const MenuOrigin.list(),
  });

  final ArtistSummary artist;

  /// The page the card is on, so its menu never links back to it.
  final MenuOrigin origin;

  @override
  Widget build(BuildContext context) {
    return KContextRegion(
      onOpen: (at) => _menu(context, artist, origin, viaKeyboard: at == null),
      child: KGridCard(
        circle: true,
        title: artist.name,
        subtitle: AppLocalizations.of(context)
            .librarySongCount(artist.trackCount),
        onTap: () => _open(context, artist),
        more: LibraryMoreButton(
          onPressed: ({required viaKeyboard}) =>
              _menu(context, artist, origin, viaKeyboard: viaKeyboard),
        ),
        coverBuilder: (context, side) => ArtistCover(
          itemKey: artist.key,
          name: artist.name,
          coverKey: artist.coverKey,
          dimension: side,
        ),
      ),
    );
  }
}
