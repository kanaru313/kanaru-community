import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/browse_items.dart';
import 'package:kanaru/src/library/domain/browse/menu_targets.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/state/browse/custom_cover_index_providers.dart';
import 'package:kanaru/src/library/state/browse/detail_providers.dart';
import 'package:kanaru/src/library/state/covers/cover_dialog_options.dart';
import 'package:kanaru/src/library/state/custom_cover_providers.dart';
import 'package:kanaru/src/library/state/playlists/playlist_providers.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';
import 'package:kanaru/src/platform/state/platform_providers.dart';

import 'cover_test_support.dart';

class _Paths implements AppPaths {
  _Paths(this.cacheDir);
  @override
  final Directory cacheDir;
  @override
  Directory get dataDir => cacheDir;
  @override
  Directory get configDir => cacheDir;
}

AlbumSummary _album(String name, String? cover, {int? year}) => AlbumSummary(
  key: AlbumKey('artist', name).encode(),
  title: name,
  artist: 'artist',
  year: year,
  trackCount: 1,
  durationMs: 1,
  coverKey: cover,
  addedAt: 0,
);

String _albumKey(String name) => AlbumKey('artist', name).encode();

void main() {
  late Directory cache;
  setUp(() => cache = Directory.systemTemp.createTempSync('kanaru_opts_'));
  tearDown(() => cache.deleteSync(recursive: true));

  final artist = ArtistKey('artist');
  CustomCoverItem item(CustomCoverKind k, String key) =>
      (kind: k, itemKey: key);

  /// [custom]: per album key, the custom cover `full` file it has.
  Future<CoverDialogOptions> load(
    CustomCoverItem it,
    List<Override> extra, {
    Map<String, File> custom = const {},
    File? own,
    File? ownThumb,
  }) async {
    final container = ProviderContainer(
      overrides: [
        appPathsProvider.overrideWithValue(_Paths(cache)),
        customCoverIndexProvider.overrideWith(
          (ref, kind) => Stream.value({...custom.keys}),
        ),
        customCoverFileProvider.overrideWith((ref, i) {
          if (i.kind == CustomCoverKind.album) {
            return Stream.value(custom[i.itemKey]);
          }
          return Stream.value(own);
        }),
        customCoverThumbProvider.overrideWith(
          (ref, i) =>
              Stream.value(i.kind == CustomCoverKind.album ? null : ownThumb),
        ),
        ...extra,
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(coverDialogOptionsProvider(it), (_, _) {});
    final value = await container.read(coverDialogOptionsProvider(it).future);
    sub.close();
    return value;
  }

  List<Override> artistData(ArtistAlbums albums) => [
    artistDetailProvider.overrideWith(
      (ref, k) => Stream.value(
        ArtistSummary(
          key: k.encode(),
          name: 'Artist',
          trackCount: 1,
          albumCount: 1,
          durationMs: 1,
          coverKey: coverKeyOf(1),
        ),
      ),
    ),
    artistAlbumsProvider.overrideWith((ref, k) => Stream.value(albums)),
  ];

  test(
    'artist: own albums first, then appears-in, with a cover, max 4',
    () async {
      final opts = await load(
        item(CustomCoverKind.artist, artist.encode()),
        artistData(
          ArtistAlbums(
            own: [
              _album('o1', coverKeyOf(1), year: 2000),
              _album('nocover', null),
              _album('o2', coverKeyOf(2)),
            ],
            appears: [
              _album('a1', coverKeyOf(3)),
              _album('o1', coverKeyOf(1)), // repeated
              _album('a2', coverKeyOf(4)),
              _album('a3', coverKeyOf(5)),
            ],
          ),
        ),
      );
      expect(opts.itemName, 'Artist');
      expect(opts.automaticCoverKeys, [coverKeyOf(1)]);
      expect(opts.suggestions.map((s) => s.title), ['o1', 'o2', 'a1', 'a2']);
      expect(opts.suggestions.first.year, 2000);
      expect(opts.suggestions.length, artistSuggestionLimit);
      expect(opts.current, isNull);
    },
  );

  test(
    'playlist: every distinct album in order, no-album tracks skipped',
    () async {
      final tracks = [
        track(100), // no album
        for (var i = 0; i < 8; i++)
          track(i, album: 'alb$i', cover: coverKeyOf(i + 1)),
        track(50, album: 'alb0', cover: coverKeyOf(1)), // repeated
      ];
      final opts = await load(item(CustomCoverKind.playlist, 'pl1'), [
        // Each album's own cover is its track's cover here.
        albumDetailProvider.overrideWith(
          (ref, k) => Stream.value(
            _album(
              k.titleKey,
              coverKeyOf(int.parse(k.titleKey.substring(3)) + 1),
            ),
          ),
        ),
        playlistDetailProvider.overrideWith(
          (ref, uid) => Stream.value(
            PlaylistDetail(
              summary: PlaylistSummary(
                uid: uid,
                name: 'Mix',
                description: '',
                isFavorites: false,
                trackCount: 9,
                durationMs: 1,
                createdAt: 0,
                updatedAt: 0,
                autoCoverKeys: [coverKeyOf(1), coverKeyOf(2)],
              ),
              entries: [
                for (final t in tracks)
                  PlaylistEntryView(uid: 'e${t.id.value}', info: t),
              ],
            ),
          ),
        ),
      ]);
      expect(opts.itemName, 'Mix');
      expect(opts.automaticCoverKeys, [coverKeyOf(1), coverKeyOf(2)]);
      expect(opts.suggestions.map((s) => s.title), [
        for (var i = 0; i < 8; i++) 'alb$i',
      ]);
    },
  );

  test(
    'playlist: album reads run at most coverResolveConcurrency at once',
    () async {
      var inFlight = 0;
      var peak = 0;
      final tracks = [
        for (var i = 0; i < 40; i++)
          track(i, album: 'alb$i', cover: coverKeyOf(i + 1)),
      ];
      final opts = await load(item(CustomCoverKind.playlist, 'pl1'), [
        albumDetailProvider.overrideWith((ref, k) async* {
          inFlight++;
          if (inFlight > peak) peak = inFlight;
          await Future<void>.delayed(const Duration(milliseconds: 5));
          inFlight--;
          yield _album(
            k.titleKey,
            coverKeyOf(int.parse(k.titleKey.substring(3)) + 1),
          );
        }),
        playlistDetailProvider.overrideWith(
          (ref, uid) => Stream.value(
            PlaylistDetail(
              summary: PlaylistSummary(
                uid: uid,
                name: 'Mix',
                description: '',
                isFavorites: false,
                trackCount: 40,
                durationMs: 1,
                createdAt: 0,
                updatedAt: 0,
                autoCoverKeys: const [],
              ),
              entries: [
                for (final t in tracks)
                  PlaylistEntryView(uid: 'e${t.id.value}', info: t),
              ],
            ),
          ),
        ),
      ]);
      expect(peak, inInclusiveRange(2, coverResolveConcurrency));
      expect(opts.suggestions.map((s) => s.title), [
        for (var i = 0; i < 40; i++) 'alb$i',
      ]);
    },
  );

  test(
    'album: no suggestions, a custom cover without its thumb is not current',
    () async {
      final key = AlbumKey('artist', 'x');
      final full = File('${cache.path}/own-full.jpg');
      final opts = await load(item(CustomCoverKind.album, key.encode()), [
        albumDetailProvider.overrideWith(
          (ref, k) => Stream.value(_album('x', coverKeyOf(7))),
        ),
      ], own: full);
      expect(opts.suggestions, isEmpty);
      expect(opts.automaticCoverKeys, [coverKeyOf(7)]);
      expect(opts.itemName, 'x');
      // The thumb stream has no file: no half-known "current".
      expect(opts.current, isNull);
    },
  );

  test('a custom cover with both of its files is the current one', () async {
    final full = File('${cache.path}/own-full.jpg');
    final thumb = File('${cache.path}/own-thumb.jpg');
    final opts = await load(
      item(CustomCoverKind.artist, ArtistKey('artist').encode()),
      artistData(ArtistAlbums(own: const [], appears: const [])),
      own: full,
      ownThumb: thumb,
    );
    expect(opts.current!.full.path, full.path);
    expect(opts.current!.thumb.path, thumb.path);
  });

  test(
    'playlist: a suggestion shows the album cover, not its track cover',
    () async {
      final customKey = coverKeyOf(0xCD);
      final custom = File('${cache.path}/covers/full/$customKey.jpg');
      final opts = await load(
        item(CustomCoverKind.playlist, 'pl1'),
        [
          albumDetailProvider.overrideWith(
            (ref, k) => Stream.value(_album(k.titleKey, coverKeyOf(90))),
          ),
          playlistDetailProvider.overrideWith(
            (ref, uid) => Stream.value(
              PlaylistDetail(
                summary: PlaylistSummary(
                  uid: uid,
                  name: 'Mix',
                  description: '',
                  isFavorites: false,
                  trackCount: 2,
                  durationMs: 1,
                  createdAt: 0,
                  updatedAt: 0,
                  autoCoverKeys: const [],
                ),
                entries: [
                  // The track carries other art than its album.
                  PlaylistEntryView(
                    uid: 'e1',
                    info: track(1, album: 'plain', cover: coverKeyOf(5)),
                  ),
                  PlaylistEntryView(
                    uid: 'e2',
                    info: track(2, album: 'custom', cover: coverKeyOf(6)),
                  ),
                ],
              ),
            ),
          ),
        ],
        custom: {_albumKey('custom'): custom},
      );
      final byTitle = {for (final s in opts.suggestions) s.title: s};
      expect(
        byTitle['plain']!.full.path,
        '${cache.path}/covers/full/${coverKeyOf(90)}.jpg',
      );
      expect(byTitle['custom']!.full.path, custom.path);
    },
  );

  test(
    'a suggestion uses the album custom cover file before its song cover',
    () async {
      final customKey = coverKeyOf(0xAB);
      final full = File('${cache.path}/covers/full/$customKey.jpg');
      final opts = await load(
        item(CustomCoverKind.artist, artist.encode()),
        artistData(
          ArtistAlbums(
            own: [
              _album('custom', coverKeyOf(1)),
              _album('plain', coverKeyOf(2)),
            ],
            appears: const [],
          ),
        ),
        custom: {_albumKey('custom'): full},
      );
      final byTitle = {for (final s in opts.suggestions) s.title: s};
      expect(byTitle['custom']!.full.path, full.path);
      expect(
        byTitle['custom']!.thumb.path,
        '${cache.path}/covers/thumb/$customKey.jpg',
      );
      expect(
        byTitle['plain']!.full.path,
        '${cache.path}/covers/full/${coverKeyOf(2)}.jpg',
      );
    },
  );
}
