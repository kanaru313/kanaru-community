import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/data/playlists/playlist_repository.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_import.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/state/m3u/m3u_import_progress.dart';
import 'package:kanaru/src/library/state/m3u/m3u_providers.dart';
import 'package:kanaru/src/library/ui/m3u/m3u_import_flow.dart';
import 'package:kanaru/src/platform/domain/document_picker.dart';
import 'package:kanaru/src/storage/domain/m3u/m3u_limits.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../database/support/test_db.dart';
import 'support/m3u_flow_harness.dart';

/// Fails the write of an imported playlist, like a database error would.
class _FailingStore extends PlaylistRepository {
  _FailingStore(super.db);

  static final error = StateError('disk full');

  @override
  Future<ImportedPlaylist> createImportedPlaylist({
    required String name,
    required List<ImportedEntry> entries,
  }) => throw error;
}

/// Runs the body, then lets the toast and route animations finish.
void flowTest(String name, Future<void> Function(WidgetTester t) body) =>
    testWidgets(name, (t) async {
      await body(t);
      await t.pumpAndSettle(const Duration(seconds: 5));
    });

Future<List<PlaylistSummary>> _playlists(
  WidgetTester t,
  M3uFlowHarness h,
) async =>
    (await t.runAsync(() => h.env.repo.watchSummaries().first))!.playlists;

/// Picks a list called [name] holding [text].
void _pick(M3uFlowHarness h, String text, {String name = 'Road.m3u8'}) {
  h.picker.onOpen = () async => h.env.list(text, name: name);
}

Future<void> _songIn(WidgetTester t, M3uFlowHarness h, String rel) async {
  h.env.file(rel);
  await t.runAsync(() => addTrack(h.env.db, h.env.source, locator: rel));
}

Future<void> _settleToast(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
}

void main() {
  void noProgressLeft(M3uFlowHarness h) {
    expect(h.container.read(m3uImportProgressProvider), isNull);
    expect(h.container.read(m3uImportBusyProvider), isFalse);
  }

  flowTest('cancelled dialog: nothing shown, nothing created', (t) async {
    final h = await M3uFlowHarness.pump(t);
    final flow = h.start(t, runM3uImport);
    await h.untilDone(t, flow);
    await _settleToast(t);
    expect(h.picker.opens, 1);
    expect(h.picker.openFilter!.matchesName('a.M3U8'), isTrue);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(await _playlists(t, h), isEmpty);
    noProgressLeft(h);
  });

  flowTest('clean import: toast and the new playlist page', (t) async {
    final h = await M3uFlowHarness.pump(t);
    await _songIn(t, h, 'a.mp3');
    await _songIn(t, h, 'b.mp3');
    _pick(h, '${h.env.music}/a.mp3\n${h.env.music}/b.mp3\n');
    final flow = h.start(t, runM3uImport);
    await h.untilDone(t, flow);
    await _settleToast(t);
    final created = (await _playlists(t, h)).single;
    expect(created.name, 'Road');
    expect(h.location(), '/playlists/${created.uid}');
    expect(find.text(h.l10n(t).playlistM3uImported(2, 'Road')), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    noProgressLeft(h);
  });

  group('some lines unusable', () {
    Future<M3uFlowHarness> mixed(WidgetTester t) async {
      final h = await M3uFlowHarness.pump(t);
      await _songIn(t, h, 'a.mp3');
      _pick(h, '${h.env.music}/a.mp3\n${h.env.music}/typo.mp3\n');
      return h;
    }

    flowTest('the report shows on the current page; Close stays', (t) async {
      final h = await mixed(t);
      final l10n = h.l10n(t);
      final flow = h.start(t, runM3uImport);
      await h.untilFound(t, find.text(l10n.playlistM3uReportTitle));
      expect(find.text(l10n.playlistM3uReportUnresolved(1)), findsOneWidget);
      expect(
        find.text(l10n.playlistM3uReportLine(2, '${h.env.music}/typo.mp3')),
        findsOneWidget,
      );
      expect(h.location(), '/');
      expect(flow.done, isFalse, reason: 'waits for the dialog');
      await t.tap(find.text(l10n.playlistClose));
      await h.untilDone(t, flow);
      await t.pumpAndSettle();
      expect(h.location(), '/');
      expect(await _playlists(t, h), hasLength(1));
      noProgressLeft(h);
    });

    flowTest('Open playlist goes to the new playlist', (t) async {
      final h = await mixed(t);
      final l10n = h.l10n(t);
      final flow = h.start(t, runM3uImport);
      await h.untilFound(t, find.text(l10n.playlistM3uOpenPlaylist));
      await t.tap(find.text(l10n.playlistM3uOpenPlaylist));
      await h.untilDone(t, flow);
      await t.pumpAndSettle();
      final uid = (await _playlists(t, h)).single.uid;
      expect(h.location(), '/playlists/$uid');
      expect(find.text('PAGE $uid'), findsOneWidget);
    });
  });

  group('errors are toasts and create nothing', () {
    Future<void> expectToast(
      WidgetTester t,
      M3uFlowHarness h,
      String Function() text,
    ) async {
      final flow = h.start(t, runM3uImport);
      await h.untilDone(t, flow);
      await _settleToast(t);
      expect(find.text(text()), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(await _playlists(t, h), isEmpty);
      expect(h.location(), '/');
      noProgressLeft(h);
    }

    flowTest('too large', (t) async {
      final h = await M3uFlowHarness.pump(t);
      final path = '${h.env.tmp}/lists/Big.m3u8';
      h.picker.inner.files[path] = Uint8List(m3uMaxBytes + 1);
      h.picker.onOpen = () async =>
          PickedDocument(name: 'Big.m3u8', handle: path, localPath: path);
      await expectToast(t, h, () => h.l10n(t).playlistM3uTooLarge);
    });

    flowTest('not a playlist file', (t) async {
      final h = await M3uFlowHarness.pump(t);
      _pick(h, 'x', name: 'notes.txt');
      await expectToast(t, h, () => h.l10n(t).playlistM3uReadFailed);
    });

    flowTest('unreadable', (t) async {
      final h = await M3uFlowHarness.pump(t);
      h.picker.onOpen = () async => const PickedDocument(
        name: 'gone.m3u',
        handle: '/nowhere/gone.m3u',
        localPath: '/nowhere/gone.m3u',
      );
      await expectToast(t, h, () => h.l10n(t).playlistM3uReadFailed);
    });

    flowTest('no song found', (t) async {
      final h = await M3uFlowHarness.pump(t);
      _pick(h, '${h.env.music}/typo.mp3\n');
      await expectToast(t, h, () => h.l10n(t).playlistM3uNothingFound);
    });

    flowTest('every usable line outside the music folders', (t) async {
      final h = await M3uFlowHarness.pump(t);
      final outside = h.env.file('o.mp3', under: '${h.env.tmp}/lists');
      _pick(h, '$outside\n');
      await expectToast(t, h, () => h.l10n(t).playlistM3uAllOutside);
    });

    flowTest('the file dialog fails', (t) async {
      final h = await M3uFlowHarness.pump(t);
      h.picker.onOpen = () async =>
          throw const DocumentPickerException(DocumentPickerFailure.failed);
      await expectToast(t, h, () => h.l10n(t).m3uImportFailed);
    });
  });

  group('an unexpected error', () {
    late List<LogRecord> records;
    late Level oldLevel;
    late StreamSubscription<LogRecord> sub;

    setUp(() {
      oldLevel = Logger.root.level;
      Logger.root.level = Level.ALL;
      records = [];
      sub = Logger.root.onRecord.listen(records.add);
    });
    tearDown(() async {
      await sub.cancel();
      Logger.root.level = oldLevel;
    });

    Future<void> expectFailsThenWorks(
      WidgetTester t,
      M3uFlowHarness h,
      Object cause,
    ) async {
      _pick(h, '${h.env.music}/a.mp3\n');
      final flow = h.start(t, runM3uImport);
      await h.untilDone(t, flow);
      await _settleToast(t);
      expect(find.text(h.l10n(t).m3uImportFailed), findsOneWidget);
      expect(await _playlists(t, h), isEmpty);
      final logged = records.where((r) => r.level >= Level.SEVERE);
      expect(logged, hasLength(1));
      expect(logged.single.error, same(cause));
      expect(logged.single.stackTrace, isNotNull);
      expect(h.container.read(m3uImportBusyProvider), isFalse);
      expect(h.container.read(m3uImportProgressProvider), isNull);
      // The guard is free again: a second flow runs.
      h.picker.onOpen = () async => null;
      final again = h.start(t, runM3uImport);
      await h.untilDone(t, again);
      expect(h.picker.opens, 2);
    }

    flowTest('a store that throws: toast, logged with stack, guard reset', (
      t,
    ) async {
      final h = await M3uFlowHarness.pump(
        t,
        store: (env) => _FailingStore(env.db),
      );
      await _songIn(t, h, 'a.mp3');
      await expectFailsThenWorks(t, h, _FailingStore.error);
    });

    flowTest('a parse failure: toast, logged with stack, guard reset', (
      t,
    ) async {
      final cause = FormatException('bad');
      final h = await M3uFlowHarness.pump(
        t,
        importService: (env, picker) =>
            ThrowingImportService(env, picker, cause),
      );
      await expectFailsThenWorks(t, h, cause);
    });
  });

  group('the progress card never sits next to the result', () {
    /// Starts a slow import and returns once its card shows.
    Future<FlowRun> startSlow(
      WidgetTester t,
      M3uFlowHarness h,
      Completer<void> gate,
    ) async {
      h.picker.readGate = gate;
      final flow = h.start(t, runM3uImport);
      await h.until(
        t,
        () => h.container.read(m3uImportProgressProvider) != null,
        what: 'the import to begin',
      );
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Importing Road.m3u8'), findsOneWidget);
      return flow;
    }

    flowTest('report dialog', (t) async {
      final h = await M3uFlowHarness.pump(t);
      await _songIn(t, h, 'a.mp3');
      _pick(h, '${h.env.music}/a.mp3\n${h.env.music}/typo.mp3\n');
      final gate = Completer<void>();
      final flow = await startSlow(t, h, gate);
      gate.complete();
      await h.untilFound(t, find.text(h.l10n(t).playlistM3uReportTitle));
      expect(find.text('Importing Road.m3u8'), findsNothing);
      await t.tap(find.text(h.l10n(t).playlistClose));
      await h.untilDone(t, flow);
    });

    flowTest('error toast', (t) async {
      final h = await M3uFlowHarness.pump(t);
      _pick(h, '${h.env.music}/typo.mp3\n');
      final gate = Completer<void>();
      final flow = await startSlow(t, h, gate);
      gate.complete();
      await h.untilFound(t, find.text(h.l10n(t).playlistM3uNothingFound));
      expect(find.text('Importing Road.m3u8'), findsNothing);
      await h.untilDone(t, flow);
    });
  });

  flowTest('another dialog is open: ignored quietly, next tap works', (
    t,
  ) async {
    final h = await M3uFlowHarness.pump(t);
    h.picker.onOpen = () async =>
        throw const DocumentPickerException(DocumentPickerFailure.busy);
    final flow = h.start(t, runM3uImport);
    await h.untilDone(t, flow);
    await _settleToast(t);
    expect(find.byType(SnackBar), findsNothing);
    noProgressLeft(h);
    h.picker.onOpen = () async => null;
    final again = h.start(t, runM3uImport);
    await h.untilDone(t, again);
    expect(h.picker.opens, 2);
  });

  flowTest('a picker that never answers shows nothing; a second tap is '
      'ignored; after null the next tap works', (t) async {
    final h = await M3uFlowHarness.pump(t);
    final answer = Completer<PickedDocument?>();
    h.picker.onOpen = () => answer.future;
    final first = h.start(t, runM3uImport);
    final second = h.start(t, runM3uImport);
    await h.untilDone(t, second);
    await _settleToast(t);
    expect(h.picker.opens, 1, reason: 'the double tap is ignored');
    expect(first.done, isFalse);
    expect(find.byType(SnackBar), findsNothing);
    expect(h.container.read(m3uImportProgressProvider), isNull);

    answer.complete(null);
    await h.untilDone(t, first);
    h.picker.onOpen = () async => null;
    final third = h.start(t, runM3uImport);
    await h.untilDone(t, third);
    expect(h.picker.opens, 2);
  });

  flowTest('the page closes while the dialog is open: toast still shows', (
    t,
  ) async {
    final h = await M3uFlowHarness.pump(t);
    final l10n = h.l10n(t);
    unawaited(h.router.push<void>('/playlists/x'));
    await t.pumpAndSettle();
    final answer = Completer<PickedDocument?>();
    h.picker.onOpen = () => answer.future;
    final flow = h.start(
      t,
      (_) => runM3uImport(t.element(find.text('PAGE x'))),
    );
    h.router.pop();
    await t.pumpAndSettle();
    expect(find.text('PAGE x'), findsNothing);
    answer.complete(h.env.list('${h.env.music}/typo.mp3\n'));
    await h.untilDone(t, flow);
    await _settleToast(t);
    expect(find.text(l10n.playlistM3uNothingFound), findsOneWidget);
    noProgressLeft(h);
  });

  flowTest('progress starts after the file was picked, ends before the toast', (
    t,
  ) async {
    final h = await M3uFlowHarness.pump(t);
    final answer = Completer<PickedDocument?>();
    h.picker.onOpen = () => answer.future;
    final seen = <String?>[];
    h.container.listen(m3uImportProgressProvider, (_, next) {
      seen.add(next?.fileName);
    });
    final flow = h.start(t, runM3uImport);
    await t.pump(const Duration(seconds: 2));
    expect(seen, isEmpty, reason: 'the system dialog time never counts');
    answer.complete(h.env.list('${h.env.music}/typo.mp3\n', name: 'Q.m3u'));
    await h.untilDone(t, flow);
    expect(seen.first, 'Q.m3u');
    expect(seen.last, isNull);
  });
}
