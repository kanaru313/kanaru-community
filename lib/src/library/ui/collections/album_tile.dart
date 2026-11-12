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

/// `artist • year` (list) or `artist · year` (grid): whichever parts exist.
String albumByLine(AlbumSummary album, {String separator = ' • '}) => [
  if (album.artist != null && album.artist!.isNotEmpty) album.artist!,
  if (album.year != null) '${album.year}',
].join(separator);

final _log = Logger('library.album_tile');

void _open(BuildContext context, AlbumSummary album) {
  final key = AlbumKey.decode(album.key);
  if (key == null) {
    _log.warning('undecodable album key: ${album.key}');
    return;
  }
  openLibraryPage(context, LibraryLocations.album(key));
}

void _menu(
  BuildContext context,
  AlbumSummary album,
  MenuOrigin origin, {
  bool viaKeyboard = false,
}) {
  final key = AlbumKey.decode(album.key);
  if (key == null) {
    _log.warning('undecodable album key: ${album.key}');
    return;
  }
  openAlbumMenu(context, key, origin: origin, viaKeyboard: viaKeyboard);
}

/// Album row: cover, title / `artist • year` / `N songs • M min`, ▶ plays the
/// whole album. Gets its summary by value, so it watches nothing.
class AlbumTile extends ConsumerWidget {
  const AlbumTile({
    super.key,
    required this.album,
    this.origin = const MenuOrigin.list(),
  });

  final AlbumSummary album;

  /// The page the tile is on, so its menu never links back to it.
  final MenuOrigin origin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return KContextRegion(
      onOpen: (at) => _menu(context, album, origin, viaKeyboard: at == null),
      child: KMediaCard(
        title: album.title,
        line2: albumByLine(album),
        line3: l10n.libraryAlbumStats(
          album.trackCount,
          minutesOf(album.durationMs),
        ),
        leading: AlbumCover(
          itemKey: album.key,
          coverKey: album.coverKey,
          dimension: KMediaCard.coverSize,
          radius: KMediaCard.coverRadius,
        ),
        onAction: () => _play(ref, context),
        actionLabel: l10n.libraryPlayAlbum,
        trailing: LibraryMoreButton(
          onPressed: ({required viaKeyboard}) =>
              _menu(context, album, origin, viaKeyboard: viaKeyboard),
        ),
        onTap: () => _open(context, album),
      ),
    );
  }

  Future<void> _play(WidgetRef ref, BuildContext context) async {
    final key = AlbumKey.decode(album.key);
    if (key == null) {
      _log.warning('undecodable album key: ${album.key}');
      return;
    }
    await playScope(
      ref,
      context,
      SongScope.album(key),
      BrowseList.albumTracks,
      PlayContext(PlayContextKind.album, ref: album.key, label: album.title),
    );
  }
}

/// Album tile of the grid: square cover, title, `artist · year`.
class AlbumCard extends StatelessWidget {
  const AlbumCard({
    super.key,
    required this.album,
    this.origin = const MenuOrigin.list(),
  });

  final AlbumSummary album;

  /// The page the card is on, so its menu never links back to it.
  final MenuOrigin origin;

  @override
  Widget build(BuildContext context) {
    return KContextRegion(
      onOpen: (at) => _menu(context, album, origin, viaKeyboard: at == null),
      child: KGridCard(
        title: album.title,
        subtitle: albumByLine(album, separator: ' · '),
        onTap: () => _open(context, album),
        more: LibraryMoreButton(
          onPressed: ({required viaKeyboard}) =>
              _menu(context, album, origin, viaKeyboard: viaKeyboard),
        ),
        coverBuilder: (context, side) => AlbumCover(
          itemKey: album.key,
          coverKey: album.coverKey,
          dimension: side,
          radius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
