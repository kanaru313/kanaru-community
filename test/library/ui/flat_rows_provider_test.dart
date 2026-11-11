import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/folder_tree.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/domain/browse/list_view_prefs.dart';
import 'package:kanaru/src/library/domain/music_folder.dart';
import 'package:kanaru/src/library/state/browse/folder_providers.dart';
import 'package:kanaru/src/library/ui/folders/folder_locations.dart';
import 'package:kanaru/src/library/ui/folders/folder_place.dart';
import 'package:kanaru/src/platform/domain/storage_volumes.dart';

final _music = MusicFolder(
  sourceId: 1,
  sourceUid: 'uid1',
  root: '/m/Music',
  volume: otherVolume,
  name: 'Music',
);

List<FolderRoot> _roots(int folders) => buildFolderTrees(
  [_music],
  [
    for (var i = 0; i < folders; i++)
      (sourceId: 1, locator: 'Folder $i/a.flac', coverKey: null),
  ],
);

ProviderContainer _container(List<FolderRoot> roots) {
  final c = ProviderContainer(
    overrides: [folderTreesProvider.overrideWith((ref) => Stream.value(roots))],
  );
  addTearDown(c.dispose);
  return c;
}

const _place = (
  location: FolderLocation.flatList,
  view: FolderView.flat,
  compact: true,
);

FlatRowsKey _key({String filter = '', bool desc = false}) => (
  place: _place,
  sort: SortSpec(SortCriterion.title, descending: desc),
  filter: filter,
);

Future<void> _treesLoaded(ProviderContainer c) async {
  final sub = c.listen(folderTreesProvider, (_, _) {});
  while (!sub.read().hasValue) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<List<FlatFolder>> _rows(ProviderContainer c, FlatRowsKey key) async {
  final sub = c.listen(flatRowsProvider(key), (_, _) {});
  await _treesLoaded(c);
  return sub.read()!;
}

void main() {
  test(
    'rows are filtered and in natural order; the count is their length',
    () async {
      {
        final c = _container(_roots(30));
        final all = await _rows(c, _key());
        expect(all, hasLength(30));
        expect(all.first.name, 'Folder 0');
        expect(all[3].name, 'Folder 3');
        expect(all.last.name, 'Folder 29');
        final some = await _rows(c, _key(filter: 'folder 2'));
        // Words match anywhere: Folder 2, 12 and 20..29.
        expect(some, hasLength(12));
        final desc = await _rows(c, _key(desc: true));
        expect(desc.first.name, 'Folder 29');
      }
    },
  );

  test(
    'the same key is computed once; a rebuild reads the same list',
    () async {
      final c = _container(_roots(50));
      final first = await _rows(c, _key());
      final again = c.listen(flatRowsProvider(_key()), (_, _) {}).read();
      expect(identical(first, again), isTrue);
    },
  );

  test('18 000 folders sort in well under a second of UI time', () async {
    final c = _container(_roots(18000));
    final watch = Stopwatch()..start();
    final rows = await _rows(c, _key());
    watch.stop();
    expect(rows, hasLength(18000));
    expect(rows[10].name, 'Folder 10');
    expect(watch.elapsedMilliseconds, lessThan(1000));
  });

  test('the place is not the flat list: no rows', () async {
    final c = _container(_roots(3));
    const key = (
      place: (
        location: FolderLocation(sourceUid: 'uid1', key: ''),
        view: FolderView.tree,
        compact: true,
      ),
      sort: SortSpec(SortCriterion.title),
      filter: '',
    );
    c.listen(flatRowsProvider(key), (_, _) {});
    await _treesLoaded(c);
    expect(c.read(flatRowsProvider(key)), isNull);
  });
}
