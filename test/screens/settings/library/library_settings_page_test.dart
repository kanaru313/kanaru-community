import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/scan_status.dart';
import 'package:kanaru/src/library/state/scan/music_folder_editor_provider.dart';
import 'package:kanaru/src/screens/settings/settings_routes.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/icon_button_finders.dart';
import 'library_host.dart';

/// The [SelectionRow] holding [title] (a row of a multi-select sheet).
SelectionRow _option(WidgetTester tester, String title) =>
    tester.widget<SelectionRow>(
      find.ancestor(of: find.text(title), matching: find.byType(SelectionRow)),
    );

void main() {
  group('overview', () {
    testWidgets('shows one line per count; no last-scan line before a scan', (
      tester,
    ) async {
      await openLibrary(tester);
      expect(find.text('2,418 songs'), findsOneWidget);
      expect(find.text('186 albums'), findsOneWidget);
      expect(find.text('142 artists'), findsOneWidget);
      expect(find.textContaining('Last scan'), findsNothing);
      expect(find.text('Rescan'), findsOneWidget);
    });

    testWidgets('a scan finished in this session adds the last-scan line', (
      tester,
    ) async {
      final h = await openLibrary(tester);
      await h.emit(
        tester,
        ScanFinished(
          tracks: 2418,
          albums: 186,
          artists: 142,
          added: 3,
          at: DateTime(2026, 11, 19, 9, 5),
        ),
      );
      expect(find.text('Last scan 09:05 · 3 songs added'), findsOneWidget);
    });

    testWidgets('progress card replaces the overview while tags are read', (
      tester,
    ) async {
      final h = await openLibrary(tester);
      await h.emit(
        tester,
        const ScanRunning(phase: ScanPhase.tags, done: 812, total: 2418),
      );
      expect(find.text('Scanning the library'), findsOneWidget);
      expect(find.byType(ProgressNoticeCard), findsOneWidget);
      expect(find.text('Rescan'), findsNothing);
    });

    testWidgets('Rescan asks the scanner and says so', (tester) async {
      final h = await openLibrary(tester);
      await tester.tap(find.text('Rescan'));
      await tester.pump();
      expect(h.scanner.rescans, 1);
      expect(
        find.text('Rescanning the library in the background'),
        findsOneWidget,
      );
    });

    testWidgets('back arrow leads to the root', (tester) async {
      final h = await openLibrary(tester);
      await tester.tap(byIconButton('Back'));
      await tester.pumpAndSettle();
      expect(
        h
            .settings
            .router
            .routerDelegate
            .currentConfiguration
            .last
            .matchedLocation,
        SettingsPaths.root,
      );
    });
  });

  group('permissions', () {
    testWidgets('Android shows the permission block, Linux does not', (
      tester,
    ) async {
      await openLibrary(tester, android: true);
      expect(find.text('Permissions'), findsOneWidget);
    });

    testWidgets('no permission block on Linux', (tester) async {
      await openLibrary(tester);
      expect(find.text('Permissions'), findsNothing);
    });
  });

  group('scan rules', () {
    testWidgets('default values read as today', (tester) async {
      await openLibrary(tester);
      expect(find.text('30 seconds'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('minimum duration: sheet, key, snack bar, Rescan', (
      tester,
    ) async {
      final h = await openLibrary(tester);
      await tester.tap(find.text('Skip files shorter than'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Ringtones, alerts and short recordings. Applies at the next scan.',
        ),
        findsOneWidget,
      );
      // Home: the smallest stop, "Off".
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(h.settings.store.read('library.min_duration_ms'), 0);
      // The older key follows, so an older build keeps "Off".
      expect(h.settings.store.read('library.skip_short_tracks'), false);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Applies at the next scan'), findsOneWidget);
      expect(h.scanner.rescans, 0);
      await tester.tap(find.text('Rescan').last);
      await tester.pump();
      expect(h.scanner.rescans, 1);
    });

    testWidgets('minimum size: key and value line', (tester) async {
      final h = await openLibrary(tester);
      await tester.tap(find.text('Skip files smaller than'));
      await tester.pumpAndSettle();
      expect(
        find.text('Measured by file size. Applies at the next scan.'),
        findsOneWidget,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(h.settings.store.read('library.min_size_bytes'), 100000);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('100 KB'), findsOneWidget);
    });

    testWidgets('formats: unticking one writes the key and reads "8 / 9"', (
      tester,
    ) async {
      final h = await openLibrary(tester);
      await tester.tap(find.text('Scanned formats'));
      await tester.pumpAndSettle();
      // Behind the sheet the row reads "All"; the sheet counts 9 / 9.
      expect(find.text('9 / 9'), findsOneWidget);
      expect(find.text('m4a, aac, alac'), findsOneWidget);
      await tester.tap(find.text('MP3'));
      await tester.pumpAndSettle();
      expect(h.settings.store.read('library.format_groups'), [
        'flac',
        'm4a',
        'ogg',
        'wav',
        'aiff',
        'ape',
        'wavpack',
        'dsd',
      ]);
      // The row behind the sheet and the sheet's own count.
      expect(find.text('8 / 9'), findsNWidgets(2));
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('8 / 9'), findsOneWidget);
      expect(find.text('Applies at the next scan'), findsOneWidget);
    });

    testWidgets('formats: the last chosen format is locked', (tester) async {
      final h = await openLibrary(tester);
      await h.settings.store.write('library.format_groups', ['flac']);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scanned formats'));
      await tester.pumpAndSettle();
      expect(_option(tester, 'FLAC').enabled, isFalse);
      expect(_option(tester, 'FLAC').selected, isTrue);
      expect(find.textContaining('· keep at least one'), findsOneWidget);
      await tester.tap(find.text('FLAC'));
      await tester.pumpAndSettle();
      expect(h.settings.store.read('library.format_groups'), ['flac']);
      expect(_option(tester, 'MP3').enabled, isTrue);
    });

    testWidgets('desktop: formats open as a panel aligned to the row end', (
      tester,
    ) async {
      await openLibrary(tester, size: const Size(1400, 2400));
      final row = find.ancestor(
        of: find.text('Scanned formats'),
        matching: find.byType(SetupValueRow),
      );
      // The panel lines up with the row's anchor box (its inner box).
      final anchor =
          tester
                  .widget<SetupValueRow>(row)
                  .anchorKey!
                  .currentContext!
                  .findRenderObject()!
              as RenderBox;
      final rowRect = anchor.localToGlobal(Offset.zero) & anchor.size;
      await tester.tap(find.text('Scanned formats'));
      await tester.pumpAndSettle();
      final panel = tester.getRect(
        find.byWidgetPredicate((w) => w is Material && w.elevation == 3),
      );
      expect(panel.right, closeTo(rowRect.right, 1));
      expect(panel.width, lessThan(400));
    });

    testWidgets('Rescan from the toast works after the page is gone', (
      tester,
    ) async {
      final h = await openLibrary(tester);
      await tester.tap(find.text('Skip files shorter than'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Applies at the next scan'), findsOneWidget);
      // Back to another page: the toast outlives the Library page.
      h.settings.router.go('/');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Scanned formats'), findsNothing);
      await tester.tap(find.text('Rescan').last);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(h.scanner.rescans, 1);
    });

    testWidgets('a damaged format list reads as every format', (tester) async {
      final h = await openLibrary(tester);
      await h.settings.store.write('library.format_groups', <String>[]);
      await tester.pumpAndSettle();
      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('.nomedia row exists on Linux only and writes its key', (
      tester,
    ) async {
      final h = await openLibrary(tester);
      expect(find.text('Skip folders with a .nomedia file'), findsOneWidget);
      await tester.tap(find.text('Skip folders with a .nomedia file'));
      await tester.pumpAndSettle();
      expect(h.settings.store.read('library.respect_nomedia'), true);
      expect(find.text('Applies at the next scan'), findsOneWidget);
    });

    testWidgets('same-file-name row writes its key and applies at once', (
      tester,
    ) async {
      final h = await openLibrary(tester);
      expect(h.settings.store.read('library.dedup_by_file_name'), isNull);
      await tester.tap(find.text('Merge tracks with the same file name'));
      await tester.pumpAndSettle();
      expect(h.settings.store.read('library.dedup_by_file_name'), true);
      expect(find.text('Applies at the next scan'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('.nomedia row is absent on Android', (tester) async {
      await openLibrary(tester, android: true);
      expect(find.text('Skip folders with a .nomedia file'), findsNothing);
    });

    testWidgets('watching folders is coming soon', (tester) async {
      await openLibrary(tester);
      expect(find.text('Update when folders change'), findsOneWidget);
      expect(find.text('Coming soon'), findsNWidgets(3));
    });
  });

  group('organise and removed', () {
    testWidgets('merge folders switch writes its key', (tester) async {
      final h = await openLibrary(tester);
      expect(h.settings.store.read('library.compact_folders'), isNull);
      await tester.tap(find.text('Merge folders with a single subfolder'));
      await tester.pumpAndSettle();
      expect(h.settings.store.read('library.compact_folders'), false);
    });

    testWidgets('album grouping and removed tracks are coming soon', (
      tester,
    ) async {
      await openLibrary(tester);
      expect(find.text('Group albums by'), findsOneWidget);
      expect(find.text('Removed from library'), findsOneWidget);
    });
  });

  group('first-run blocks in Settings', () {
    testWidgets('captions sit behind the section hint, not under the title', (
      tester,
    ) async {
      await openLibrary(tester);
      // Three sections with a whole-section note.
      expect(find.byType(KHelpIcon), findsNWidgets(3));
      expect(
        find.text('Kanaru scans these folders and everything inside them.'),
        findsNothing,
      );
    });

    testWidgets('the tabs note names where tabs show on this shell', (
      tester,
    ) async {
      await openLibrary(tester, size: const Size(1400, 2400));
      final help = find.byWidgetPredicate(
        (w) =>
            w is KHelpIcon &&
            w.message.contains('Library items in the sidebar'),
      );
      expect(help, findsOneWidget);
    });

    testWidgets('the last music folder cannot be removed', (tester) async {
      final h = await openLibrary(tester);
      await _addFolders(tester, h, ['/home/u/Music']);
      await tester.tap(byIconButton('Remove Music'));
      await tester.pumpAndSettle();
      expect(find.text('Cannot remove the last folder'), findsOneWidget);
      expect(
        find.textContaining('Add another folder first, then remove “Music”'),
        findsOneWidget,
      );
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.text('Music'), findsOneWidget);
      expect(h.scanner.rescans, 0);
    });

    testWidgets('removing a folder asks, then rescans and says so', (
      tester,
    ) async {
      final h = await openLibrary(tester);
      await _addFolders(tester, h, ['/home/u/Music', '/home/u/Rock']);
      await tester.tap(byIconButton('Remove Rock'));
      await tester.pumpAndSettle();
      expect(find.text('Remove “Rock”?'), findsOneWidget);
      expect(
        find.textContaining('Files on your device are not deleted'),
        findsOneWidget,
      );
      // Cancel leaves everything as it was.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Rock'), findsOneWidget);
      expect(h.scanner.rescans, 0);

      await tester.tap(byIconButton('Remove Rock'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove folder'));
      await tester.pumpAndSettle();
      expect(find.text('Rock'), findsNothing);
      expect(h.scanner.rescans, 1);
      expect(find.text('Removed “Rock”'), findsOneWidget);
    });

    testWidgets('adding a folder rescans in the background', (tester) async {
      final h = await openLibrary(tester);
      h.catalog.picks.add('/home/u/Music');
      await tester.tap(find.text('Add folder…'));
      await tester.pumpAndSettle();
      expect(find.text('Music'), findsOneWidget);
      expect(h.scanner.rescans, 1);
      expect(
        find.text('Rescanning the library in the background'),
        findsOneWidget,
      );
    });

    testWidgets('a refused folder does not rescan', (tester) async {
      final h = await openLibrary(tester);
      await _addFolders(tester, h, ['/home/u/Music']);
      h.catalog.picks.add('/home/u/Music');
      await tester.tap(find.text('Add folder…'));
      await tester.pumpAndSettle();
      expect(find.text('“Music” is already chosen.'), findsOneWidget);
      expect(h.scanner.rescans, 0);
    });

    testWidgets('adding then undoing an exclusion rescans each time', (
      tester,
    ) async {
      final h = await openLibrary(tester);
      await _addFolders(tester, h, ['/home/u/Music']);
      h.catalog.picks.add('/home/u/Music/Live');
      await tester.tap(find.text('Add excluded folder…'));
      await tester.pumpAndSettle();
      expect(find.text('Live'), findsOneWidget);
      expect(h.scanner.rescans, 1);

      await tester.tap(byIconButton('Remove Live'));
      await tester.pumpAndSettle();
      expect(find.text('Live'), findsNothing);
      expect(
        find.text('“Live” is no longer excluded · rescanning'),
        findsOneWidget,
      );
      expect(h.scanner.rescans, 2);
    });
  });
}

/// Adds [paths] as music folders and lets the page show them.
Future<void> _addFolders(
  WidgetTester tester,
  LibraryHarness h,
  List<String> paths,
) async {
  final editor = h.settings.container.read(musicFolderEditorProvider);
  for (final path in paths) {
    await editor.addFolder(path);
  }
  await tester.pumpAndSettle();
}
