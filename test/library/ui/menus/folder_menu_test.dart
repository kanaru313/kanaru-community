import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/folders/folder_locations.dart';
import 'package:kanaru/src/library/ui/menus/folder_menu.dart';
import 'package:kanaru/src/library/ui/menus/menu_model.dart';
import 'package:kanaru/src/library/ui/menus/menu_origin.dart';

import 'menu_fixtures.dart';

MenuSpec _menu({
  MenuOrigin origin = const MenuOrigin.list(),
  String key = 'Jazz',
  int subfolders = 2,
  int direct = 3,
  bool flat = false,
  bool canReveal = true,
}) => buildFolderMenu(
  FolderMenuData(
    folder: musicFolder,
    key: key,
    name: key.isEmpty ? 'Music' : key.split('/').last,
    ids: trackIds(flat ? direct : 8),
    directIds: trackIds(direct),
    subfolders: subfolders,
    flat: flat,
  ),
  origin,
  env(canReveal: canReveal),
);

void main() {
  test('tree view with songs and subfolders', () {
    final spec = _menu();
    expect(rowIds(spec.groups), [
      MenuItemId.goFolder,
      MenuItemId.play,
      MenuItemId.shuffle,
      MenuItemId.playDirect,
      MenuItemId.playlist,
      MenuItemId.advanced,
    ]);
    expect(rowOf(spec, MenuItemId.play).subtitle, 'Includes subfolders');
    expect(
      rowOf(spec, MenuItemId.playDirect).subtitle,
      '3 songs, without subfolders',
    );
    expect(rowOf(spec, MenuItemId.playDirect).action, isA<PlayAction>());
    expect(
      (rowOf(spec, MenuItemId.playDirect).action as PlayAction).ids,
      trackIds(3),
    );
    expect(spec.header.subtitle, '8 songs · 2 folders');
    expect(spec.queueIds, trackIds(8));
    expect(rowIds(spec.advanced), [MenuItemId.copyPath, MenuItemId.exclude]);
  });

  test('go row opens the level and has the reveal button', () {
    final row = rowOf(_menu(), MenuItemId.goFolder);
    expect(
      row.action,
      MenuAction.go(
        const FolderLocation(sourceUid: sourceUid, key: 'Jazz').path,
      ),
    );
    expect(row.trailing!.action, const MenuAction.reveal('/home/u/Music/Jazz'));
    expect(row.subtitle, '/home/u/Music/Jazz');
  });

  test('no subfolders: plain Play, no "only this folder"', () {
    final spec = _menu(subfolders: 0);
    expect(rowOf(spec, MenuItemId.play).subtitle, isNull);
    expect(hasRow(spec, MenuItemId.playDirect), isFalse);
  });

  test('flat view counts its own songs only', () {
    final spec = _menu(flat: true, direct: 4);
    expect(hasRow(spec, MenuItemId.playDirect), isFalse);
    expect(rowOf(spec, MenuItemId.play).subtitle, isNull);
    expect(spec.queueIds, trackIds(4));
    expect(spec.header.subtitle, '4 songs');
    expect(
      (rowOf(spec, MenuItemId.goFolder).action as GoAction).location,
      contains('view=flat'),
    );
  });

  test('exclude is real, with a display path, and not on a root', () {
    final row = rowOf(_menu(key: 'Jazz/Blue'), MenuItemId.exclude);
    expect(row.soon, isFalse);
    expect(
      row.action,
      MenuAction.exclude(
        musicFolder,
        'Jazz/Blue',
        displayPath: 'Music/Jazz/Blue',
      ),
    );
    final root = _menu(key: '');
    expect(hasRow(root, MenuItemId.exclude), isFalse);
    expect(
      rowOf(root, MenuItemId.copyPath).action,
      const MenuAction.copy('/home/u/Music'),
    );
  });

  test('own page: reveal replaces "Go to folder"; no play, shuffle', () {
    final spec = _menu(origin: const MenuOrigin.own());
    expect(hasRow(spec, MenuItemId.goFolder), isFalse);
    expect(
      rowOf(spec, MenuItemId.reveal).action,
      const MenuAction.reveal('/home/u/Music/Jazz'),
    );
    expect(hasRow(spec, MenuItemId.play), isFalse);
    expect(hasRow(spec, MenuItemId.shuffle), isFalse);
    expect(hasRow(spec, MenuItemId.playDirect), isTrue);
  });

  test('without a file manager the reveal row is dimmed', () {
    final spec = _menu(origin: const MenuOrigin.own(), canReveal: false);
    expect(rowOf(spec, MenuItemId.reveal).soon, isTrue);
    expect(
      rowOf(_menu(canReveal: false), MenuItemId.goFolder).trailing,
      isNull,
    );
  });
}
