import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/ask_ai_target.dart';
import 'package:kanaru/src/library/domain/browse/browse_items.dart';
import 'package:kanaru/src/library/domain/browse/menu_targets.dart';
import 'package:kanaru/src/library/ui/menus/album_menu.dart';
import 'package:kanaru/src/library/ui/menus/artist_menu.dart';
import 'package:kanaru/src/library/ui/menus/ask_ai_entry.dart';
import 'package:kanaru/src/library/ui/menus/menu_model.dart';
import 'package:kanaru/src/library/ui/menus/menu_origin.dart';
import 'package:kanaru/src/library/ui/menus/selection_menu.dart';
import 'package:kanaru/src/library/ui/menus/song_menu.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';

import 'menu_fixtures.dart';

/// Records what the menus hand to the chat.
class _Entry implements AskAiEntry {
  final asked = <AskAiTarget>[];

  @override
  Future<void> ask(BuildContext context, AskAiTarget target) async =>
      asked.add(target);
}

MenuEnv _env(AskAiEntry? entry) =>
    MenuEnv(l10n: l10n, canReveal: true, pathOf: (_) => null, askAi: entry);

/// Runs the row's action the way the menu does.
Future<void> _tap(WidgetTester tester, MenuItemSpec row) async {
  late BuildContext context;
  await tester.pumpWidget(
    Builder(
      builder: (c) {
        context = c;
        return const SizedBox();
      },
    ),
  );
  final action = row.action;
  expect(action, isA<RunAction>());
  await (action! as RunAction).run(context);
}

MenuSpec _song(MenuEnv env) => buildSongMenu(
  SongMenuData(
    info: trackInfo(id: 7, title: 'So What', artists: ['Miles', 'Coltrane']),
    links: trackLinks(),
    favorite: false,
    selected: false,
  ),
  const MenuOrigin.list(),
  env,
);

MenuSpec _album(MenuEnv env) => buildAlbumMenu(
  AlbumMenuData(
    album: albumSummary('Blue', 'Miles'),
    key: albumKeyOf('Blue', 'Miles'),
    ids: trackIds(3),
    folders: [folderRef('Blue')],
  ),
  const MenuOrigin.list(),
  env,
);

final _artistKey = ArtistKey(groupKey('Vu'));

MenuSpec _artist(MenuEnv env) => buildArtistMenu(
  ArtistMenuData(
    artist: ArtistSummary(
      key: _artistKey.encode(),
      name: 'Vu',
      trackCount: 10,
      albumCount: 2,
      durationMs: 3600000,
      coverKey: null,
    ),
    key: _artistKey,
    albums: ArtistAlbums(own: [albumSummary('Own', 'Vu')], appears: const []),
    ids: trackIds(10),
    folders: [folderRef('A')],
  ),
  const MenuOrigin.list(),
  env,
);

MenuSpec _selection(MenuEnv env) => buildSelectionMenu(
  SelectionMenuData(ids: trackIds(2), durationMs: 360000, allFavorite: false),
  env,
);

void main() {
  test('row is Sắp có when no entry', () {
    for (final build in [_song, _album, _artist, _selection]) {
      final row = rowOf(build(_env(null)), MenuItemId.ai);
      expect(row.soon, isTrue);
      expect(row.action, isNull);
    }
  });

  group('with an entry the row is live and', () {
    testWidgets('a song hands over that song', (tester) async {
      final entry = _Entry();
      final row = rowOf(_song(_env(entry)), MenuItemId.ai);
      expect(row.soon, isFalse);
      await _tap(tester, row);
      final target = entry.asked.single as AskAiSong;
      expect(
        target.track,
        const AskAiTrack(
          id: 7,
          title: 'So What',
          artist: 'Miles, Coltrane',
          album: 'Blue',
        ),
      );
    });

    testWidgets('an album hands over its key and title', (tester) async {
      final entry = _Entry();
      await _tap(tester, rowOf(_album(_env(entry)), MenuItemId.ai));
      expect(entry.asked.single, isA<AskAiAlbum>());
      final target = entry.asked.single as AskAiAlbum;
      expect(target.key, albumKeyOf('Blue', 'Miles').encode());
      expect(target.label, 'Blue');
    });

    testWidgets('an artist hands over its key and name', (tester) async {
      final entry = _Entry();
      await _tap(tester, rowOf(_artist(_env(entry)), MenuItemId.ai));
      final target = entry.asked.single as AskAiArtist;
      expect(target.key, _artistKey.encode());
      expect(target.label, 'Vu');
    });

    testWidgets('a selection hands over every selected song', (tester) async {
      final entry = _Entry();
      await _tap(tester, rowOf(_selection(_env(entry)), MenuItemId.ai));
      final target = entry.asked.single as AskAiSongs;
      expect([for (final t in target.tracks) t.id], [1, 2]);
    });
  });

  test('a huge selection hands over at most the chip limit', () {
    final tracks = askAiTracksOfIds(List.generate(500, (i) => i + 1));
    expect(tracks, hasLength(askAiMaxSongs));
    expect(tracks.first.id, 1);
  });

  test('an empty selection has a dimmed row', () {
    final spec = buildSelectionMenu(
      SelectionMenuData(ids: trackIds(0), durationMs: 0, allFavorite: false),
      _env(_Entry()),
    );
    final row = rowOf(spec, MenuItemId.ai);
    expect(row.enabled, isFalse);
  });
}
