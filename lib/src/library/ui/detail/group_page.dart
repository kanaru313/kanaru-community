import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/library_keys.dart';
import '../../../media/domain/play_context.dart';
import '../../domain/browse/detail_data.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/song_scope.dart';
import '../../domain/library_tabs.dart';
import '../../state/browse/detail_providers.dart';
import '../browse/library_labels.dart';
import '../browse/library_list_scaffold.dart';
import '../browse/library_navigation.dart';
import '../library_locations.dart';
import '../menus/menu_origin.dart';
import '../menus/open_menu.dart';
import 'detail_header.dart';
import 'detail_songs.dart';
import 'see_all_page.dart';

/// Which kind of group a page or see-all grid shows.
enum GroupKind { genre, language }

/// A genre or language named by a location: its song scope and, for a
/// genre, the stored key. A language [code] of null is the "unknown" group.
class GroupTarget {
  const GroupTarget._(this.kind, this.id, this.scope, this.genreKey, this.code);

  final GroupKind kind;

  /// The id as it appears in the location.
  final String id;
  final SongScope scope;
  final String? genreKey;
  final String? code;

  /// Reads [id] of a location; null when it is not a valid id.
  static GroupTarget? parse(GroupKind kind, String id) {
    if (kind == GroupKind.language && id == '_unknown') {
      return GroupTarget._(
        kind,
        id,
        const SongScope.language(null),
        null,
        null,
      );
    }
    final decoded = decodeKey(id);
    if (decoded == null || decoded.isEmpty) return null;
    return kind == GroupKind.genre
        ? GroupTarget._(kind, id, SongScope.genre(decoded), decoded, null)
        : GroupTarget._(kind, id, SongScope.language(decoded), null, decoded);
  }

  PlayContextKind get playKind => kind == GroupKind.genre
      ? PlayContextKind.genre
      : PlayContextKind.language;

  LibraryTab get tab =>
      kind == GroupKind.genre ? LibraryTab.genres : LibraryTab.languages;

  String get fallback => LibraryLocations.list(tab);
}

/// Name of a group (the genre as stored, the language in its names), loading
/// while the genre list is; data null = not found.
AsyncValue<String?> groupName(
  WidgetRef ref,
  AppLocalizations l10n,
  GroupTarget target,
) {
  if (target.kind == GroupKind.language) {
    return AsyncData(languageDisplayName(l10n, target.code));
  }
  return ref.watch(genreNameProvider(target.genreKey!));
}

/// Genre or language page: a colour banner (big song count, artists and
/// length, buttons), the artist and album shelves when they have two items or
/// more, then every song. A language page explains the "auto-detected" tag.
class GroupPage extends ConsumerWidget {
  const GroupPage({super.key, required this.kind, required this.id});

  final GroupKind kind;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = GroupTarget.parse(kind, id);
    final fallback = LibraryLocations.list(
      kind == GroupKind.genre ? LibraryTab.genres : LibraryTab.languages,
    );
    if (target == null) return DetailNotFound(fallback: fallback);
    final l10n = AppLocalizations.of(context);
    final name = groupName(ref, l10n, target);
    final totals = ref.watch(groupTotalsProvider(target.scope));
    final title = name.value;
    final stats = totals.value;
    if (title == null || stats == null) {
      return (name.hasValue && title == null) ||
              (totals.hasValue && stats?.tracks == 0)
          ? DetailNotFound(fallback: fallback)
          : DetailPending(
              fallback: fallback,
              failed: name.hasError || totals.hasError,
            );
    }
    if (stats.tracks == 0) return DetailNotFound(fallback: fallback);
    final shelves = ref.watch(groupShelvesProvider(target.scope)).value;
    final playContext = PlayContext(target.playKind, ref: id, label: title);
    final language = kind == GroupKind.language;
    return DetailFrame(
      title: title,
      fallback: fallback,
      child: DetailSongsHost(
        list: BrowseList.detailSongs,
        item: '${kind.name}:$id',
        scope: target.scope,
        playContext: playContext,
        durationMs: stats.durationMs,
        showDetected: language,
        builder: (context, songs) => CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: libraryGutter(context),
                vertical: KSpace.x2,
              ),
              sliver: SliverToBoxAdapter(
                child: KColorBanner(
                  seed: title,
                  icon: language
                      ? (target.code == null ? KIcons.help : KIcons.languages)
                      : KIcons.genres,
                  headline: l10n.librarySongCount(stats.tracks),
                  caption: _caption(l10n, stats, language),
                  actions: DetailActions(
                    scope: target.scope,
                    list: BrowseList.detailSongs,
                    item: '${kind.name}:$id',
                    playContext: playContext,
                    onMenu: (c) => language
                        ? openLanguageMenu(
                            c,
                            target.code,
                            origin: const MenuOrigin.own(),
                          )
                        : openGenreMenu(
                            c,
                            genreKey: target.genreKey!,
                            name: title,
                            origin: const MenuOrigin.own(),
                          ),
                  ),
                ),
              ),
            ),
            if (language && (target.code == null || stats.detected > 0))
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  libraryGutter(context),
                  0,
                  libraryGutter(context),
                  KSpace.x3,
                ),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    target.code == null
                        ? l10n.libraryLanguageUnknownNote
                        : l10n.libraryLanguageDetectedNote,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ..._shelves(context, l10n, target, shelves),
            ...songs,
          ],
        ),
      ),
    );
  }

  String _caption(AppLocalizations l10n, GroupTotals stats, bool language) => [
    l10n.libraryArtistCount(stats.artists),
    formatTotalDuration(l10n, stats.durationMs),
    if (language && stats.detected > 0)
      l10n.libraryDetectedCount(stats.detected),
  ].join(' · ');

  List<Widget> _shelves(
    BuildContext context,
    AppLocalizations l10n,
    GroupTarget target,
    GroupShelves? shelves,
  ) {
    if (shelves == null) return const [];
    final cap = shelfCap(context);
    return [
      if (shelves.artists.length >= 2)
        SliverToBoxAdapter(
          child: ArtistShelf(
            title: l10n.libraryTabArtists,
            artists: shelves.artists.take(cap).toList(),
            onSeeAll: () =>
                openLibraryPage(context, SeeAllLocations.groupArtists(target)),
          ),
        ),
      if (shelves.albums.length >= 2)
        SliverToBoxAdapter(
          child: AlbumShelf(
            title: l10n.libraryTabAlbums,
            albums: shelves.albums.take(cap).toList(),
            onSeeAll: () =>
                openLibraryPage(context, SeeAllLocations.groupAlbums(target)),
          ),
        ),
    ];
  }
}
