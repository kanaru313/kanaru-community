import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/browse/group_play.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/library/ui/menus/group_menu.dart';
import 'package:kanaru/src/library/ui/menus/menu_model.dart';
import 'package:kanaru/src/library/ui/menus/menu_origin.dart';

import 'menu_fixtures.dart';

MenuSpec _menu(
  GroupMenuKind kind, {
  MenuOrigin origin = const MenuOrigin.list(),
  String? key = 'indie',
  int albums = 7,
  int detected = 0,
}) => buildGroupMenu(
  GroupMenuData(
    kind: kind,
    key: key,
    name: kind == GroupMenuKind.genre ? 'Indie' : 'Vietnamese',
    ids: trackIds(5),
    albums: [for (var i = 0; i < albums; i++) albumSummary('A$i', 'X')],
    folders: [folderRef('One')],
    durationMs: 600000,
    detected: detected,
  ),
  origin,
  env(),
);

void main() {
  test('genre rows: links, play block with split or merge, no advanced', () {
    final spec = _menu(GroupMenuKind.genre);
    expect(rowIds(spec.groups), [
      MenuItemId.goGenre,
      MenuItemId.goAlbum,
      MenuItemId.goFolder,
      MenuItemId.play,
      MenuItemId.shuffle,
      MenuItemId.playlist,
      MenuItemId.favorite,
      MenuItemId.split,
    ]);
    expect(rowOf(spec, MenuItemId.split).soon, isTrue);
    expect(spec.advanced, isEmpty);
    expect(spec.header.subtitle, '7 albums · 5 songs · 10 min');
    expect(spec.queueIds, trackIds(5));
  });

  test('7 albums: a page; 2 albums: chips', () {
    final spec = _menu(GroupMenuKind.genre);
    expect(rowOf(spec, MenuItemId.goAlbum).page, 'albums');
    expect(spec.pages['albums']!.title, 'Albums · Indie');
    expect(spec.pages['albums']!.groups.single, hasLength(7));
    final few = _menu(GroupMenuKind.genre, albums: 2);
    expect(rowOf(few, MenuItemId.goAlbum).chips, hasLength(2));
  });

  test('language rows end with the dimmed detection settings row', () {
    final spec = _menu(GroupMenuKind.language, key: 'vie', detected: 2);
    expect(rowIds(spec.groups), [
      MenuItemId.goLanguage,
      MenuItemId.goAlbum,
      MenuItemId.goFolder,
      MenuItemId.play,
      MenuItemId.shuffle,
      MenuItemId.playlist,
      MenuItemId.favorite,
      MenuItemId.languageSettings,
    ]);
    expect(rowOf(spec, MenuItemId.languageSettings).soon, isTrue);
    expect(spec.header.subtitle, '5 songs · 2 auto-detected');
  });

  test('own page hides the kind link, play and shuffle', () {
    for (final kind in GroupMenuKind.values) {
      final spec = _menu(kind, origin: const MenuOrigin.own(), key: 'k');
      expect(hasRow(spec, MenuItemId.goGenre), isFalse);
      expect(hasRow(spec, MenuItemId.goLanguage), isFalse);
      expect(hasRow(spec, MenuItemId.play), isFalse);
      expect(hasRow(spec, MenuItemId.shuffle), isFalse);
      expect(
        goLocations(spec),
        isNot(
          contains(
            kind == GroupMenuKind.genre
                ? LibraryLocations.genre('k')
                : LibraryLocations.language('k'),
          ),
        ),
      );
    }
  });

  test('the language without a code still links to its page', () {
    final spec = _menu(GroupMenuKind.language, key: null);
    expect(
      rowOf(spec, MenuItemId.goLanguage).action,
      MenuAction.go(LibraryLocations.language(null)),
    );
  });

  test('Play carries the play context of the page, `_unknown` for no code', () {
    final unknown = _menu(GroupMenuKind.language, key: null);
    expect(
      rowOf(unknown, MenuItemId.play).action,
      MenuAction.play(
        trackIds(5),
        shuffle: false,
        context: languagePlayContext(null, 'Vietnamese'),
      ),
    );
    final play = rowOf(unknown, MenuItemId.play).action as PlayAction;
    expect(play.context.ref, '_unknown');
    expect(play.context.kind, PlayContextKind.language);
    final genre = rowOf(_menu(GroupMenuKind.genre), MenuItemId.play).action;
    expect((genre as PlayAction).context, genrePlayContext('indie', 'Indie'));
  });
}
