import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/data/media_store/media_index_targets.dart';

void main() {
  const internal = '/storage/emulated/0';
  Future<List<String>> targets({
    required Map<String, List<String>> tree,
    List<String> roots = const [internal],
    List<String> folders = const [],
  }) => mediaIndexTargets(
    volumeRoots: roots,
    folders: folders,
    listChildDirs: (dir) async => tree[dir] ?? const [],
  );

  test(
    'skips Android, dot and junk folders; Music and Download come first',
    () async {
      final result = await targets(
        tree: {
          internal: [
            '$internal/Zebra',
            '$internal/Android',
            '$internal/.thumbnails',
            '$internal/lost+found',
            '$internal/download',
            '$internal/Alpha',
            '$internal/music',
          ],
        },
      );
      expect(result, [
        '$internal/music',
        '$internal/download',
        '$internal/Alpha',
        '$internal/Zebra',
      ]);
    },
  );

  test(
    'Music and Download of every volume come before other folders',
    () async {
      final result = await targets(
        tree: {
          internal: ['$internal/DCIM', '$internal/Music'],
          '/storage/1234-ABCD': [
            '/storage/1234-ABCD/Backup',
            '/storage/1234-ABCD/Download',
          ],
        },
        roots: [internal, '/storage/1234-ABCD'],
      );
      expect(result, [
        '$internal/Music',
        '/storage/1234-ABCD/Download',
        '/storage/1234-ABCD/Backup',
        '$internal/DCIM',
      ]);
    },
  );

  test('a chosen folder inside a target is dropped', () async {
    final result = await targets(
      tree: {
        internal: ['$internal/Music'],
      },
      folders: ['$internal/Music/Rock'],
    );
    expect(result, ['$internal/Music']);
  });

  test('a chosen folder outside every volume is kept', () async {
    final result = await targets(
      tree: {
        internal: ['$internal/Music'],
      },
      folders: ['/mnt/media_rw/X/Songs'],
    );
    expect(result, ['$internal/Music', '/mnt/media_rw/X/Songs']);
  });

  test('a chosen folder that holds other targets replaces them', () async {
    final result = await targets(
      tree: {
        internal: ['$internal/Music'],
      },
      folders: [internal],
    );
    expect(result, [internal]);
  });

  test('a volume that cannot be listed adds nothing', () async {
    final result = await targets(
      tree: {
        '/storage/1234-ABCD': ['/storage/1234-ABCD/Music'],
      },
      roots: ['/storage/gone', '/storage/1234-ABCD'],
    );
    expect(result, ['/storage/1234-ABCD/Music']);
  });
}
