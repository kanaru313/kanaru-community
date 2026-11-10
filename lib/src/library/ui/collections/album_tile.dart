import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/cover_files.dart';
import '../../../media/domain/library_keys.dart';
import '../../../media/domain/play_context.dart';
import '../../../playback/ui/track_cover.dart';
import '../../domain/browse/browse_items.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/song_scope.dart';
import '../browse/library_labels.dart';
import '../browse/library_navigation.dart';
import '../browse/play_actions.dart';
import '../library_locations.dart';

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

/// Album row: cover, title / `artist • year` / `N songs • M min`, ▶ plays the
/// whole album. Gets its summary by value, so it watches nothing.
class AlbumTile extends ConsumerWidget {
  const AlbumTile({super.key, required this.album});

  final AlbumSummary album;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return KMediaCard(
      title: album.title,
      line2: albumByLine(album),
      line3: l10n.libraryAlbumStats(
        album.trackCount,
        minutesOf(album.durationMs),
      ),
      leading: TrackCover(
        coverKey: album.coverKey,
        seed: album.key,
        size: CoverSize.thumb,
        dimension: KMediaCard.coverSize,
        radius: BorderRadius.circular(10),
      ),
      onAction: () => _play(ref, context),
      actionLabel: l10n.libraryPlayAlbum,
      onTap: () => _open(context, album),
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
  const AlbumCard({super.key, required this.album});

  final AlbumSummary album;

  @override
  Widget build(BuildContext context) {
    return KGridCard(
      title: album.title,
      subtitle: albumByLine(album, separator: ' · '),
      onTap: () => _open(context, album),
      coverBuilder: (context, side) => TrackCover(
        coverKey: album.coverKey,
        seed: album.key,
        size: CoverSize.thumb,
        dimension: side,
        radius: BorderRadius.circular(14),
      ),
    );
  }
}
