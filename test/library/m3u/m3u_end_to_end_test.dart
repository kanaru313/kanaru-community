import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/extension/state/extension_providers.dart';
import 'package:kanaru/src/library/data/m3u/m3u_export_service.dart';
import 'package:kanaru/src/library/data/m3u/m3u_import_service.dart';
import 'package:kanaru/src/library/data/m3u/m3u_results.dart';
import 'package:kanaru/src/library/data/m3u/m3u_scan_rules.dart';
import 'package:kanaru/src/library/state/m3u/m3u_import_progress.dart';
import 'package:kanaru/src/library/state/m3u/m3u_providers.dart';
import 'package:kanaru/src/library/state/playlists/playlist_providers.dart';
import 'package:kanaru/src/library/ui/m3u/m3u_import_progress_card.dart';
import 'package:kanaru/src/library/ui/playlists/playlists_page.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/platform/domain/document_picker.dart';
import 'package:kanaru/src/platform/state/document_picker_provider.dart';
import 'package:kanaru/src/platform/state/file_manager_provider.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';

import '../../database/support/test_db.dart';
import '../../support/fake_playback_commands.dart';
import '../ui/playlists/support/playlist_menu_support.dart';
import '../ui/playlists/support/playlist_ui_harness.dart';
import '../ui/playlists/support/playlists_page_support.dart';
import '../../support/icon_button_finders.dart';
import 'support/m3u_env.dart';
import 'support/m3u_fixtures.dart';
import 'support/m3u_flow_harness.dart';

/// The real playlists page over an in-memory database with a music folder,
/// a scripted picker and the real M3U services.
class _Page {
  _Page(this.h, this.picker, this.tmp);

  final PlaylistUiHarness h;
  final FlowPicker picker;
  final String tmp;

  String get music => '$tmp/music';
  String get lists => '$tmp/lists';
}

Future<_Page> _pumpPage(WidgetTester t) async {
  final picker = FlowPicker(FakePicker());
  final root = Directory.systemTemp.createTempSync('m3u_e2e');
  addTearDown(() => root.deleteSync(recursive: true));
  final tmp = root.resolveSymbolicLinksSync();
  Directory('$tmp/music').createSync();
  Directory('$tmp/lists').createSync();
  final h = await PlaylistUiHarness.pump(
    t,
    listBuilder: (_) => const PlaylistsPage(),
    overrides: [
      extensionRegistryProvider.overrideWithValue(hubRegistry()),
      fileManagerProvider.overrideWithValue(NoFileManager()),
      playbackCommandsProvider.overrideWithValue(FakePlaybackCommands()),
      documentPickerProvider.overrideWithValue(picker),
      m3uImportServiceProvider.overrideWith(
        (ref) => M3uImportService(
          ref.watch(appDatabaseProvider),
          ref.watch(playlistStoreProvider),
          picker,
          realPath,
          FakeScans(),
          const ShortTrackRule.off(),
          androidStorage: false,
        ),
      ),
      m3uExportServiceProvider.overrideWith(
        (ref) =>
            M3uExportService(ref.watch(appDatabaseProvider), picker, realPath),
      ),
    ],
  );
  final source = (await t.runAsync(() async {
    final id = await addSource(
      h.fixture.db,
      uid: 'src-e2e',
      root: '$tmp/music',
    );
    await addMount(h.fixture.db, id, root: '$tmp/music');
    return id;
  }))!;
  File('$tmp/music/a.mp3').createSync();
  File('$tmp/music/b.mp3').createSync();
  await t.runAsync(() async {
    await addTrack(h.fixture.db, source, locator: 'a.mp3');
    await addTrack(h.fixture.db, source, locator: 'b.mp3');
  });
  unawaited(h.router.push<void>('/playlists'));
  await settlePage(t);
  return _Page(h, picker, tmp);
}

void _pickList(_Page p, String text, {String name = 'Road trip.m3u'}) {
  final path = '${p.lists}/$name';
  File(path).writeAsStringSync(text);
  p.picker.inner.put(path, text);
  p.picker.onOpen = () async =>
      PickedDocument(name: name, handle: path, localPath: path);
}

Future<void> _openFabImport(WidgetTester t) async {
  final l10n = pageL10n(t);
  await t.tap(find.byTooltip(l10n.playlistFabOpen));
  await settlePage(t);
  await t.tap(find.text(l10n.playlistFabImport));
}

/// Real-time wait (the flows do database and file work) until [done].
Future<void> _until(WidgetTester t, bool Function() done, String what) async {
  final end = DateTime.now().add(const Duration(seconds: 10));
  while (!done()) {
    if (DateTime.now().isAfter(end)) fail('timed out waiting for $what');
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await t.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  pageTest('FAB › import M3U creates the playlist and toasts', (t) async {
    final p = await _pumpPage(t);
    final l10n = pageL10n(t);
    _pickList(p, '#EXTM3U\n${p.music}/a.mp3\n${p.music}/b.mp3\n');
    await _openFabImport(t);
    await _until(
      t,
      () => find
          .text(l10n.playlistM3uImported(2, 'Road trip'))
          .evaluate()
          .isNotEmpty,
      'the import toast',
    );
    final lists = await t.runAsync(
      () => p.h.fixture.repo.watchSummaries().first,
    );
    expect(lists!.playlists.map((e) => e.name), contains('Road trip'));
    await t.pump(const Duration(seconds: 6));
  });

  pageTest('a slow import shows the progress card, gone with the result', (
    t,
  ) async {
    final p = await _pumpPage(t);
    final l10n = pageL10n(t);
    _pickList(p, '#EXTM3U\n${p.music}/a.mp3\n');
    final gate = Completer<void>();
    p.picker.readGate = gate;
    await _openFabImport(t);
    await t.pump(const Duration(milliseconds: 300));
    expect(
      find.byType(M3uImportProgressCard, skipOffstage: false),
      findsOneWidget,
    );
    // Not yet a second: the card draws nothing.
    expect(
      find.text(l10n.m3uImportProgressTitle('Road trip.m3u')),
      findsNothing,
    );

    await t.pump(const Duration(seconds: 1));
    expect(
      find.text(l10n.m3uImportProgressTitle('Road trip.m3u')),
      findsOneWidget,
    );
    // The importer reports no total while the read is gated (the total comes
    // from the resolver, after the read), so the progress state is driven here.
    p.h.container
        .read(m3uImportProgressProvider.notifier)
        .update(
          const M3uImportProgress(fileName: 'Road trip.m3u', done: 2, total: 5),
        );
    await t.pump();
    expect(find.text(l10n.m3uImportProgressLines(2, 5)), findsOneWidget);
    // The card is the first sliver: its top is the scroll view's top, so it
    // sits above the hub, the list bar and every playlist row.
    expect(
      t.getTopLeft(find.byType(M3uImportProgressCard)).dy,
      t.getTopLeft(find.byType(CustomScrollView)).dy,
    );

    gate.complete();
    await _until(
      t,
      () => find
          .text(l10n.playlistM3uImported(1, 'Road trip'))
          .evaluate()
          .isNotEmpty,
      'the import toast',
    );
    expect(
      find.text(l10n.m3uImportProgressTitle('Road trip.m3u')),
      findsNothing,
    );
    await t.pump(const Duration(seconds: 6));
  });

  pageTest('Advanced › Export M3U from the card menu writes the file', (
    t,
  ) async {
    final p = await _pumpPage(t);
    final l10n = pageL10n(t);
    final out = '${p.lists}/Mix.m3u8';
    await t.runAsync(() async {
      final ids = [
        for (final r
            in await p.h.fixture.db.select(p.h.fixture.db.tracks).get())
          TrackId(r.id),
      ];
      await p.h.fixture.repo.createPlaylist(name: 'Mix', tracks: ids);
    });
    await _until(
      t,
      () => find.text('Mix').evaluate().isNotEmpty,
      'the playlist',
    );
    p.picker.onCreate = (name) async =>
        SaveTarget(name: name, handle: out, localPath: out, exists: false);

    await t.longPress(find.text('Mix'));
    await settlePage(t);
    await t.tap(find.text(l10n.libraryMenuAdvanced));
    await settlePage(t);
    await t.tap(find.text(l10n.playlistMenuExportM3u));
    await _until(t, () => File(out).existsSync(), 'the exported file');
    await _until(
      t,
      () => find
          .text(l10n.playlistM3uExported(2, 'Mix.m3u8'))
          .evaluate()
          .isNotEmpty,
      'the export toast',
    );
    final text = File(out).readAsStringSync();
    expect(text, contains('${p.music}/a.mp3'));
    expect(text, contains('${p.music}/b.mp3'));
    expect(byIconButton(l10n.libraryMenuMore), findsNothing);
    await t.pump(const Duration(seconds: 6));
  });
}
