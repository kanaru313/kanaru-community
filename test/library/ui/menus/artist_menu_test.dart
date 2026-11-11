import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/browse_items.dart';
import 'package:kanaru/src/library/domain/browse/menu_targets.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/library/ui/menus/artist_menu.dart';
import 'package:kanaru/src/library/ui/menus/menu_model.dart';
import 'package:kanaru/src/library/ui/menus/menu_origin.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';

import 'menu_fixtures.dart';

final _key = ArtistKey(groupKey('Vu'));

MenuSpec _menu({
  MenuOrigin origin = const MenuOrigin.list(),
  int own = 2,
  int appears = 1,
}) => buildArtistMenu(
  ArtistMenuData(
    artist: const ArtistSummary(
      key: 'k',
      name: 'Vu',
      trackCount: 10,
      albumCount: 2,
      durationMs: 3600000,
      coverKey: null,
    ),
    key: _key,
    albums: ArtistAlbums(
      own: [for (var i = 0; i < own; i++) albumSummary('Own $i', 'Vu')],
      appears: [
        for (var i = 0; i < appears; i++) albumSummary('Guest $i', 'Other'),
      ],
    ),
    ids: trackIds(10),
    folders: [folderRef('A'), folderRef('B')],
  ),
  origin,
  env(),
);

void main() {
  test('rows and header', () {
    final spec = _menu();
    expect(rowIds(spec.groups), [
      MenuItemId.goArtist,
      MenuItemId.goAlbum,
      MenuItemId.goFolder,
      MenuItemId.play,
      MenuItemId.shuffle,
      MenuItemId.playlist,
      MenuItemId.favorite,
      MenuItemId.ai,
      MenuItemId.advanced,
    ]);
    expect(rowIds(spec.advanced), [
      MenuItemId.split,
      MenuItemId.hide,
      MenuItemId.delete,
    ]);
    expect(spec.header.subtitle, '2 albums · 10 songs · 1 h');
    expect(rowOf(spec, MenuItemId.split).soon, isTrue);
  });

  test('3 albums: chips, own first, then the ones the artist appears on', () {
    final row = rowOf(_menu(), MenuItemId.goAlbum);
    expect(row.chips.map((c) => c.label), ['Own 0', 'Own 1', 'Guest 0']);
    expect(row.chipsOpen, isTrue);
    expect(row.subtitle, '2 albums · appears on 1');
  });

  test('4 or more albums: a page with two headed groups', () {
    final spec = _menu(own: 2, appears: 2);
    expect(rowOf(spec, MenuItemId.goAlbum).page, 'albums');
    final page = spec.pages['albums']!;
    expect(page.title, 'Albums · Vu');
    expect(page.groupTitles, ['Albums', 'Appears on']);
    expect(page.groups.map((g) => g.length), [2, 2]);
    // Each row shows its album's cover.
    expect(page.groups.expand((g) => g).every((i) => i.cover != null), isTrue);
  });

  test('no albums: dimmed row', () {
    final row = rowOf(_menu(own: 0, appears: 0), MenuItemId.goAlbum);
    expect(row.enabled, isFalse);
    expect(row.subtitle, 'No album');
  });

  test(
    'own page hides the artist link and play, and links to no self page',
    () {
      final spec = _menu(origin: const MenuOrigin.own());
      expect(hasRow(spec, MenuItemId.goArtist), isFalse);
      expect(hasRow(spec, MenuItemId.play), isFalse);
      expect(hasRow(spec, MenuItemId.shuffle), isFalse);
      expect(goLocations(spec), isNot(contains(LibraryLocations.artist(_key))));
    },
  );

  test('several folders open a page', () {
    expect(_menu().pages['folders']!.groups.single, hasLength(2));
  });
}
