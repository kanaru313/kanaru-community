import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/folder_tree.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/domain/browse/list_view_prefs.dart';
import 'package:kanaru/src/library/domain/music_folder.dart';
import 'package:kanaru/src/library/ui/folders/folder_locations.dart';
import 'package:kanaru/src/library/ui/folders/folder_place.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/platform/domain/storage_volumes.dart';

MusicFolder _folder(int id, String name) => MusicFolder(
  sourceId: id,
  sourceUid: 'uid$id',
  root: '/m/$name',
  volume: otherVolume,
  name: name,
);

List<FolderRoot> _roots(List<MusicFolder> folders, List<FolderRow> rows) =>
    buildFolderTrees(folders, rows);

FolderRow _row(int source, String locator) =>
    (sourceId: source, locator: locator, coverKey: null);

void main() {
  group('FolderLocation', () {
    test('the top has no query', () {
      expect(FolderLocation.top.path, '/library/folders');
      expect(FolderLocation.parse(Uri.parse('/library/folders')).isTop, isTrue);
    });

    test('a level round trips, keys with slashes and non-ASCII included', () {
      for (final key in ['', 'a', 'Lossless/Hi-Res/Bùi Lan Hương']) {
        final location = FolderLocation(sourceUid: 'uid-1', key: key);
        final parsed = FolderLocation.parse(Uri.parse(location.path));
        expect(parsed, location, reason: key);
      }
    });

    test('the flat flag survives', () {
      const location = FolderLocation(sourceUid: 'u', key: 'a', flat: true);
      expect(location.path, contains('view=flat'));
      expect(FolderLocation.parse(Uri.parse(location.path)), location);
      expect(
        FolderLocation.parse(Uri.parse('/library/folders?view=flat')),
        FolderLocation.flatList,
      );
    });

    test('anything malformed is the top', () {
      for (final bad in [
        '/library/folders?at=',
        '/library/folders?at=!!!',
        // base64url of "nouid" (no slash) and of "/x" (empty uid).
        '/library/folders?at=${encodeKey('nouid')}',
        '/library/folders?at=${encodeKey('/x')}',
      ]) {
        expect(FolderLocation.parse(Uri.parse(bad)).isTop, isTrue, reason: bad);
      }
    });

    test('slashes around the key are dropped', () {
      final at = encodeKey('uid//a/b/');
      expect(
        FolderLocation.parse(Uri.parse('/library/folders?at=$at')).key,
        'a/b',
      );
    });
  });

  group('resolveFolderPlace', () {
    final one = [_folder(1, 'Music')];
    final two = [_folder(1, 'Music'), _folder(2, 'Other')];
    final rows = [
      _row(1, 'A/B/C/x.flac'),
      _row(1, 'A/y.flac'),
      _row(2, 'z.flac'),
    ];

    test('one music folder opens straight into it', () {
      final place = resolveFolderPlace(
        _roots(one, rows),
        FolderLocation.top,
        FolderView.tree,
      );
      expect(place, isA<LevelPlace>());
      expect((place as LevelPlace).node.key, '');
      expect(place.parent, isNull);
    });

    test('several music folders list them first', () {
      final place = resolveFolderPlace(
        _roots(two, rows),
        FolderLocation.top,
        FolderView.tree,
      );
      expect(place, isA<RootsPlace>());
    });

    test('a level inside a root climbs through its parents to the top', () {
      final roots = _roots(two, rows);
      final deep = resolveFolderPlace(
        roots,
        const FolderLocation(sourceUid: 'uid1', key: 'A/B/C'),
        FolderView.tree,
        compact: false,
      );
      expect(deep.parent, const FolderLocation(sourceUid: 'uid1', key: 'A/B'));
      // "B" holds no file and only "C": a link of a chain, never a level a
      // row opens, so Back skips it.
      final merged = resolveFolderPlace(
        roots,
        const FolderLocation(sourceUid: 'uid1', key: 'A/B/C'),
        FolderView.tree,
      );
      expect(merged.parent, const FolderLocation(sourceUid: 'uid1', key: 'A'));
      final root = resolveFolderPlace(
        roots,
        const FolderLocation(sourceUid: 'uid1'),
        FolderView.tree,
      );
      expect(root.parent, FolderLocation.top);
    });

    test('a level that is gone opens its nearest ancestor', () {
      final place = resolveFolderPlace(
        _roots(two, rows),
        const FolderLocation(sourceUid: 'uid1', key: 'A/B/Gone/Deeper'),
        FolderView.tree,
      );
      expect((place as LevelPlace).node.key, 'A/B');
    });

    test('an unknown music folder is the top', () {
      final place = resolveFolderPlace(
        _roots(two, rows),
        const FolderLocation(sourceUid: 'nope', key: 'A'),
        FolderView.tree,
      );
      expect(place, isA<RootsPlace>());
    });

    test(
      'the flat view lists folders with songs; a level opened from it is flat',
      () {
        final roots = _roots(two, rows);
        final list = resolveFolderPlace(
          roots,
          FolderLocation.top,
          FolderView.flat,
        );
        expect(list, isA<FlatListPlace>());
        expect((list as FlatListPlace).folders.length, 3);
        final open = resolveFolderPlace(
          roots,
          const FolderLocation(sourceUid: 'uid1', key: 'A', flat: true),
          FolderView.flat,
        );
        expect(open, isA<FlatOpenPlace>());
        expect(open.parent, FolderLocation.flatList);
      },
    );

    test('no music folder, no place', () {
      expect(
        resolveFolderPlace(const [], FolderLocation.top, FolderView.tree),
        isA<NoFoldersPlace>(),
      );
    });
  });

  group('rows', () {
    final roots = _roots(
      [_folder(1, 'Music')],
      [
        _row(1, 'Disc 10/a.flac'),
        _row(1, 'Disc 2/a.flac'),
        _row(1, 'Disc 2/b.flac'),
        _row(1, 'Chain/One/Two/a.flac'),
      ],
    );
    final node = roots.single.node;

    test('natural order, compact chains, sorted by song count', () {
      final byName = levelRows(
        node,
        compact: true,
        sort: const SortSpec(SortCriterion.title),
        filter: '',
      );
      expect(
        [for (final r in byName) r.label],
        ['Chain › One › Two', 'Disc 2', 'Disc 10'],
      );
      expect(byName.first.target.key, 'Chain/One/Two');
      final plain = levelRows(
        node,
        compact: false,
        sort: const SortSpec(SortCriterion.title, descending: true),
        filter: '',
      );
      expect([for (final r in plain) r.label], ['Disc 10', 'Disc 2', 'Chain']);
      final byCount = levelRows(
        node,
        compact: true,
        sort: const SortSpec(SortCriterion.trackCount, descending: true),
        filter: '',
      );
      expect(byCount.first.label, 'Disc 2');
    });

    test('the filter ignores accents and matches the whole chain', () {
      final rows = levelRows(
        node,
        compact: true,
        sort: const SortSpec(SortCriterion.title),
        filter: 'ONE tw',
      );
      expect([for (final r in rows) r.label], ['Chain › One › Two']);
    });
  });
}
