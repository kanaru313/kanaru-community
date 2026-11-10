import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/folders/folder_locations.dart';
import 'package:kanaru/src/library/ui/menus/link_rows.dart';
import 'package:kanaru/src/library/ui/menus/menu_model.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import 'menu_fixtures.dart';

List<LinkTarget> _targets(int n) => [
  for (var i = 1; i <= n; i++) LinkTarget('Name $i', '/x/$i'),
];

LinkRow _row(int n, {bool chipsOnly = false}) => linkRow(
  id: MenuItemId.goArtist,
  icon: KIcons.artists,
  manyIcon: KIcons.artistsMany,
  title: 'Go to artist',
  targets: _targets(n),
  manyText: '$n artists',
  noneText: 'No artist',
  pageKey: 'artists',
  pageTitle: 'Artists · X',
  chipsOnly: chipsOnly,
);

void main() {
  group('linkRow', () {
    test('no target: a dimmed row that says so', () {
      final row = _row(0);
      expect(row.item.enabled, isFalse);
      expect(row.item.active, isFalse);
      expect(row.item.soon, isFalse);
      expect(row.item.subtitle, 'No artist');
      expect(row.item.action, isNull);
      expect(row.page, isNull);
    });

    test('one target: a plain row with its name that goes there', () {
      final row = _row(1);
      expect(row.item.subtitle, 'Name 1');
      expect(row.item.action, const MenuAction.go('/x/1'));
      expect(row.item.chips, isEmpty);
      expect(row.page, isNull);
    });

    test('2 and 3 targets: chips, open', () {
      for (final n in [2, 3]) {
        final row = _row(n);
        expect(row.item.subtitle, '$n artists');
        expect(row.item.chips.map((c) => c.label), [
          for (var i = 1; i <= n; i++) 'Name $i',
        ]);
        expect(row.item.chipsOpen, isTrue, reason: '$n targets');
        expect(row.item.page, isNull);
        expect(row.page, isNull);
      }
    });

    test('4 and 7 targets: a sub-page with a row per target', () {
      for (final n in [4, 7]) {
        final row = _row(n);
        expect(row.item.page, 'artists');
        expect(row.item.chips, isEmpty);
        final page = row.page!;
        expect(page.title, 'Artists · X');
        expect(page.groups.single.map((i) => i.title), [
          for (var i = 1; i <= n; i++) 'Name $i',
        ]);
        expect(page.groups.single.first.action, const MenuAction.go('/x/1'));
      }
    });

    test('chips only: from 4 the chips are folded, never a page', () {
      final row = _row(4, chipsOnly: true);
      expect(row.item.chips, hasLength(4));
      expect(row.item.chipsOpen, isFalse);
      expect(row.item.page, isNull);
      expect(row.page, isNull);
      expect(_row(3, chipsOnly: true).item.chipsOpen, isTrue);
    });

    test('sections give the page a heading per group', () {
      final all = _targets(5);
      final row = linkRow(
        id: MenuItemId.goAlbum,
        icon: KIcons.album,
        title: 'Go to album',
        targets: all,
        manyText: '5',
        noneText: 'none',
        pageKey: 'albums',
        sections: [
          LinkSection(all.sublist(0, 2), title: 'Albums'),
          LinkSection(all.sublist(2), title: 'Appears on'),
        ],
      );
      expect(row.page!.groupTitles, ['Albums', 'Appears on']);
      expect(row.page!.groups.map((g) => g.length), [2, 3]);
    });
  });

  group('folderLinks', () {
    test('no folder: no row', () {
      expect(folderLinks(env(), [], intro: 'i', pageTitle: 't'), isNull);
    });

    test('one folder: its path, goes to the level, reveal button', () {
      final row = folderLinks(
        env(),
        [folderRef('Jazz/Blue')],
        intro: 'i',
        pageTitle: 't',
      )!;
      expect(row.item.subtitle, 'Jazz › Blue');
      expect(
        row.item.action,
        MenuAction.go(
          const FolderLocation(sourceUid: sourceUid, key: 'Jazz/Blue').path,
        ),
      );
      expect(row.item.trailing!.tooltip, 'Show in file manager');
      expect(
        row.item.trailing!.action,
        const MenuAction.reveal('/home/u/Music/Jazz/Blue'),
      );
      expect(row.page, isNull);
    });

    test('one folder where the file manager cannot show it: no button', () {
      final row = folderLinks(
        env(canReveal: false),
        [folderRef('Blue')],
        intro: 'i',
        pageTitle: 't',
      )!;
      expect(row.item.trailing, isNull);
      expect(row.item.action, isA<GoAction>());
    });

    test('several folders: a count line and a page with the intro', () {
      final row = folderLinks(
        env(),
        [folderRef('A', songs: 4), folderRef('B', songs: 2)],
        intro: 'Stored in 2 folders',
        pageTitle: 'Folders · X',
      )!;
      expect(row.item.subtitle, '6 songs in 2 folders');
      expect(row.item.page, 'folders');
      expect(row.page!.note, 'Stored in 2 folders');
      expect(row.page!.title, 'Folders · X');
      expect(row.page!.groups.single.map((i) => i.subtitle), [
        '4 songs',
        '2 songs',
      ]);
      expect(row.page!.groups.single.first.action, isA<GoAction>());
    });
  });

  group('revealRow', () {
    test('works where the file manager can show a path', () {
      final row = revealRow(env(), '/a/b');
      expect(row.active, isTrue);
      expect(row.action, const MenuAction.reveal('/a/b'));
    });

    test('is dimmed with "coming soon" where it cannot', () {
      final row = revealRow(env(canReveal: false), '/a/b');
      expect(row.soon, isTrue);
      expect(row.active, isFalse);
    });

    test('is inert without a path', () {
      final row = revealRow(env(), null);
      expect(row.enabled, isFalse);
      expect(row.action, isNull);
    });
  });
}
