import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../media/domain/library_keys.dart';
import '../../../platform/state/platform_providers.dart';
import '../../domain/covers/album_cover_candidates.dart';
import '../../domain/covers/cover_file_paths.dart';
import '../../domain/playlists/playlist_models.dart';
import '../browse/detail_providers.dart';
import '../custom_cover_providers.dart';
import '../playlists/playlist_providers.dart';
import '../shown_cover_provider.dart';
import 'cover_dialog_models.dart';
import 'cover_options_waiters.dart';

export 'cover_dialog_models.dart';

/// Options of the cover dialog of one item. A snapshot: later scan or cover
/// changes do not move rows under the user's finger.
final coverDialogOptionsProvider = FutureProvider.autoDispose
    .family<CoverDialogOptions, CustomCoverItem>(_load);

/// [coverKey] is the album's own cover (the automatic one under a custom
/// cover); null when it has none.
typedef _Candidate = ({String key, String title, int? year, String? coverKey});

Future<CoverDialogOptions> _load(Ref ref, CustomCoverItem item) async {
  final String name;
  final List<String> auto;
  final List<_Candidate> candidates;
  switch (item.kind) {
    case CustomCoverKind.album:
      final key = AlbumKey.decode(item.itemKey);
      if (key == null) throw ArgumentError.value(item.itemKey, 'itemKey');
      final album = await firstAsync(ref, albumDetailProvider(key));
      name = album?.title ?? '';
      auto = [?album?.coverKey];
      candidates = const [];
    case CustomCoverKind.artist:
      final key = ArtistKey.decode(item.itemKey);
      if (key == null) throw ArgumentError.value(item.itemKey, 'itemKey');
      final artist = await firstAsync(ref, artistDetailProvider(key));
      final albums = await firstAsync(ref, artistAlbumsProvider(key));
      name = artist?.name ?? '';
      auto = [?artist?.coverKey];
      final seen = <String>{};
      candidates = [
        for (final a in [...albums.own, ...albums.appears])
          if (a.coverKey != null && seen.add(a.key))
            (key: a.key, title: a.title, year: a.year, coverKey: a.coverKey),
      ].take(artistSuggestionLimit).toList();
    case CustomCoverKind.playlist:
      final detail = await firstAsync(
        ref,
        playlistDetailProvider(item.itemKey),
      );
      name = detail?.summary.name ?? '';
      auto = detail?.summary.autoCoverKeys ?? const [];
      // The track's cover only picks the albums; each suggestion shows the
      // album's own cover, like the album's tile does.
      candidates = await Future.wait([
        for (final c in albumCoverCandidates([
          for (final e in detail?.entries ?? const <PlaylistEntryView>[])
            e.info,
        ], playlistSuggestionLimit))
          _albumCandidate(ref, c),
      ]);
  }

  final cache = ref.read(appPathsProvider).cacheDir.path;
  final suggestions = await Future.wait([
    for (final c in candidates) _suggestion(ref, cache, c),
  ]);
  final full = await firstAsync(ref, customCoverFileProvider(item));
  final thumb = await firstAsync(ref, customCoverThumbProvider(item));
  return CoverDialogOptions(
    itemName: name,
    automaticCoverKeys: auto,
    current: full == null || thumb == null ? null : (thumb: thumb, full: full),
    suggestions: suggestions.whereType<CoverSuggestion>().toList(),
  );
}

Future<_Candidate> _albumCandidate(Ref ref, AlbumCoverCandidate c) async {
  final album = await firstAsync(ref, albumDetailProvider(c.key));
  return (
    key: c.key.encode(),
    title: c.title,
    year: c.year,
    // An album that cannot be read keeps the track's cover.
    coverKey: album == null ? c.coverKey : album.coverKey,
  );
}

/// The suggestion of [c]: its shown cover (custom first, else the song
/// cover). Null when the album shows none.
Future<CoverSuggestion?> _suggestion(
  Ref ref,
  String cache,
  _Candidate c,
) async {
  final shown = await firstSettled(
    ref,
    shownCoverProvider((
      item: (kind: CustomCoverKind.album, itemKey: c.key),
      automaticCoverKey: c.coverKey,
    )),
  );
  final File? full;
  final File? thumb;
  switch (shown) {
    case ShownCustomCover(:final coverKey, file: final f):
      full = f;
      thumb = thumbBesideFull(coverKey, f) ?? f;
    case ShownAutomaticCover(:final coverKey) when coverKey != null:
      full = songCoverFull(cache, coverKey);
      thumb = songCoverThumb(cache, coverKey);
    default:
      return null;
  }
  return CoverSuggestion(
    albumKey: c.key,
    title: c.title,
    year: c.year,
    thumb: thumb,
    full: full,
  );
}
