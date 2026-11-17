import 'dart:async';

import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/data/scan/scan_folders.dart';
import 'package:kanaru/src/library/state/scan/folder_candidates_provider.dart';
import 'package:kanaru/src/library/state/scan/media_index_refresh.dart';
import 'package:kanaru/src/platform/domain/local_audio_catalog.dart';
import 'package:kanaru/src/platform/domain/media_permissions.dart';
import 'package:kanaru/src/screens/first_run/ui/folder_sheet_states.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/first_run_host.dart';

const _music = '/storage/emulated/0/Music';
const _download = '/storage/emulated/0/Download';

const _empty = AudioFoldersListed(<AudioFolderSummary>[]);
const _failed = AudioFoldersFailed(AudioFoldersFailure.failed);

/// What Android reports after a rescan: 10 + 18 songs.
const _listed = AudioFoldersListed([
  AudioFolderSummary(path: _music, audioCount: 10),
  AudioFolderSummary(path: _download, audioCount: 18),
]);
const _foundBanner = 'Rescanned · Android found 28 songs.';

/// Music with one sub-folder, for the exclusion sheet.
const _withSubfolder = AudioFoldersListed([
  AudioFolderSummary(path: _music, audioCount: 10),
  AudioFolderSummary(path: '$_music/Rock', audioCount: 4),
]);

const _noMusicTitle = 'Android sees no music yet';
const _stillNoMusicTitle = 'Still no music found';
const _listFailedTitle = 'Could not load the folder list';
const _loadingText = 'Looking for folders with music…';
const _scanning = 'Rescanning…';
const _everyChosen = 'Every folder with music is already chosen.';
const _rescanRow = "Can't see your folder? Rescan";
const _tipShared =
    "• Music must be in shared storage (for example Music or Download), not "
    "inside another app's Android › data folder.";
const _tipRestart =
    '• Restart the phone so Android rescans all storage, then reopen Kanaru.';

final _made = <FakeCatalog>[];

FakeCatalog _catalog(AudioFoldersResult result, {String? suggestion = _music}) {
  final c = FakeCatalog(android: true)
    ..result = result
    ..suggestion = suggestion;
  _made.add(c);
  return c;
}

/// The two sheets behind two buttons, audio permission granted.
Future<FirstRunHarness> _pump(
  WidgetTester tester,
  FakeCatalog catalog, {
  double? width,
  double height = 2600,
}) {
  return pumpFirstRun(
    tester,
    width: width,
    height: height,
    android: true,
    permission: perms(
      MediaPermissionStatus.granted,
      MediaPermissionStatus.granted,
    ),
    catalog: catalog,
    child: const SheetHost(),
  );
}

Future<void> _open(
  WidgetTester tester, [
  String button = SheetHost.openAdd,
]) async {
  await tester.tap(find.text(button));
  await frames(tester);
}

/// Taps [label], with a refresh gate the test completes later.
Future<Completer<MediaIndexRefresh>> _startRescan(
  WidgetTester tester,
  FakeCatalog catalog,
  String label,
) async {
  final gate = catalog.refreshGate = Completer<MediaIndexRefresh>();
  // At a large text scale the button is below the fold of the sheet.
  await _see(tester, find.text(label));
  await tester.ensureVisible(find.text(label));
  await tester.pump();
  await tester.tap(find.text(label));
  await frames(tester);
  return gate;
}

/// Ends the run in flight with [outcome]; the list Android reports afterwards
/// is [result] when given.
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

SemanticsNode _rowNode(WidgetTester tester, String title) =>
    tester.getSemantics(
      find.ancestor(of: find.text(title), matching: find.byType(SelectionRow)),
    );

/// Scrolls the sheet until [finder] is built and visible (at a large text
/// scale a state can be taller than the sheet).
Future<void> _see(WidgetTester tester, Finder finder) async {
  final scrollable = find
      .descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(Scrollable),
      )
      .first;
  for (final delta in [-300.0, 300.0]) {
    if (finder.evaluate().isNotEmpty) break;
    try {
      await tester.scrollUntilVisible(
        finder,
        delta,
        scrollable: scrollable,
        maxScrolls: 20,
      );
    } on StateError {
      // Wrong direction: try the other one.
    }
  }
}

void _expectChosen(WidgetTester tester, String title, {required bool chosen}) =>
    expect(
      _rowNode(tester, title),
      isSemantics(hasCheckedState: true, isChecked: chosen),
      reason: '$title chosen: $chosen',
    );

void _expectButton(
  WidgetTester tester,
  Finder finder, {
  required bool enabled,
}) => expect(
  tester.getSemantics(finder),
  isSemantics(isButton: true, isEnabled: enabled, hasTapAction: enabled),
);

/// A widget test with semantics on (state is asserted through semantics); the
/// handle must be released before the test ends.
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

void main() {
  group('refresh state helpers', () {
    test('a run in flight counts as seen, a finished one does not', () {
      expect(refreshSeenFrom(const IndexRefreshIdle()), 0);
      expect(refreshSeenFrom(const IndexRefreshRunning(5)), 4);
      expect(
        refreshSeenFrom(
          const IndexRefreshFinished(3, MediaIndexRefresh.done, 1),
        ),
        3,
      );
    });

    test('a finished run shows only above the run id the surface saw', () {
      const finished = IndexRefreshFinished(3, MediaIndexRefresh.done, 1);
      expect(seenRefreshResult(finished, 3), isNull);
      expect(seenRefreshResult(finished, 2), same(finished));
      expect(seenRefreshResult(const IndexRefreshRunning(4), 0), isNull);
      expect(seenRefreshResult(const IndexRefreshIdle(), 0), isNull);
    });

    test('only an unsupported outcome hides every rescan entry', () {
      for (final outcome in MediaIndexRefresh.values) {
        expect(
          refreshUnsupported(IndexRefreshFinished(1, outcome, null)),
          outcome == MediaIndexRefresh.unsupported,
          reason: '$outcome',
        );
      }
      expect(refreshUnsupported(const IndexRefreshRunning(1)), isFalse);
    });

    test('done and timedOut mean the system looked; failed does not', () {
      IndexRefreshFinished of(MediaIndexRefresh o) =>
          IndexRefreshFinished(1, o, null);
      expect(of(MediaIndexRefresh.done).looked, isTrue);
      expect(of(MediaIndexRefresh.timedOut).looked, isTrue);
      expect(of(MediaIndexRefresh.failed).looked, isFalse);
      expect(of(MediaIndexRefresh.unsupported).looked, isFalse);
      expect(of(MediaIndexRefresh.failed).failed, isTrue);
      expect(of(MediaIndexRefresh.done).failed, isFalse);
    });
  });

  group('add sheet with no list yet', () {
    _test('opens at once and says it is looking while the read is '
        'pending', (tester) async {
      final catalog = _catalog(_listed, suggestion: null)
        ..readGate = Completer<void>();
      await _pump(tester, catalog);
      await _open(tester);

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Add music folders'), findsOneWidget);
      expect(find.text(_loadingText), findsOneWidget);
      expect(find.text(_everyChosen), findsNothing);
      expect(find.text(_noMusicTitle), findsNothing);

      catalog.readGate!.complete();
      await frames(tester);
      expect(find.text(_loadingText), findsNothing);
      expect(find.text('Download'), findsOneWidget);
    });

    _test('an empty index says Android sees no music, offers Rescan, '
        'never "every folder chosen"', (tester) async {
      await _pump(tester, _catalog(_empty));
      await _open(tester);

      expect(find.text(_noMusicTitle), findsOneWidget);
      expect(find.text(_everyChosen), findsNothing);
      _expectButton(tester, find.text('Rescan'), enabled: true);
      expect(find.text(_rescanRow), findsNothing);
    });

    for (final outcome in [
      MediaIndexRefresh.done,
      MediaIndexRefresh.timedOut,
    ]) {
      _test('Rescan then $outcome: banner, rows, Music preselected, '
          'nothing written until Add', (tester) async {
        final catalog = _catalog(_empty);
        final h = await _pump(tester, catalog);
        await _open(tester);

        await _startRescan(tester, catalog, 'Rescan');
        expect(find.text(_scanning), findsOneWidget);
        expect(find.text('Rescan'), findsNothing);
        expect(find.text(_noMusicTitle), findsNothing);
        expect(
          find.text('If you close this sheet, Android keeps scanning.'),
          findsOneWidget,
        );
        expect(catalog.refreshCalls, 1);

        await _finish(tester, catalog, outcome, result: _listed);
        expect(find.text(_foundBanner), findsOneWidget);
        expect(find.text(_scanning), findsNothing);
        expect(find.text(_noMusicTitle), findsNothing);
        expect(
          find.text('Internal storage › Music · 10 songs'),
          findsOneWidget,
        );
        expect(
          find.text('Internal storage › Download · 18 songs'),
          findsOneWidget,
        );
        _expectChosen(tester, 'Music', chosen: true);
        _expectChosen(tester, 'Download', chosen: false);
        expect(find.text('Add 1'), findsOneWidget);
        // The picked rows are only suggestions until Add.
        expect(await liveScanFolders(h.db), isEmpty);
        expect(h.scanner.rescans, 1);
        expect(catalog.refreshCalls, 1);

        await tester.tap(find.text('Add 1'));
        await frames(tester);
        expect(find.byType(BottomSheet), findsNothing);
        expect([for (final f in await liveScanFolders(h.db)) f.root], [_music]);
      });
    }

    _test('a rescan that still finds nothing lists both tips and '
        'offers Rescan again', (tester) async {
      final catalog = _catalog(_empty);
      await _pump(tester, catalog);
      await _open(tester);
      await _startRescan(tester, catalog, 'Rescan');
      await _finish(tester, catalog, MediaIndexRefresh.done);

      expect(find.text(_stillNoMusicTitle), findsOneWidget);
      expect(find.text(_tipShared), findsOneWidget);
      expect(find.text(_tipRestart), findsOneWidget);
      expect(find.text(_noMusicTitle), findsNothing);
      expect(find.textContaining('Rescanned'), findsNothing);
      _expectButton(tester, find.text('Rescan'), enabled: true);

      // The second Rescan is a second run.
      await _startRescan(tester, catalog, 'Rescan');
      expect(catalog.refreshCalls, 2);
      expect(find.text(_scanning), findsOneWidget);
      await _finish(tester, catalog, MediaIndexRefresh.done, result: _listed);
      expect(find.text(_foundBanner), findsOneWidget);
      expect(find.text(_stillNoMusicTitle), findsNothing);
    });

    _test('a failed rescan says so, does not rescan the list, and Try '
        'again starts a second run', (tester) async {
      final catalog = _catalog(_empty);
      final h = await _pump(tester, catalog);
      await _open(tester);
      await _startRescan(tester, catalog, 'Rescan');
      final readsBefore = catalog.audioFolderReads;
      await _finish(tester, catalog, MediaIndexRefresh.failed);

      expect(find.text(_listFailedTitle), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text(_noMusicTitle), findsNothing);
      expect(find.text(_everyChosen), findsNothing);
      // A failed run never reads the index again nor asks for a scan.
      expect(catalog.audioFolderReads, readsBefore);
      expect(h.scanner.rescans, 0);

      await _startRescan(tester, catalog, 'Try again');
      expect(catalog.refreshCalls, 2);
      expect(find.text(_scanning), findsOneWidget);
      await _finish(tester, catalog, MediaIndexRefresh.done, result: _listed);
      expect(find.text(_foundBanner), findsOneWidget);
      expect(find.text(_listFailedTitle), findsNothing);
    });

    _test('an Android that cannot rescan keeps the no-music text and '
        'hides every Rescan entry', (tester) async {
      final catalog = _catalog(_empty);
      await _pump(tester, catalog);
      await _open(tester);
      await _startRescan(tester, catalog, 'Rescan');
      await _finish(tester, catalog, MediaIndexRefresh.unsupported);

      expect(find.text(_noMusicTitle), findsOneWidget);
      expect(find.textContaining('Rescan'), findsNothing);
      expect(find.text(_stillNoMusicTitle), findsNothing);
      expect(find.text(_listFailedTitle), findsNothing);
    });

    _test('a failed read offers Try again, which reads again and shows '
        'the rows', (tester) async {
      final catalog = _catalog(_failed, suggestion: null);
      await _pump(tester, catalog);
      await _open(tester);

      expect(find.text(_listFailedTitle), findsOneWidget);
      expect(
        find.text('Android did not answer in time or reported an error.'),
        findsOneWidget,
      );
      expect(find.text(_noMusicTitle), findsNothing);
      expect(find.text(_everyChosen), findsNothing);
      _expectButton(tester, find.text('Try again'), enabled: true);

      final reads = catalog.audioFolderReads;
      catalog.result = _listed;
      await tester.tap(find.text('Try again'));
      await frames(tester);
      expect(catalog.audioFolderReads, reads + 1);
      expect(find.text(_listFailedTitle), findsNothing);
      expect(find.text('Music'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
      // Reading again is not a rescan.
      expect(catalog.refreshCalls, 0);
    });
  });

  group('add sheet with a list', () {
    _test('the trailing row starts one shared refresh, is off while it '
        'runs, and a quick second tap joins it', (tester) async {
      final catalog = _catalog(_listed);
      final h = await _pump(tester, catalog);
      await _open(tester);

      expect(find.text('Download'), findsOneWidget);
      expect(find.textContaining('Rescanned'), findsNothing);
      // No rescan was seen yet: Music is only a suggestion after one.
      _expectChosen(tester, 'Music', chosen: false);
      expect(
        tester.getSemantics(find.text(_rescanRow)),
        isSemantics(hasTapAction: true),
      );

      final gate = catalog.refreshGate = Completer<MediaIndexRefresh>();
      // Two taps in the same frame.
      await tester.tap(find.text(_rescanRow));
      await tester.tap(find.text(_rescanRow));
      await frames(tester);
      expect(find.text(_scanning), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
      expect(
        tester.getSemantics(find.text(_rescanRow)),
        isSemantics(hasTapAction: false),
      );
      await tester.tap(find.text(_rescanRow));
      await frames(tester);
      expect(catalog.refreshCalls, 1);

      gate.complete(MediaIndexRefresh.done);
      catalog.refreshGate = null;
      await frames(tester);
      expect(catalog.refreshCalls, 1);
      expect(find.text(_scanning), findsNothing);
      expect(find.text(_foundBanner), findsOneWidget);
      expect(
        tester.getSemantics(find.text(_rescanRow)),
        isSemantics(hasTapAction: true),
      );
      _expectChosen(tester, 'Music', chosen: true);
      expect(h.scanner.rescans, 1);
    });

    _test('every folder chosen keeps its text and the trailing row', (
      tester,
    ) async {
      final catalog = _catalog(
        const AudioFoldersListed([
          AudioFolderSummary(path: _music, audioCount: 10),
        ]),
      );
      final h = await _pump(tester, catalog);
      await h.editor.addFolder(_music, fromCatalog: true);
      await tester.pumpAndSettle();
      await _open(tester);

      expect(find.text(_everyChosen), findsOneWidget);
      expect(find.text(_rescanRow), findsOneWidget);
      expect(find.text(_noMusicTitle), findsNothing);
      expect(find.text(_stillNoMusicTitle), findsNothing);
    });

    _test('a failed rescan keeps the list, shows an error banner and '
        'Try again starts a second run', (tester) async {
      final catalog = _catalog(_listed, suggestion: null);
      final h = await _pump(tester, catalog);
      await _open(tester);
      await _startRescan(tester, catalog, _rescanRow);
      await _finish(tester, catalog, MediaIndexRefresh.failed);

      expect(find.text('Could not rescan.'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
      expect(find.text(_scanning), findsNothing);
      expect(h.scanner.rescans, 0);

      await _startRescan(tester, catalog, 'Try again');
      expect(catalog.refreshCalls, 2);
      expect(find.text(_scanning), findsOneWidget);
      await _finish(tester, catalog, MediaIndexRefresh.done);
      expect(find.text(_foundBanner), findsOneWidget);
      expect(find.text('Could not rescan.'), findsNothing);
    });

    _test('an Android that cannot rescan drops the trailing row and '
        'shows no banner', (tester) async {
      final catalog = _catalog(_listed);
      await _pump(tester, catalog);
      await _open(tester);
      await _startRescan(tester, catalog, _rescanRow);
      await _finish(tester, catalog, MediaIndexRefresh.unsupported);

      expect(find.text(_rescanRow), findsNothing);
      expect(find.textContaining('Rescan'), findsNothing);
      expect(find.text('Download'), findsOneWidget);
    });

    _test('a result the sheet did not see is hidden on reopen, and '
        'Music is not offered again', (tester) async {
      final catalog = _catalog(_empty);
      await _pump(tester, catalog);
      await _open(tester);
      await _startRescan(tester, catalog, 'Rescan');
      await _finish(tester, catalog, MediaIndexRefresh.done, result: _listed);
      expect(find.text(_foundBanner), findsOneWidget);
      _expectChosen(tester, 'Music', chosen: true);

      await tester.tap(find.text('Cancel'));
      await frames(tester);
      expect(find.byType(BottomSheet), findsNothing);

      await _open(tester);
      expect(find.text('Download'), findsOneWidget);
      expect(find.textContaining('Rescanned'), findsNothing);
      expect(find.text(_scanning), findsNothing);
      _expectChosen(tester, 'Music', chosen: false);
      _expectButton(tester, find.text('Add'), enabled: false);
      expect(find.text(_rescanRow), findsOneWidget);
    });

    _test('Music unticked by the user is not ticked again by a second '
        'rescan', (tester) async {
      final catalog = _catalog(_listed);
      await _pump(tester, catalog);
      await _open(tester);
      await _startRescan(tester, catalog, _rescanRow);
      await _finish(tester, catalog, MediaIndexRefresh.done);
      _expectChosen(tester, 'Music', chosen: true);

      await tester.tap(find.text('Music'));
      await frames(tester, 1);
      _expectChosen(tester, 'Music', chosen: false);
      _expectButton(tester, find.text('Add'), enabled: false);

      await _startRescan(tester, catalog, _rescanRow);
      expect(catalog.refreshCalls, 2);
      await _finish(tester, catalog, MediaIndexRefresh.done);
      expect(find.text(_foundBanner), findsOneWidget);
      _expectChosen(tester, 'Music', chosen: false);
      _expectButton(tester, find.text('Add'), enabled: false);
    });

    _test('a pick survives a reload of the list and Add writes it', (
      tester,
    ) async {
      final catalog = _catalog(_listed, suggestion: null);
      final h = await _pump(tester, catalog);
      await _open(tester);
      await tester.tap(find.text('Download'));
      await frames(tester, 1);
      _expectChosen(tester, 'Download', chosen: true);
      expect(find.text('Add 1'), findsOneWidget);

      // The list reloads: the rows stay, no loading note replaces them.
      final gate = catalog.readGate = Completer<void>();
      h.container.invalidate(audioFoldersProvider);
      await frames(tester);
      expect(find.text(_loadingText), findsNothing);
      expect(find.text('Download'), findsOneWidget);
      _expectChosen(tester, 'Download', chosen: true);

      gate.complete();
      await frames(tester);
      _expectChosen(tester, 'Download', chosen: true);
      _expectChosen(tester, 'Music', chosen: false);
      expect(find.text('Add 1'), findsOneWidget);

      await tester.tap(find.text('Add 1'));
      await frames(tester);
      expect(
        [for (final f in await liveScanFolders(h.db)) f.root],
        [_download],
      );
    });
  });

  group('exclusion sheet', () {
    Future<FirstRunHarness> pumpExclusion(
      WidgetTester tester,
      FakeCatalog catalog,
    ) async {
      final h = await _pump(tester, catalog);
      await h.editor.addFolder(_music, fromCatalog: true);
      await tester.pumpAndSettle();
      return h;
    }

    _test('loads with its own text, lists sub-folders and has no '
        'Rescan', (tester) async {
      final catalog = _catalog(_withSubfolder);
      await pumpExclusion(tester, catalog);
      catalog.readGate = Completer<void>();
      await _open(tester, SheetHost.openExclude);

      expect(find.text('Exclude folders'), findsOneWidget);
      expect(find.text('Looking for sub-folders…'), findsOneWidget);
      expect(find.text(_loadingText), findsNothing);

      catalog.readGate!.complete();
      await frames(tester);
      expect(find.text('Looking for sub-folders…'), findsNothing);
      expect(find.text('Rock'), findsOneWidget);
      expect(find.textContaining('Rescan'), findsNothing);
    });

    _test('a failed read says so and Try again reads again', (tester) async {
      final catalog = _catalog(_failed);
      await pumpExclusion(tester, catalog);
      await _open(tester, SheetHost.openExclude);

      expect(find.text('Could not load the sub-folder list'), findsOneWidget);
      expect(find.text(_listFailedTitle), findsNothing);
      expect(find.textContaining('Rescan'), findsNothing);

      final reads = catalog.audioFolderReads;
      catalog.result = _withSubfolder;
      await tester.tap(find.text('Try again'));
      await frames(tester);
      expect(catalog.audioFolderReads, reads + 1);
      expect(find.text('Could not load the sub-folder list'), findsNothing);
      expect(find.text('Rock'), findsOneWidget);
      expect(catalog.refreshCalls, 0);
    });

    for (final (name, result) in [
      (
        'no sub-folder',
        const AudioFoldersListed([
          AudioFolderSummary(path: _music, audioCount: 10),
        ]),
      ),
      ('an empty index', _empty),
    ]) {
      _test('$name: the empty text and no Rescan', (tester) async {
        final catalog = _catalog(result);
        await pumpExclusion(tester, catalog);
        await _open(tester, SheetHost.openExclude);

        expect(
          find.text('There are no sub-folders to exclude.'),
          findsOneWidget,
        );
        expect(find.text(_noMusicTitle), findsNothing);
        expect(find.textContaining('Rescan'), findsNothing);
        expect(catalog.refreshCalls, 0);
      });
    }
  });

  group('text scale and motion', () {
    _test('every sheet state fits at 200 % text', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final catalog = _catalog(_empty);
      await _pump(tester, catalog, width: 412, height: 915);
      await _open(tester);
      await _see(tester, find.text(_noMusicTitle));
      expect(find.text(_noMusicTitle), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _startRescan(tester, catalog, 'Rescan');
      await _see(tester, find.text(_scanning));
      expect(find.text(_scanning), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _finish(tester, catalog, MediaIndexRefresh.done);
      await _see(tester, find.text(_stillNoMusicTitle));
      expect(find.text(_stillNoMusicTitle), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _startRescan(tester, catalog, 'Rescan');
      await _finish(tester, catalog, MediaIndexRefresh.failed);
      await _see(tester, find.text(_listFailedTitle));
      expect(find.text(_listFailedTitle), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _startRescan(tester, catalog, 'Try again');
      await _finish(tester, catalog, MediaIndexRefresh.done, result: _listed);
      await _see(tester, find.text(_foundBanner));
      expect(find.text(_foundBanner), findsOneWidget);
      await _see(tester, find.text('Download'));
      expect(find.text('Download'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _startRescan(tester, catalog, _rescanRow);
      await _see(tester, find.text(_scanning));
      expect(find.text(_scanning), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    _test('with animations off the sheet settles while it scans', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final catalog = _catalog(_empty);
      await _pump(tester, catalog);
      await tester.tap(find.text(SheetHost.openAdd));
      await tester.pumpAndSettle();
      catalog.refreshGate = Completer<MediaIndexRefresh>();
      await tester.tap(find.text('Rescan'));
      // Would never return with the bar animating.
      await tester.pumpAndSettle();
      expect(find.text(_scanning), findsOneWidget);
    });
  });
}
