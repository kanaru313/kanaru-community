import 'dart:async';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/data/scan/scan_folders.dart';
import 'package:kanaru/src/library/domain/library_tabs.dart';
import 'package:kanaru/src/library/state/library_tabs_providers.dart';
import 'package:kanaru/src/library/state/music_folders_providers.dart';
import 'package:kanaru/src/screens/settings/state/appearance_settings.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/first_run_host.dart';

Finder _tooltip(String message) => find.byWidgetPredicate(
  (w) => w is Tooltip && w.message == message,
  description: 'tooltip "$message"',
);

void main() {
  testWidgets('has no permission group', (tester) async {
    await pumpFirstRun(tester);
    expect(find.text('Welcome to Kanaru'), findsOneWidget);
    expect(find.text('Permissions'), findsNothing);
    expect(find.byType(PermissionCard), findsNothing);
  });

  testWidgets('the system music folder is chosen and marked Suggested', (
    tester,
  ) async {
    final catalog = FakeCatalog()..suggestion = '/home/u/Music';
    final h = await pumpFirstRun(tester, catalog: catalog);
    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Suggested'), findsOneWidget);
    expect(find.text('~/Music'), findsOneWidget);
    expect(await liveScanFolders(h.db), hasLength(1));
  });

  testWidgets('removing the suggested folder keeps it removed', (tester) async {
    final catalog = FakeCatalog()..suggestion = '/home/u/Music';
    final h = await pumpFirstRun(tester, catalog: catalog);
    await tester.tap(find.byIcon(KIcons.close));
    await tester.pumpAndSettle();
    expect(find.text('Music'), findsNothing);
    expect(find.text('No folder chosen yet.'), findsOneWidget);
    expect(await liveScanFolders(h.db), isEmpty);
  });

  testWidgets('without a system music folder it says so', (tester) async {
    await pumpFirstRun(tester);
    expect(
      find.text(
        'Kanaru could not find the system Music folder. Add the folder that '
        'holds your music.',
      ),
      findsOneWidget,
    );
    expect(find.text('Suggested'), findsNothing);
  });

  testWidgets('the arrow is there, dimmed with a tooltip, until a folder is '
      'chosen', (tester) async {
    final h = await pumpFirstRun(tester);
    final button = find.byType(SetupNextButton);
    expect(button, findsOneWidget);
    expect(tester.widget<SetupNextButton>(button).visible, isTrue);
    expect(tester.widget<SetupNextButton>(button).onPressed, isNull);
    expect(_tooltip('Add at least one music folder'), findsOneWidget);

    h.catalog.picks.add('/home/u/Songs');
    await tester.tap(find.text('Add folder…'));
    await tester.pumpAndSettle();
    expect(tester.widget<SetupNextButton>(button).onPressed, isNotNull);
    expect(find.text('~/Songs'), findsOneWidget);
  });

  testWidgets('the arrow finishes setup: flag set, one scan asked, settings '
      'flushed', (tester) async {
    final catalog = FakeCatalog()..suggestion = '/home/u/Music';
    final h = await pumpFirstRun(tester, catalog: catalog);
    await tester.tap(find.byType(SetupNextButton));
    await tester.pumpAndSettle();
    expect(h.settings.read('library.setup_done'), isTrue);
    expect(h.scanner.rescans, 1);
  });

  testWidgets('a nested folder is refused with a message naming it', (
    tester,
  ) async {
    final catalog = FakeCatalog()..suggestion = '/home/u/Music';
    final h = await pumpFirstRun(tester, catalog: catalog);
    h.catalog.picks.add('/home/u/Music/Rock');
    await tester.tap(find.text('Add folder…'));
    await tester.pumpAndSettle();
    expect(find.text('“Rock” is already inside “Music”.'), findsOneWidget);
    expect(await liveScanFolders(h.db), hasLength(1));
  });

  testWidgets('the same folder twice says it is already chosen', (
    tester,
  ) async {
    final catalog = FakeCatalog()..suggestion = '/home/u/Music';
    final h = await pumpFirstRun(tester, catalog: catalog);
    h.catalog.picks.add('/home/u/Music');
    await tester.tap(find.text('Add folder…'));
    await tester.pumpAndSettle();
    expect(find.text('“Music” is already chosen.'), findsOneWidget);
  });

  testWidgets('the theme applies at once to the app', (tester) async {
    await pumpFirstRun(tester);
    expect(tester.themeMode, ThemeMode.system);
    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    // Desktop: an anchored panel, not a sheet.
    expect(find.byType(BottomSheet), findsNothing);
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();
    expect(tester.themeMode, ThemeMode.dark);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('the language applies at once', (tester) async {
    final h = await pumpFirstRun(tester);
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếng Việt').last);
    await tester.pumpAndSettle();
    expect(h.container.read(appLanguageProvider), AppLanguage.vi);
    expect(find.text('Chào mừng đến Kanaru'), findsOneWidget);
  });

  testWidgets('the last enabled tab switch is locked', (tester) async {
    final h = await pumpFirstRun(tester);
    final tabs = [
      'Songs',
      'Albums',
      'Artists',
      'Genres',
      'Languages',
      'Folders',
    ];
    for (final name in tabs.take(5)) {
      await tester.tap(switchOf(name));
      await tester.pumpAndSettle();
    }
    expect(h.container.read(libraryTabsProvider).enabled, {LibraryTab.folders});
    expect(tester.widget<Switch>(switchOf('Folders')).onChanged, isNull);
    expect(tester.widget<Switch>(switchOf('Songs')).onChanged, isNotNull);
  });

  testWidgets('removing a music folder removes its exclusions', (tester) async {
    final catalog = FakeCatalog()..suggestion = '/home/u/Music';
    final h = await pumpFirstRun(tester, catalog: catalog);
    final folder = (await h.container.read(musicFoldersProvider.future)).single;
    await h.editor.excludeFolder(folder, '/home/u/Music/Podcasts');
    await tester.pumpAndSettle();
    expect(find.text('Podcasts'), findsOneWidget);
    expect(find.text('~/Music/Podcasts'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove Music'));
    await tester.pumpAndSettle();
    expect(find.text('Podcasts'), findsNothing);
    expect(find.text('No folder excluded.'), findsOneWidget);
    expect(await excludedPaths(h), isEmpty);
  });

  testWidgets('an exclusion is added from the system dialog starting in the '
      'music folder', (tester) async {
    final catalog = FakeCatalog()..suggestion = '/home/u/Music';
    final h = await pumpFirstRun(tester, catalog: catalog);
    h.catalog.picks.add('/home/u/Music/Live');
    await tester.tap(find.text('Add excluded folder…'));
    await tester.pumpAndSettle();
    expect(h.catalog.pickStarts, ['/home/u/Music']);
    expect(find.text('~/Music/Live'), findsOneWidget);
  });

  testWidgets('an exclusion outside every music folder is refused', (
    tester,
  ) async {
    final catalog = FakeCatalog()..suggestion = '/home/u/Music';
    final h = await pumpFirstRun(tester, catalog: catalog);
    h.catalog.picks.add('/home/u/Other');
    await tester.tap(find.text('Add excluded folder…'));
    await tester.pumpAndSettle();
    expect(find.text('“Other” is not inside a music folder.'), findsOneWidget);
  });

  testWidgets('exclusions cannot be added before a folder exists', (
    tester,
  ) async {
    await pumpFirstRun(tester);
    final row = tester.widget<SetupAddRow>(
      find.ancestor(
        of: find.text('Add excluded folder…'),
        matching: find.byType(SetupAddRow),
      ),
    );
    expect(row.onTap, isNull);
  });

  testWidgets('two quick taps on the arrow finish setup once', (tester) async {
    final catalog = FakeCatalog()..suggestion = '/home/u/Music';
    final h = await pumpFirstRun(tester, catalog: catalog);
    h.scanner.gate = Completer<void>();
    await tester.tap(find.byType(SetupNextButton));
    await tester.tap(find.byType(SetupNextButton), warnIfMissed: false);
    await tester.pump();
    expect(h.scanner.rescans, 1);
    h.scanner.gate!.complete();
    await tester.pumpAndSettle();
    expect(h.scanner.rescans, 1);
  });

  testWidgets('picking / names the path, not an empty folder', (tester) async {
    final h = await pumpFirstRun(tester);
    h.catalog.picks.add('/');
    await tester.tap(find.text('Add folder…'));
    await tester.pumpAndSettle();
    expect(find.text('“/” is too broad to scan.'), findsOneWidget);
  });

  testWidgets('a column no wider than 640 on a wide window', (tester) async {
    await pumpFirstRun(tester, width: 1600);
    final box = tester.getSize(find.byType(SetupSection).first);
    expect(box.width, lessThanOrEqualTo(640));
  });
}

Future<List<String>> excludedPaths(FirstRunHarness h) async => [
  for (final f in await liveScanFolders(h.db)) ...await _keys(h, f.sourceId),
];

Future<List<String>> _keys(FirstRunHarness h, int sourceId) async {
  final rows = await h.db
      .customSelect(
        'SELECT folder_key FROM excluded_folders WHERE source_id = ? '
        'AND deleted_at IS NULL',
        variables: [Variable.withInt(sourceId)],
      )
      .get();
  return [for (final r in rows) r.read<String>('folder_key')];
}
