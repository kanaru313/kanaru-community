import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/menus/menu_model.dart';
import 'package:kanaru/src/library/ui/menus/menu_origin.dart';
import 'package:kanaru/src/library/ui/menus/song_menu.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru_ui/kanaru_ui.dart' show KIcons;

import 'menu_fixtures.dart';

MenuSpec _base() => buildSongMenu(
  SongMenuData(
    info: trackInfo(),
    links: trackLinks(),
    favorite: false,
    selected: false,
    openLyrics: (_) async {},
  ),
  const MenuOrigin.list(),
  env(),
);

MenuItemSpec _row(MenuItemId id) =>
    MenuItemSpec(id, icon: KIcons.lyrics, title: id.name);

List<List<MenuItemId>> _ids(MenuSpec s) => [
  for (final g in s.groups) [for (final i in g) i.id],
];

void main() {
  test('defaults return the spec as it is', () {
    final spec = _base();
    expect(identical(withSongPageRows(spec), spec), isTrue);
  });

  test('rows go before and after the lyrics row, in its group', () {
    final spec = withSongPageRows(
      _base(),
      aroundLyrics: (
        before: [_row(MenuItemId.sleepTimer)],
        after: [_row(MenuItemId.translate), _row(MenuItemId.visualEffects)],
      ),
    );
    expect(_ids(spec)[1], [
      MenuItemId.sleepTimer,
      MenuItemId.lyrics,
      MenuItemId.translate,
      MenuItemId.visualEffects,
    ]);
    expect(_ids(spec)[0], isNot(contains(MenuItemId.lyrics)));
    expect(_ids(spec)[2], contains(MenuItemId.playlist));
  });

  test('without a lyrics row the rows form a group right after Go to', () {
    final base = _base();
    final spec = withSongPageRows(
      base.copyWith(
        groups: [
          for (final g in base.groups)
            [
              for (final i in g)
                if (i.id != MenuItemId.lyrics) i,
            ],
        ],
      ),
      aroundLyrics: (
        before: [_row(MenuItemId.sleepTimer)],
        after: [_row(MenuItemId.translate)],
      ),
    );
    expect(_ids(spec)[1], [MenuItemId.sleepTimer, MenuItemId.translate]);
    expect(_ids(spec)[0], contains(MenuItemId.goArtist));
  });

  test('selectRow false drops only the Select row', () {
    final spec = withSongPageRows(_base(), selectRow: false);
    final ids = _ids(spec).expand((g) => g);
    expect(ids, isNot(contains(MenuItemId.select)));
    expect(ids, containsAll([MenuItemId.favorite, MenuItemId.edit]));
  });

  test('queueButtons false empties the queue ids, true keeps them', () {
    expect(_base().queueIds, [TrackId(1)]);
    expect(withSongPageRows(_base(), queueButtons: false).queueIds, isEmpty);
    expect(withSongPageRows(_base(), favoriteRow: false).queueIds, [
      TrackId(1),
    ]);
  });

  test('all hooks together give the order of the Now Playing menu', () {
    final spec = withSongPageRows(
      _base(),
      selectRow: false,
      queueButtons: false,
      aroundLyrics: (
        before: [_row(MenuItemId.sleepTimer)],
        after: [_row(MenuItemId.translate), _row(MenuItemId.visualEffects)],
      ),
    );
    expect(_ids(spec).take(3).map((g) => g.first), [
      MenuItemId.goAlbum,
      MenuItemId.sleepTimer,
      MenuItemId.playlist,
    ]);
    expect(_ids(spec).expand((g) => g), isNot(contains(MenuItemId.select)));
    expect(spec.queueIds, isEmpty);
  });

  test('leadingGroup is the first group, before Go to', () {
    final spec = withSongPageRows(
      _base(),
      leadingGroup: [_row(MenuItemId.playThis), _row(MenuItemId.playNext)],
    );
    expect(_ids(spec).first, [MenuItemId.playThis, MenuItemId.playNext]);
    expect(_ids(spec)[1], contains(MenuItemId.goArtist));
    expect(_ids(spec).length, _ids(_base()).length + 1);
  });

  test('selectReplacement takes the Select row place, keeping its group', () {
    final replacement = _row(MenuItemId.select);
    final spec = withSongPageRows(_base(), selectReplacement: replacement);
    final all = spec.groups.expand((g) => g).toList();
    expect(all.where((i) => i.id == MenuItemId.select), [replacement]);
    expect(_ids(spec), _ids(_base()));
  });

  test('selectRow false wins over selectReplacement', () {
    final spec = withSongPageRows(
      _base(),
      selectRow: false,
      selectReplacement: _row(MenuItemId.select),
    );
    expect(_ids(spec).expand((g) => g), isNot(contains(MenuItemId.select)));
  });

  test('beforeAdvanced is a group right before the Advanced group', () {
    final spec = withSongPageRows(
      _base(),
      beforeAdvanced: [_row(MenuItemId.removeFromQueue)],
    );
    final ids = _ids(spec);
    expect(ids[ids.length - 2], [MenuItemId.removeFromQueue]);
    expect(ids.last, [MenuItemId.advanced]);
  });

  test('beforeAdvanced goes last when the menu has no Advanced group', () {
    final base = _base();
    final spec = withSongPageRows(
      base.copyWith(
        groups: [
          for (final g in base.groups)
            [
              for (final i in g)
                if (i.id != MenuItemId.advanced) i,
            ],
        ],
      ),
      beforeAdvanced: [_row(MenuItemId.removeFromQueue)],
    );
    expect(_ids(spec).last, [MenuItemId.removeFromQueue]);
  });

  test('all queue-row hooks together give the queue row menu order', () {
    final spec = withSongPageRows(
      _base(),
      queueButtons: false,
      leadingGroup: [_row(MenuItemId.playThis), _row(MenuItemId.playNext)],
      selectReplacement: _row(MenuItemId.select),
      beforeAdvanced: [_row(MenuItemId.removeFromQueue)],
    );
    final ids = _ids(spec);
    expect(ids.first.first, MenuItemId.playThis);
    expect(ids[1].first, MenuItemId.goAlbum);
    expect(ids[ids.length - 2], [MenuItemId.removeFromQueue]);
    expect(ids.last, [MenuItemId.advanced]);
    expect(spec.queueIds, isEmpty);
  });
}
