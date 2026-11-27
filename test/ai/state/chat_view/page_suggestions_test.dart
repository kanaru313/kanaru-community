import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations_en.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/state/chat_view/page_suggestions.dart';
import 'package:kanaru/src/library/domain/ask_ai_target.dart';
import 'package:kanaru/src/library/domain/browse/browse_items.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/state/browse/detail_providers.dart';
import 'package:kanaru/src/library/state/playlists/playlist_providers.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';

final _l10n = AppLocalizationsEn();
final _album = albumKeyFor(
  album: 'Blue',
  albumArtist: 'Miles',
  artists: ['Miles'],
)!;

AlbumSummary _summary() => AlbumSummary(
  key: _album.encode(),
  title: 'Blue',
  artist: 'Miles',
  year: 1959,
  trackCount: 4,
  durationMs: 600000,
  coverKey: null,
  addedAt: 1,
);

ProviderContainer _container({bool playing = true}) {
  final container = ProviderContainer(
    overrides: [
      hasCurrentTrackProvider.overrideWithValue(playing),
      albumDetailProvider.overrideWith((ref, key) => Stream.value(_summary())),
      playlistDetailProvider.overrideWith(
        (ref, uid) => Stream.value(
          PlaylistDetail(
            summary: PlaylistSummary(
              id: 7,
              uid: uid,
              name: 'Road',
              description: '',
              isFavorites: false,
              trackCount: 0,
              durationMs: 0,
              createdAt: 1,
              updatedAt: 1,
              autoCoverKeys: const [],
            ),
            entries: const [],
          ),
        ),
      ),
      genreNameProvider.overrideWith(
        (ref, key) => const AsyncData<String?>('Jazz'),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Lets the album stream publish, then reads the suggestions.
Future<List<ChipPart>> _suggestions(ProviderContainer container) async {
  final keep = container.listen(chatSuggestionsProvider(_l10n), (_, _) {});
  addTearDown(keep.close);
  // Held open: the autoDispose album stream is dropped while loading when
  // nothing (a root page) listens to it.
  final album = container.listen(albumDetailProvider(_album), (_, _) {});
  addTearDown(album.close);
  await container.read(albumDetailProvider(_album).future);
  return container.read(chatSuggestionsProvider(_l10n));
}

void main() {
  test('album detail suggests album chip', () async {
    final container = _container();
    container
        .read(chatPageLocationProvider.notifier)
        .set(LibraryLocations.album(_album));

    final chips = await _suggestions(container);

    expect(
      [for (final c in chips) c.kind],
      [ChipKind.nowPlaying, ChipKind.album],
    );
    expect(chips.last.ref, _album.encode());
    expect(chips.last.label, 'Blue');
  });

  test('root page suggests now playing only', () async {
    final container = _container();
    container
        .read(chatPageLocationProvider.notifier)
        .set(LibraryLocations.root);

    final chips = await _suggestions(container);

    expect([for (final c in chips) c.kind], [ChipKind.nowPlaying]);
  });

  test('nothing playing and no page suggests nothing', () async {
    final container = _container(playing: false);
    expect(await _suggestions(container), isEmpty);
  });

  test('playlist page suggests its playlist chip', () async {
    final container = _container(playing: false);
    container
        .read(chatPageLocationProvider.notifier)
        .set(LibraryLocations.playlist('uid-1'));
    final keep = container.listen(chatSuggestionsProvider(_l10n), (_, _) {});
    addTearDown(keep.close);
    final detail = container.listen(playlistDetailProvider('uid-1'), (_, _) {});
    addTearDown(detail.close);
    await container.read(playlistDetailProvider('uid-1').future);
    final chip = container.read(chatSuggestionsProvider(_l10n)).single;
    expect(chip.kind, ChipKind.playlist);
    expect(chip.ref, 'uid-1');
    expect(chip.label, 'Road');
  });

  test('genre and language pages suggest their chip', () async {
    final container = _container(playing: false);
    final location = container.read(chatPageLocationProvider.notifier);

    location.set(LibraryLocations.genre('jazz'));
    var chips = await _suggestions(container);
    expect(chips.single.kind, ChipKind.genre);
    expect(chips.single.ref, 'jazz');
    expect(chips.single.label, 'Jazz');

    location.set(LibraryLocations.language('vi'));
    chips = container.read(chatSuggestionsProvider(_l10n));
    expect(chips.single.kind, ChipKind.language);
    expect(chips.single.ref, 'vi');
  });

  test('a page the chat has no chip for adds nothing', () async {
    final container = _container(playing: false);
    container
        .read(chatPageLocationProvider.notifier)
        .set('${LibraryLocations.playlists}/queues/abc');
    expect(await _suggestions(container), isEmpty);
  });

  test('the selection is offered as N songs', () async {
    final container = ProviderContainer(
      overrides: [
        hasCurrentTrackProvider.overrideWithValue(false),
        selectionTracksProvider.overrideWithValue(const [
          AskAiTrack(id: 1, title: ''),
          AskAiTrack(id: 2, title: ''),
        ]),
      ],
    );
    addTearDown(container.dispose);
    final keep = container.listen(chatSuggestionsProvider(_l10n), (_, _) {});
    addTearDown(keep.close);

    final chips = container.read(chatSuggestionsProvider(_l10n));

    expect(chips.single.kind, ChipKind.songs);
    expect(chips.single.tracks, hasLength(2));
  });

  test('a cut selection still states its real count', () async {
    final ids = [
      for (var i = 1; i <= askAiMaxSongs; i++) AskAiTrack(id: i, title: ''),
    ];
    final container = ProviderContainer(
      overrides: [
        hasCurrentTrackProvider.overrideWithValue(false),
        selectionTracksProvider.overrideWithValue(ids),
        selectionCountProvider.overrideWithValue(250),
      ],
    );
    addTearDown(container.dispose);
    final keep = container.listen(chatSuggestionsProvider(_l10n), (_, _) {});
    addTearDown(keep.close);

    final chip = container.read(chatSuggestionsProvider(_l10n)).single;

    expect(chip.kind, ChipKind.songs);
    expect(chip.label, '250');
    expect(chip.tracks, hasLength(askAiMaxSongs));
  });
}
