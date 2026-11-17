import 'dart:async';

import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/data/scan/scan_folders.dart';
import 'package:kanaru/src/library/state/music_folders_providers.dart';
import 'package:kanaru/src/platform/domain/local_audio_catalog.dart';
import 'package:kanaru/src/platform/domain/media_permissions.dart';
import 'package:kanaru/src/screens/first_run/ui/no_music_card_note.dart';
import 'package:material_ui/material_ui.dart';

import 'support/first_run_host.dart';

const _music = '/storage/emulated/0/Music';
const _download = '/storage/emulated/0/Download';

const _empty = AudioFoldersListed(<AudioFolderSummary>[]);
const _failed = AudioFoldersFailed(AudioFoldersFailure.failed);
const _listed = AudioFoldersListed([
  AudioFolderSummary(path: _music, audioCount: 10),
  AudioFolderSummary(path: _download, audioCount: 18),
]);
const _foundLine = 'Rescanned · Android found 28 songs.';

const _noMusicCard =
    'Android sees no music on this phone yet. Music you just copied often '
    'does not show up until Android rescans.';
const _stillNoMusicCard = 'Android still sees no music.';
const _scanning = 'Rescanning…';
const _noFolder = 'No folder chosen yet.';
const _listFailed = 'Could not load the folder list';
const _tipShared =
    "• Music must be in shared storage (for example Music or Download), not "
    "inside another app's Android › data folder.";
const _tipRestart =
    '• Restart the phone so Android rescans all storage, then reopen Kanaru.';
const _hintPlain = 'Kanaru scans these folders and everything inside them.';

final _granted = perms(
  MediaPermissionStatus.granted,
  MediaPermissionStatus.granted,
);

final _made = <FakeCatalog>[];

FakeCatalog _catalog(AudioFoldersResult result, {String? suggestion}) {
  final c = FakeCatalog(android: true)
    ..result = result
    ..suggestion = suggestion;
  _made.add(c);
  return c;
}

/// A widget test with semantics on; the handle is released before it ends.
void _test(String name, Future<void> Function(WidgetTester tester) body) =>
    testWidgets(name, (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await body(tester);
      } finally {
        // Release gates a test left open.
        for (final c in _made) {
          if (c.refreshGate?.isCompleted == false) {
            c.refreshGate!.complete(MediaIndexRefresh.failed);
          }
          if (c.readGate?.isCompleted == false) c.readGate!.complete();
        }
        _made.clear();
        handle.dispose();
      }
    });

/// The card alone, with the auto-run off and every result visible.
Future<FirstRunHarness> _pumpCard(
  WidgetTester tester,
  FakeCatalog catalog, {
  bool settle = true,
}) => pumpFirstRun(
  tester,
  android: true,
  permission: _granted,
  catalog: catalog,
  settle: settle,
  child: const Scaffold(
    body: SingleChildScrollView(
      child: NoMusicCardNote(autoRun: false, seenFrom: 0),
    ),
  ),
);

/// The whole first-run page; the card auto-runs. Never settles: a held
/// refresh keeps the bar moving.
Future<FirstRunHarness> _pumpPage(
  WidgetTester tester,
  FakeCatalog catalog, {
  double? width,
  double height = 2600,
}) => pumpFirstRun(
  tester,
  width: width,
  height: height,
  android: true,
  permission: _granted,
  catalog: catalog,
  settle: false,
);

Future<void> _finish(
  WidgetTester tester,
  FakeCatalog catalog,
  MediaIndexRefresh outcome, {
  AudioFoldersResult? result,
}) async {
  if (result != null) catalog.result = result;
  catalog.refreshGate!.complete(outcome);
  catalog.refreshGate = null;
  await frames(tester);
}

Future<Completer<MediaIndexRefresh>> _startRescan(
  WidgetTester tester,
  FakeCatalog catalog,
  Finder button,
) async {
  final gate = catalog.refreshGate = Completer<MediaIndexRefresh>();
  // At a large text scale the button is below the fold.
  await tester.ensureVisible(button);
  await tester.pump();
  await tester.tap(button);
  await frames(tester);
  return gate;
}

void _expectButton(
  WidgetTester tester,
  Finder finder, {
  required bool enabled,
}) => expect(
  tester.getSemantics(finder),
  isSemantics(isButton: true, isEnabled: enabled, hasTapAction: enabled),
);

/// The arrow of the page is off: no action (it may be shown dimmed).
void _expectArrowOff(WidgetTester tester) {
  final arrow = find.bySemanticsLabel('Continue');
  if (arrow.evaluate().isEmpty) return;
  expect(tester.getSemantics(arrow), isSemantics(isEnabled: false));
}

/// The arrow is a button the user can press.
void _expectArrowOn(WidgetTester tester) => expect(
  tester.getSemantics(find.bySemanticsLabel('Continue')),
  isSemantics(isButton: true, isEnabled: true),
);

SemanticsNode _addFolderRow(WidgetTester tester) =>
    tester.getSemantics(find.text('Add folder'));

Finder get _sheetRescan => find.descendant(
  of: find.byType(BottomSheet),
  matching: find.text('Rescan'),
);

void main() {
  group('card on its own', () {
    _test('an empty index: the no-music text and a Rescan button', (
      tester,
    ) async {
      final catalog = _catalog(_empty);
      await _pumpCard(tester, catalog);

      expect(find.text(_noMusicCard), findsOneWidget);
      expect(find.text(_noFolder), findsNothing);
      expect(find.text(_tipShared), findsNothing);
      _expectButton(tester, find.text('Rescan'), enabled: true);
      // The card never starts a run by itself without autoRun.
      expect(catalog.refreshCalls, 0);
    });

    for (final outcome in [
      MediaIndexRefresh.done,
      MediaIndexRefresh.timedOut,
    ]) {
      _test('Rescan then $outcome with music: the count line replaces the '
          'no-music text', (tester) async {
        final catalog = _catalog(_empty);
        final h = await _pumpCard(tester, catalog);

        await _startRescan(tester, catalog, find.text('Rescan'));
        expect(find.text(_scanning), findsOneWidget);
        expect(find.text('Rescan'), findsNothing);
        expect(find.text(_noMusicCard), findsNothing);
        expect(catalog.refreshCalls, 1);

        await _finish(tester, catalog, outcome, result: _listed);
        expect(find.text(_scanning), findsNothing);
        expect(find.text(_foundLine), findsOneWidget);
        expect(find.text(_noFolder), findsOneWidget);
        expect(find.text(_noMusicCard), findsNothing);
        expect(find.textContaining('Rescan'), findsOneWidget);
        expect(h.scanner.rescans, 1);
      });
    }

    _test('a rescan that still finds nothing: short text, both tips, Rescan', (
      tester,
    ) async {
      final catalog = _catalog(_empty);
      await _pumpCard(tester, catalog);
      await _startRescan(tester, catalog, find.text('Rescan'));
      await _finish(tester, catalog, MediaIndexRefresh.done);

      expect(find.text(_stillNoMusicCard), findsOneWidget);
      expect(find.text(_tipShared), findsOneWidget);
      expect(find.text(_tipRestart), findsOneWidget);
      expect(find.text(_noMusicCard), findsNothing);
      expect(find.textContaining('Rescanned'), findsNothing);
      _expectButton(tester, find.text('Rescan'), enabled: true);
    });

    _test('a failed rescan says so and Try again runs a second refresh', (
      tester,
    ) async {
      final catalog = _catalog(_empty);
      final h = await _pumpCard(tester, catalog);
      await _startRescan(tester, catalog, find.text('Rescan'));
      await _finish(tester, catalog, MediaIndexRefresh.failed);

      expect(find.text('Could not rescan.'), findsOneWidget);
      expect(find.text(_noMusicCard), findsNothing);
      expect(find.text(_stillNoMusicCard), findsNothing);
      expect(h.scanner.rescans, 0);

      await _startRescan(tester, catalog, find.text('Try again'));
      expect(catalog.refreshCalls, 2);
      expect(find.text(_scanning), findsOneWidget);
      await _finish(tester, catalog, MediaIndexRefresh.done, result: _listed);
      expect(find.text('Could not rescan.'), findsNothing);
      expect(find.text(_foundLine), findsOneWidget);
    });

    _test('an Android that cannot rescan keeps the no-music text without a '
        'button', (tester) async {
      final catalog = _catalog(_empty);
      await _pumpCard(tester, catalog);
      await _startRescan(tester, catalog, find.text('Rescan'));
      await _finish(tester, catalog, MediaIndexRefresh.unsupported);

      expect(find.text(_noMusicCard), findsOneWidget);
      expect(find.textContaining('Rescan'), findsNothing);
      expect(find.text('Try again'), findsNothing);
      expect(find.text(_stillNoMusicCard), findsNothing);
    });

    _test('a failed read says so, never the empty text, and Try again reads '
        'again', (tester) async {
      final catalog = _catalog(_failed);
      await _pumpCard(tester, catalog);

      expect(find.text(_listFailed), findsOneWidget);
      expect(find.text(_noMusicCard), findsNothing);
      expect(find.text(_noFolder), findsNothing);
      expect(find.text('Rescan'), findsNothing);

      final reads = catalog.audioFolderReads;
      catalog.result = _listed;
      await tester.tap(find.text('Try again'));
      await frames(tester);
      expect(catalog.audioFolderReads, reads + 1);
      expect(find.text(_listFailed), findsNothing);
      expect(find.text(_noFolder), findsOneWidget);
      expect(catalog.refreshCalls, 0);
    });

    _test('while the list loads it shows neither "no music" nor "no folder"', (
      tester,
    ) async {
      final catalog = _catalog(_empty)..readGate = Completer<void>();
      await _pumpCard(tester, catalog, settle: false);
      await frames(tester);

      expect(find.text(_noMusicCard), findsNothing);
      expect(find.text(_noFolder), findsNothing);

      catalog.readGate!.complete();
      await frames(tester);
      expect(find.text(_noMusicCard), findsOneWidget);
    });
  });

  group('card in the first-run page', () {
    _test('auto-runs once: Add folder is off while it runs, the arrow does '
        'not change, and a new page does not run again', (tester) async {
      final catalog = _catalog(_empty)
        ..refreshGate = Completer<MediaIndexRefresh>();
      final h = await _pumpPage(tester, catalog);
      await frames(tester);

      expect(catalog.refreshCalls, 1);
      expect(find.text(_scanning), findsOneWidget);
      expect(find.text(_noMusicCard), findsNothing);
      expect(_addFolderRow(tester), isSemantics(hasTapAction: false));
      await tester.tap(find.text('Add folder'));
      await frames(tester);
      expect(find.byType(BottomSheet), findsNothing);
      _expectArrowOff(tester);

      // A folder chosen while the scan runs turns the arrow on: the scan
      // does not hold it back.
      await h.editor.addFolder(_music, fromCatalog: true);
      await frames(tester);
      expect(catalog.refreshGate!.isCompleted, isFalse);
      _expectArrowOn(tester);
      await h.editor.removeFolder(
        (await h.container.read(musicFoldersProvider.future)).single,
      );
      await frames(tester);
      _expectArrowOff(tester);

      await _finish(tester, catalog, MediaIndexRefresh.done);
      expect(find.text(_stillNoMusicCard), findsOneWidget);
      expect(find.text(_tipShared), findsOneWidget);
      expect(_addFolderRow(tester), isSemantics(hasTapAction: true));
      _expectArrowOff(tester);
      // The page rebuilds around the same launch: still one run.
      await frames(tester);
      expect(catalog.refreshCalls, 1);

      // A new page of the same launch: the old result is not news, the card
      // is back to "no music" with a button, and nothing runs by itself.
      await remountFirstRun(tester, h);
      await frames(tester);
      expect(catalog.refreshCalls, 1);
      expect(find.text(_noMusicCard), findsOneWidget);
      expect(find.text(_stillNoMusicCard), findsNothing);
      _expectButton(tester, find.text('Rescan'), enabled: true);
    });

    _test('a rescan with music shows the count line and turns Add folder on '
        'again', (tester) async {
      final catalog = _catalog(_empty)
        ..refreshGate = Completer<MediaIndexRefresh>();
      final h = await _pumpPage(tester, catalog);
      await frames(tester);
      await _finish(tester, catalog, MediaIndexRefresh.done, result: _listed);

      expect(find.text(_foundLine), findsOneWidget);
      expect(find.text(_noFolder), findsOneWidget);
      expect(_addFolderRow(tester), isSemantics(hasTapAction: true));
      // Nothing is chosen for the user.
      expect(await liveScanFolders(h.db), isEmpty);
      _expectArrowOff(tester);
      expect(catalog.refreshCalls, 1);
    });

    _test('the card and the sheet share one run', (tester) async {
      final catalog = _catalog(_empty)
        ..refreshGate = Completer<MediaIndexRefresh>();
      await _pumpPage(tester, catalog);
      await frames(tester);
      await _finish(tester, catalog, MediaIndexRefresh.done);
      expect(find.text(_stillNoMusicCard), findsOneWidget);

      await tester.tap(find.text('Add folder'));
      await frames(tester);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Android sees no music yet'), findsOneWidget);
      // The sheet did not see the card's run.
      expect(find.text('Still no music found'), findsNothing);

      await _startRescan(tester, catalog, _sheetRescan);
      // One run, shown in both places.
      expect(catalog.refreshCalls, 2);
      expect(find.text(_scanning), findsNWidgets(2));

      await _finish(tester, catalog, MediaIndexRefresh.done, result: _listed);
      expect(catalog.refreshCalls, 2);
      expect(find.text(_foundLine), findsNWidgets(2));
      expect(find.text('Download'), findsOneWidget);
    });

    _test('a failed read: the card says so and Try again reads again, with no '
        'auto-run', (tester) async {
      final catalog = _catalog(_failed);
      await _pumpPage(tester, catalog);
      await frames(tester);

      expect(find.text(_listFailed), findsOneWidget);
      expect(catalog.refreshCalls, 0);
      final reads = catalog.audioFolderReads;
      catalog.result = _listed;
      await tester.tap(find.text('Try again'));
      await frames(tester);
      expect(catalog.audioFolderReads, reads + 1);
      expect(find.text(_listFailed), findsNothing);
      expect(find.text(_noFolder), findsOneWidget);
      expect(catalog.refreshCalls, 0);
    });
  });

  group('estimate hint', () {
    for (final (name, result) in [('failed', _failed), ('empty', _empty)]) {
      _test('a $name index shows the plain hint, no number', (tester) async {
        final catalog = _catalog(result);
        final h = await pumpFirstRun(
          tester,
          android: true,
          permission: _granted,
          catalog: catalog,
        );
        await h.editor.addFolder(_music, fromCatalog: true);
        await tester.pumpAndSettle();

        expect(find.text(_hintPlain), findsOneWidget);
        expect(find.textContaining('about'), findsNothing);
        expect(find.textContaining(' song'), findsNothing);
      });
    }

    _test('a listed index shows the estimate', (tester) async {
      final catalog = _catalog(_listed);
      final h = await pumpFirstRun(
        tester,
        android: true,
        permission: _granted,
        catalog: catalog,
      );
      await h.editor.addFolder(_music, fromCatalog: true);
      await tester.pumpAndSettle();

      expect(
        find.text('Kanaru scans these folders · about 10 songs'),
        findsOneWidget,
      );
    });
  });

  group('text scale and motion', () {
    _test('the card states fit at 200 % text', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final catalog = _catalog(_empty)
        ..refreshGate = Completer<MediaIndexRefresh>();
      await _pumpPage(tester, catalog, width: 412, height: 915);
      await frames(tester);
      await tester.scrollUntilVisible(
        find.text(_scanning),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(_scanning), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _finish(tester, catalog, MediaIndexRefresh.done);
      await tester.scrollUntilVisible(
        find.text(_stillNoMusicCard),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(_stillNoMusicCard), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(_tipRestart),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(_tipRestart), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _startRescan(tester, catalog, find.text('Rescan'));
      await _finish(tester, catalog, MediaIndexRefresh.failed);
      await tester.scrollUntilVisible(
        find.text('Could not rescan.'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Could not rescan.'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _startRescan(tester, catalog, find.text('Try again'));
      await _finish(tester, catalog, MediaIndexRefresh.done, result: _listed);
      await tester.scrollUntilVisible(
        find.text(_foundLine),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(_foundLine), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    _test('with animations off the page settles while the card scans', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final catalog = _catalog(_empty)
        ..refreshGate = Completer<MediaIndexRefresh>();
      await _pumpPage(tester, catalog);
      // Would never return with the bar animating.
      await tester.pumpAndSettle();
      expect(find.text(_scanning), findsOneWidget);
      expect(catalog.refreshCalls, 1);
    });
  });
}
