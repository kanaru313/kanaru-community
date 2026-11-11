import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/l10n/gen/app_localizations_en.dart';
import 'package:kanaru/src/library/domain/browse/folder_tree.dart';
import 'package:kanaru/src/library/domain/browse/list_view_prefs.dart';
import 'package:kanaru/src/library/domain/music_folder.dart';
import 'package:kanaru/src/library/ui/folders/folder_breadcrumb.dart';
import 'package:kanaru/src/library/ui/folders/folder_locations.dart';
import 'package:kanaru/src/library/ui/folders/folder_place.dart';
import 'package:kanaru/src/platform/domain/storage_volumes.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

final _l10n = AppLocalizationsEn();

const _home = StorageVolume(root: '/home/u', kind: StorageVolumeKind.home);
const _sd = StorageVolume(
  root: '/storage/ABCD',
  kind: StorageVolumeKind.sdCard,
);
const _internal = StorageVolume(
  root: '/storage/emulated/0',
  kind: StorageVolumeKind.internal,
);

MusicFolder _folder(int id, String name, String root, StorageVolume volume) =>
    MusicFolder(
      sourceId: id,
      sourceUid: 'uid$id',
      root: root,
      volume: volume,
      name: name,
    );

FolderRow _row(int source, String locator) =>
    (sourceId: source, locator: locator, coverKey: null);

List<String> _labels(List<KBreadcrumbSegment> s) => [
  for (final x in s) x.label,
];

void main() {
  final rows = [
    _row(1, 'V-Pop/Singles/a.flac'),
    _row(1, 'V-Pop/b.flac'),
    _row(2, 'c.flac'),
  ];

  List<KBreadcrumbSegment> segments(
    List<MusicFolder> folders,
    FolderLocation at, {
    required bool mobile,
    FolderView view = FolderView.tree,
    void Function(FolderLocation)? jump,
  }) {
    final roots = buildFolderTrees(folders, rows);
    return folderSegments(
      _l10n,
      resolveFolderPlace(roots, at, view),
      mobile: mobile,
      jump: jump ?? (_) {},
    );
  }

  test(
    'one music folder starts at its location: desktop path, mobile volume',
    () {
      final one = [_folder(1, 'Music', '/home/u/Music', _home)];
      const at = FolderLocation(sourceUid: 'uid1', key: 'V-Pop/Singles');
      expect(_labels(segments(one, at, mobile: false)), [
        '~/Music',
        'V-Pop',
        'Singles',
      ]);
      final phone = [
        _folder(1, 'Music', '/storage/emulated/0/Music', _internal),
      ];
      expect(_labels(segments(phone, at, mobile: true)), [
        'Internal storage',
        'Music',
        'V-Pop',
        'Singles',
      ]);
    },
  );

  test('several music folders start with "All folders"', () {
    final two = [
      _folder(1, 'Music', '/home/u/Music', _home),
      _folder(2, 'Other', '/mnt/Other', otherVolume),
    ];
    expect(
      _labels(
        segments(
          two,
          const FolderLocation(sourceUid: 'uid1', key: 'V-Pop'),
          mobile: false,
        ),
      ),
      ['All folders', 'Music', 'V-Pop'],
    );
    expect(_labels(segments(two, FolderLocation.top, mobile: false)), [
      'All folders',
    ]);
  });

  test('music folders with one name are told apart by their location', () {
    final two = [
      _folder(1, 'Music', '/home/u/Music', _home),
      _folder(2, 'Music', '/storage/ABCD/Music', _sd),
    ];
    expect(
      _labels(
        segments(two, const FolderLocation(sourceUid: 'uid2'), mobile: false),
      ),
      ['All folders', '/storage/ABCD/Music'],
    );
    expect(
      _labels(
        segments(two, const FolderLocation(sourceUid: 'uid2'), mobile: true),
      ),
      ['All folders', 'SD card · Music'],
    );
  });

  test('every level but the open one jumps to itself', () {
    final one = [_folder(1, 'Music', '/home/u/Music', _home)];
    final jumps = <FolderLocation>[];
    final s = segments(
      one,
      const FolderLocation(sourceUid: 'uid1', key: 'V-Pop/Singles'),
      mobile: false,
      jump: jumps.add,
    );
    for (final seg in s) {
      seg.onTap?.call();
    }
    expect(s.last.onTap, isNull);
    expect(jumps, const [
      FolderLocation(sourceUid: 'uid1'),
      FolderLocation(sourceUid: 'uid1', key: 'V-Pop'),
    ]);
  });

  test(
    'a folder opened from the flat list: "All folders" returns to the list',
    () {
      final one = [_folder(1, 'Music', '/home/u/Music', _home)];
      final jumps = <FolderLocation>[];
      final s = segments(
        one,
        const FolderLocation(sourceUid: 'uid1', key: 'V-Pop', flat: true),
        mobile: false,
        view: FolderView.flat,
        jump: jumps.add,
      );
      expect(_labels(s), ['All folders', 'V-Pop']);
      s.first.onTap!();
      expect(jumps, [FolderLocation.flatList]);
    },
  );

  testWidgets(
    'the "..." button picks a hidden level with the open one selected',
    (tester) async {
      final one = [_folder(1, 'Music', '/home/u/Music', _home)];
      final jumps = <FolderLocation>[];
      final s = segments(
        one,
        const FolderLocation(
          sourceUid: 'uid1',
          key: 'V-Pop/Singles/Deep/Deeper',
        ),
        mobile: true,
        jump: jumps.add,
      );
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 800);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildKanaruTheme(brightness: Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: FolderBreadcrumb(segments: s)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Hidden levels'));
      await tester.pumpAndSettle();
      expect(find.text('Go to folder'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SelectionRow),
          matching: find.text('Singles'),
        ),
        findsOneWidget,
      );
      // The open level is listed too, and is the selected row.
      expect(find.byType(SelectionRow), findsWidgets);
      final selected = tester
          .widgetList<SelectionRow>(find.byType(SelectionRow))
          .where((r) => r.selected);
      expect(selected.length, 1);
      await tester.tap(find.text('V-Pop'));
      await tester.pumpAndSettle();
      expect(
        jumps.single,
        const FolderLocation(sourceUid: 'uid1', key: 'V-Pop'),
      );
    },
  );
}
