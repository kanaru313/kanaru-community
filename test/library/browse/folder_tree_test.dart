import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/folder_tree.dart';
import 'package:kanaru/src/library/domain/music_folder.dart';
import 'package:kanaru/src/platform/domain/storage_volumes.dart';

MusicFolder folder(int id, String name) => MusicFolder(
  sourceId: id,
  sourceUid: 'uid$id',
  root: '/music/$name$id',
  volume: const StorageVolume(root: '/', kind: StorageVolumeKind.home),
  name: name,
);

FolderRow row(String locator, {int source = 1, String? cover}) =>
    (sourceId: source, locator: locator, coverKey: cover);

FolderRoot single(List<FolderRow> rows) =>
    buildFolderTrees([folder(1, 'Music')], rows).single;

void main() {
  test('counts: direct, deep, subfolders; root is key empty', () {
    final root = single([
      row('x.flac'),
      row('a/1.flac'),
      row('a/2.flac'),
      row('a/b/3.flac'),
    ]).node;
    expect(root.key, '');
    expect(root.name, 'Music');
    expect((root.directSongs, root.deepSongs, root.subfolders), (1, 4, 1));
    final a = root.children.single;
    expect((a.key, a.name, a.directSongs, a.deepSongs), ('a', 'a', 2, 3));
    expect(a.children.single.key, 'a/b');
  });

  test('rows of other sources are ignored; empty root is empty', () {
    final roots = buildFolderTrees(
      [folder(1, 'Music'), folder(2, 'Empty')],
      [row('a/1.flac'), row('b/2.flac', source: 3)],
    );
    expect(roots[0].node.deepSongs, 1);
    expect(roots[1].node.deepSongs, 0);
    expect(roots[1].node.children, isEmpty);
    expect(flatFolders([roots[1]]), isEmpty);
  });

  test('two roots with the same name are both ambiguous', () {
    final roots = buildFolderTrees([
      folder(1, 'Music'),
      folder(2, 'Music'),
      folder(3, 'Other'),
    ], const []);
    expect(roots.map((r) => r.ambiguous), [true, true, false]);
  });

  test('children are in natural order', () {
    final root = single([
      row('Disc 10/1.flac'),
      row('Disc 2/1.flac'),
      row('disc 1/1.flac'),
    ]).node;
    expect(root.children.map((c) => c.name), ['disc 1', 'Disc 2', 'Disc 10']);
  });

  group('compact chain', () {
    test('merges folders with no files and one subfolder, 6 levels', () {
      final root = single([
        row('Lossless/Hi-Res/24bit/96k/Album/Disc 1/1.flac'),
      ]).node;
      final chain = compactChain(root.children.single);
      expect(chain.map((n) => n.name), [
        'Lossless',
        'Hi-Res',
        '24bit',
        '96k',
        'Album',
        'Disc 1',
      ]);
      expect(chain.last.directSongs, 1);
    });

    test('stops at files and at a fork', () {
      final root = single([
        row('a/1.flac'),
        row('a/b/2.flac'),
        row('c/d/1.flac'),
        row('c/d/e/1.flac'),
        row('c/d/f/1.flac'),
        row('g/h/1.flac'),
      ]).node;
      List<String> chain(String key) =>
          compactChain(root.children.firstWhere((c) => c.key == key))
              .map((n) => n.name)
              .toList();
      expect(chain('a'), ['a']);
      expect(chain('c'), ['c', 'd']);
      expect(chain('g'), ['g', 'h']);
    });
  });

  group('cover', () {
    test('direct: the cover of most direct files, ties to the smaller key', () {
      final a = single([
        row('a/1.flac', cover: 'c2'),
        row('a/2.flac', cover: 'c2'),
        row('a/3.flac', cover: 'c1'),
        row('a/4.flac'),
        row('b/1.flac', cover: 'z'),
        row('b/2.flac', cover: 'y'),
      ]).node;
      expect(a.children[0].directCoverKey, 'c2');
      expect(a.children[0].coverKey, 'c2');
      expect(a.children[1].directCoverKey, 'y');
    });

    test('inherited: the subfolder with most files that has a cover', () {
      final root = single([
        row('A/1.flac', cover: 'x'),
        row('A/2.flac', cover: 'x'),
        row('B/1.flac', cover: 'y'),
        row('B/2.flac', cover: 'y'),
        row('B/3.flac', cover: 'y'),
        // The biggest subfolder has no cover: it is skipped.
        row('C/1.flac'),
        row('C/2.flac'),
        row('C/3.flac'),
        row('C/4.flac'),
      ]).node;
      expect(root.directCoverKey, isNull);
      expect(root.coverKey, 'y');
    });

    test('inherited tie goes to the first in natural order', () {
      final root = single([
        row('B/1.flac', cover: 'y'),
        row('A/1.flac', cover: 'x'),
      ]).node;
      expect(root.coverKey, 'x');
    });

    test('inherits through levels and stays null without covers', () {
      final root = single([row('a/b/1.flac', cover: 'deep')]).node;
      expect(root.coverKey, 'deep');
      expect(single([row('a/1.flac')]).node.coverKey, isNull);
    });
  });

  test('nodeAt finds any level, missing keys give null', () {
    final root = single([row('a/b/1.flac')]);
    expect(root.nodeAt('')!.name, 'Music');
    expect(root.nodeAt('a/b')!.name, 'b');
    expect(root.nodeAt('a/c'), isNull);
    expect(nodeAt([root], 1, 'a')!.key, 'a');
    expect(nodeAt([root], 2, 'a'), isNull);
  });

  test('flat view: folders with direct files, label = ancestors', () {
    final root = single([
      row('top.flac'),
      row('Lossless/1.flac'),
      row('Lossless/Hi-Res/2.flac'),
      row('Lossless/Hi-Res/3.flac'),
      row('only/dirs/x/1.flac'),
    ]);
    final flat = flatFolders([root]);
    expect(
      [
        for (final f in flat)
          '${f.name}|${f.ancestors.join('/')}|${f.songCount}',
      ],
      [
        'Music||1',
        'Lossless|Music|1',
        'Hi-Res|Music/Lossless|2',
        'x|Music/only/dirs|1',
      ],
    );
  });
}
