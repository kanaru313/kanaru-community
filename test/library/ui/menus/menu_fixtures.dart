import 'package:kanaru/l10n/gen/app_localizations_en.dart';
import 'package:kanaru/src/library/domain/browse/browse_items.dart';
import 'package:kanaru/src/library/domain/browse/menu_targets.dart';
import 'package:kanaru/src/library/domain/music_folder.dart';
import 'package:kanaru/src/library/ui/menus/menu_model.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru/src/platform/domain/storage_volumes.dart';

final l10n = AppLocalizationsEn();

String? Function(FolderRef) _paths = (f) => '/home/u/Music/${f.folderKey}';

MenuEnv env({bool canReveal = true, bool trash = false}) =>
    MenuEnv(l10n: l10n, canReveal: canReveal, pathOf: _paths, trash: trash);

const sourceUid = 'uid-music';

final musicFolder = MusicFolder(
  sourceId: 1,
  sourceUid: sourceUid,
  root: '/home/u/Music',
  volume: const StorageVolume(root: '/home/u', kind: StorageVolumeKind.home),
  name: 'Music',
);

FolderRef folderRef(String key, {int songs = 3}) => FolderRef(
  sourceId: 1,
  sourceUid: sourceUid,
  folderKey: key,
  name: key.isEmpty ? 'Music' : key.split('/').last,
  songCount: songs,
);

ArtistRef artistRef(String name) => ArtistRef(ArtistKey(groupKey(name)), name);

AlbumKey albumKeyOf(String album, String artist) =>
    albumKeyFor(album: album, albumArtist: artist, artists: [artist])!;

AlbumSummary albumSummary(
  String title,
  String artist, {
  int year = 2000,
  int tracks = 3,
}) => AlbumSummary(
  key: albumKeyOf(title, artist).encode(),
  title: title,
  artist: artist,
  year: year,
  trackCount: tracks,
  durationMs: 600000,
  coverKey: null,
  addedAt: 1,
);

TrackInfo trackInfo({
  int id = 1,
  String title = 'So What',
  List<String> artists = const ['Miles'],
  String? album = 'Blue',
  AlbumKey? albumKey,
}) => TrackInfo(
  id: TrackId(id),
  title: title,
  status: TrackAvailability.present,
  relPath: 'Blue/1.flac',
  artists: artists,
  album: album,
  albumKey: albumKey ?? (album == null ? null : albumKeyOf(album, 'Miles')),
  durationMs: 180000,
);

TrackLinks trackLinks({
  List<String> artists = const ['Miles'],
  List<String> albumArtists = const [],
  String? album = 'Blue',
  String folder = 'Blue',
}) => TrackLinks(
  albumKey: album == null ? null : albumKeyOf(album, 'Miles'),
  albumTitle: album,
  artists: [for (final a in artists) artistRef(a)],
  albumArtists: [for (final a in albumArtists) artistRef(a)],
  folder: folderRef(folder, songs: 5),
);

const songFile = SongInfo(
  format: 'FLAC',
  bitrate: 900,
  sampleRate: 44100,
  bitDepth: 16,
  sizeBytes: 30000000,
  path: '/home/u/Music/Blue/1.flac',
  playCount: 4,
);

List<TrackId> trackIds(int count) => [
  for (var i = 1; i <= count; i++) TrackId(i),
];

/// Ids of the rows of every group, in order.
List<MenuItemId> rowIds(List<List<MenuItemSpec>> groups) => [
  for (final g in groups)
    for (final i in g) i.id,
];

MenuItemSpec rowOf(MenuSpec spec, MenuItemId id) => [
  ...spec.groups.expand((g) => g),
  ...spec.advanced.expand((g) => g),
].firstWhere((i) => i.id == id, orElse: () => throw StateError('no $id'));

bool hasRow(MenuSpec spec, MenuItemId id) => [
  ...spec.groups.expand((g) => g),
  ...spec.advanced.expand((g) => g),
].any((i) => i.id == id);

/// Every location a menu can open: rows, chips, trailing buttons, and the
/// rows of its sub-pages.
Set<String> goLocations(MenuSpec spec) {
  final out = <String>{};
  void row(MenuItemSpec i) {
    final a = i.action;
    if (a is GoAction) out.add(a.location);
    for (final c in i.chips) {
      final ca = c.action;
      if (ca is GoAction) out.add(ca.location);
    }
    final t = i.trailing?.action;
    if (t is GoAction) out.add(t.location);
  }

  for (final g in [...spec.groups, ...spec.advanced]) {
    g.forEach(row);
  }
  for (final p in spec.pages.values) {
    for (final g in p.groups) {
      g.forEach(row);
    }
  }
  return out;
}
