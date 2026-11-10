import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/library/ui/menus/album_menu.dart';
import 'package:kanaru/src/library/ui/menus/menu_model.dart';
import 'package:kanaru/src/library/ui/menus/menu_origin.dart';
import 'package:kanaru/src/media/domain/play_context.dart';

import 'menu_fixtures.dart';

MenuSpec _menu({
  MenuOrigin origin = const MenuOrigin.list(),
  List<int> folders = const [3],
  bool canReveal = true,
}) {
  final album = albumSummary('Blue', 'Miles', tracks: 3);
  return buildAlbumMenu(
    AlbumMenuData(
      album: album,
      key: albumKeyOf('Blue', 'Miles'),
      ids: trackIds(3),
      folders: [for (final n in folders) folderRef('Dir$n', songs: n)],
    ),
    origin,
    env(canReveal: canReveal),
  );
}

void main() {
  test('rows of an album menu and its queue ids', () {
    final spec = _menu();
    expect(rowIds(spec.groups), [
      MenuItemId.goAlbum,
      MenuItemId.goArtist,
      MenuItemId.goFolder,
      MenuItemId.play,
      MenuItemId.shuffle,
      MenuItemId.playlist,
      MenuItemId.favorite,
      MenuItemId.edit,
      MenuItemId.ai,
      MenuItemId.advanced,
    ]);
    expect(rowIds(spec.advanced), [MenuItemId.hide, MenuItemId.delete]);
    expect(spec.queueIds, trackIds(3));
    expect(spec.header.subtitle, 'Miles · 2000 · 3 songs · 10 min');
    expect(rowOf(spec, MenuItemId.delete).subtitle, '3 files');
    expect(rowOf(spec, MenuItemId.edit).subtitle, '3 songs');
  });

  test('play and shuffle take the album ids with its context', () {
    final spec = _menu();
    final context = PlayContext(
      PlayContextKind.album,
      ref: albumKeyOf('Blue', 'Miles').encode(),
      label: 'Blue',
    );
    expect(
      rowOf(spec, MenuItemId.play).action,
      MenuAction.play(trackIds(3), shuffle: false, context: context),
    );
    expect(
      rowOf(spec, MenuItemId.shuffle).action,
      MenuAction.play(trackIds(3), shuffle: true, context: context),
    );
    expect(
      rowOf(spec, MenuItemId.favorite).action,
      MenuAction.favorite(trackIds(3), on: true),
    );
  });

  test('dimmed set', () {
    final spec = _menu();
    for (final id in [
      MenuItemId.playlist,
      MenuItemId.edit,
      MenuItemId.ai,
      MenuItemId.hide,
      MenuItemId.delete,
    ]) {
      expect(rowOf(spec, id).soon, isTrue, reason: '$id');
    }
  });

  test('own page: no "Go to album", no play, no shuffle', () {
    final spec = _menu(origin: const MenuOrigin.own());
    expect(hasRow(spec, MenuItemId.goAlbum), isFalse);
    expect(hasRow(spec, MenuItemId.play), isFalse);
    expect(hasRow(spec, MenuItemId.shuffle), isFalse);
    expect(hasRow(spec, MenuItemId.goArtist), isTrue);
    expect(
      goLocations(spec),
      isNot(contains(LibraryLocations.album(albumKeyOf('Blue', 'Miles')))),
    );
  });

  test('folders: none, one with reveal button, several as a page', () {
    expect(hasRow(_menu(folders: []), MenuItemId.goFolder), isFalse);
    final one = rowOf(_menu(), MenuItemId.goFolder);
    expect(one.trailing, isNotNull);
    final many = _menu(folders: [2, 1]);
    expect(rowOf(many, MenuItemId.goFolder).subtitle, '3 songs in 2 folders');
    expect(many.pages['folders']!.title, 'Folders · Blue');
    expect(many.pages['folders']!.note, contains('2 folders'));
  });

  test('without a file manager the one-folder row has no reveal button', () {
    expect(
      rowOf(_menu(canReveal: false), MenuItemId.goFolder).trailing,
      isNull,
    );
  });
}
