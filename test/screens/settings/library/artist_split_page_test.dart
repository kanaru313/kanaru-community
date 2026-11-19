import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/scan/read_rules.dart';
import 'package:kanaru/src/screens/settings/settings_routes.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/icon_button_finders.dart';
import 'library_host.dart';

void main() {
  Future<LibraryHarness> open(WidgetTester tester) => openLibrary(
    tester,
    location: SettingsPaths.artistSplit,
    size: const Size(400, 2400),
  );

  Object? stored(LibraryHarness h, String key) => h.settings.store.read(key);

  testWidgets('defaults: seven separators, example, restore dimmed', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Split artists'), findsWidgets);
    expect(find.text('␣feat.␣'), findsOneWidget);
    expect(find.text('␣featuring␣'), findsOneWidget);
    expect(find.text('AC/DC'), findsOneWidget);
    expect(find.text('+ ␣with␣'), findsOneWidget);
    // The example is split by the rules as they are.
    expect(find.text('Chi Pu'), findsOneWidget);
    expect(find.text('Already the default'), findsOneWidget);
    final semantics = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.byType(KListRow)),
      isSemantics(isEnabled: false),
    );
    semantics.dispose();
  });

  testWidgets(
    'adding a comma stores it, re-scans (the pipeline re-reads) and hints',
    (tester) async {
      final h = await open(tester);
      await tester.enterText(find.byType(TextField).first, ',');
      await tester.tap(find.text('Add').first);
      await tester.pump();
      expect(stored(h, 'library.artist_separators'), [
        ...defaultArtistSeparators,
        ',',
      ]);
      expect(h.scanner.plainRescans, 1);
      expect(
        find.textContaining('add band names that contain it to Keep whole'),
        findsOneWidget,
      );
      final semantics = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byType(KListRow)),
        isSemantics(isEnabled: true),
      );
      semantics.dispose();
      // A plain scan: the pipeline reads in full the folders that differ.
      expect(h.scanner.fullRescans, 0);
    },
  );

  testWidgets('a refused entry shows its message and changes nothing', (
    tester,
  ) async {
    final h = await open(tester);
    await tester.enterText(find.byType(TextField).first, 'FEAT.');
    await tester.tap(find.text('Add').first);
    await tester.pump();
    expect(find.text('Already in the list'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '   ');
    await tester.tap(find.text('Add').first);
    await tester.pump();
    expect(find.text('Nothing typed'), findsOneWidget);
    expect(stored(h, 'library.artist_separators'), isNull);
    expect(h.scanner.plainRescans, 0);
  });

  testWidgets('removing a separator is immediate and re-reads', (tester) async {
    final h = await open(tester);
    await tester.tap(find.bySemanticsLabel('Remove ;'));
    await tester.pump();
    expect(
      stored(h, 'library.artist_separators'),
      defaultArtistSeparators.where((e) => e != ';').toList(),
    );
    expect(h.scanner.plainRescans, 1);
    expect(find.text('Removed “;”'), findsOneWidget);
  });

  testWidgets('keep whole: add and remove', (tester) async {
    final h = await open(tester);
    await tester.enterText(find.byType(TextField).last, 'Earth, Wind & Fire');
    await tester.tap(find.text('Add').last);
    await tester.pump();
    expect(stored(h, 'library.artist_keep_whole'), [
      'AC/DC',
      'Earth, Wind & Fire',
    ]);
    await tester.tap(find.bySemanticsLabel('Remove AC/DC'));
    await tester.pump();
    expect(stored(h, 'library.artist_keep_whole'), ['Earth, Wind & Fire']);
    expect(h.scanner.plainRescans, 2);
  });

  testWidgets('restore asks first; cancel changes nothing', (tester) async {
    final h = await open(tester);
    await tester.tap(find.bySemanticsLabel('Remove ;'));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 5));
    await tester.tap(find.text('Restore defaults'));
    await tester.pumpAndSettle();
    expect(find.text('Restore the default separators?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      stored(h, 'library.artist_separators'),
      isNot(defaultArtistSeparators),
    );
    expect(h.scanner.plainRescans, 1);

    await tester.tap(find.text('Restore defaults'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();
    expect(stored(h, 'library.artist_separators'), defaultArtistSeparators);
    expect(stored(h, 'library.artist_keep_whole'), defaultArtistKeepWhole);
    expect(h.scanner.plainRescans, 2);
    expect(find.text('Already the default'), findsOneWidget);
  });

  testWidgets('a damaged stored list shows the default list', (tester) async {
    final h = await open(tester);
    await h.settings.store.write('library.artist_separators', ['ok', 3]);
    await tester.pumpAndSettle();
    expect(find.text('␣feat.␣'), findsOneWidget);
  });

  testWidgets('the back arrow leads to Library', (tester) async {
    final h = await open(tester);
    await tester.tap(byIconButton('Back'));
    await tester.pumpAndSettle();
    expect(h.settings.router.state.uri.toString(), SettingsPaths.library);
  });

  testWidgets('Library row shows the count and opens the page', (tester) async {
    final h = await openLibrary(tester);
    expect(find.text('7 separators'), findsOneWidget);
    await tester.tap(find.text('Split artists'));
    await tester.pumpAndSettle();
    expect(h.settings.router.state.uri.toString(), SettingsPaths.artistSplit);
  });

  testWidgets('language source: picker, stores, re-scans', (tester) async {
    final h = await openLibrary(tester);
    expect(find.text('Tag, then detection'), findsOneWidget);
    await tester.tap(find.text('Language source'));
    await tester.pumpAndSettle();
    expect(
      find.text('Ignore the file\'s language tag · Coming soon'),
      findsOneWidget,
    );
    // "Detection only" is shown dimmed and cannot be picked.
    await tester.tap(find.text('Detection only'));
    await tester.pumpAndSettle();
    expect(stored(h, 'library.language_source'), isNull);
    expect(h.scanner.plainRescans, 0);
    await tester.tap(find.text('Tag only'));
    await tester.pumpAndSettle();
    expect(stored(h, 'library.language_source'), LanguageSource.tagOnly.name);
    expect(h.scanner.plainRescans, 1);
    expect(find.text('Tag only'), findsOneWidget);
  });
}
