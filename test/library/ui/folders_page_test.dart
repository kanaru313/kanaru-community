import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/list_view_prefs.dart';
import 'package:kanaru/src/library/domain/music_folder.dart';
import 'package:kanaru/src/library/state/browse/list_prefs_providers.dart';
import 'package:kanaru/src/library/ui/folders/folder_locations.dart';
import 'package:kanaru/src/library/ui/folders/folder_tile.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/platform/domain/storage_volumes.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/fake_playback_commands.dart';
import '../browse/support/library_fixture.dart';
import 'support/library_harness.dart';
import 'support/ui_harness.dart';

const _home = StorageVolume(root: '/home/u', kind: StorageVolumeKind.home);
const _sd = StorageVolume(
  root: '/storage/ABCD',
  kind: StorageVolumeKind.sdCard,
);

/// A music folder `Music` with:
///   Album A/01.flac, Album A/02.flac
///   V-Pop/Singles/Deep/a.flac            (V-Pop and Singles hold no file)
///   V-Pop/Singles/Deep/b.flac
///   loose.flac
Future<(LibraryHarness, MusicFolder)> _single(
  WidgetTester tester, {
  FakePlaybackCommands? playback,
  String initial = '/library/folders',
  double width = 390,
}) async {
  final h = await pumpLibrary(
    tester,
    initial: initial,
    playback: playback,
    width: width,
    height: width > 1000 ? 800 : 844,
  );
  final folder = await h.addFolder(
    'Music',
    volume: _home,
    root: '/home/u/Music',
  );
  Future<void> add(String locator) => addLibraryTrack(
    h.db,
    source: folder.sourceId,
    locator: locator,
    title: locator.split('/').last,
  );
  await add('Album A/01.flac');
  await add('Album A/02.flac');
  await add('V-Pop/Singles/Deep/a.flac');
  await add('V-Pop/Singles/Deep/b.flac');
  await add('loose.flac');
  await h.settle(tester);
  return (h, folder);
}

Future<void> _settle(WidgetTester tester, LibraryHarness h) async {
  await h.settle(tester, rounds: 4);
}

String _at(MusicFolder folder, String key) =>
    FolderLocation(sourceUid: folder.sourceUid, key: key).path;

void main() {
  testWidgets('one music folder opens into it: folders first, then its songs', (
    tester,
  ) async {
    final (h, _) = await _single(tester);
    expect(find.byType(FolderTile), findsNWidgets(2));
    // "V-Pop" holds no file and has one subfolder: a chain down to Deep.
    expect(find.text('V-Pop › Singles › Deep'), findsOneWidget);
    expect(find.text('Album A'), findsOneWidget);
    expect(find.text('2 songs · 0 folders'), findsNWidgets(2));
    expect(find.text('Songs in this folder · 1'), findsOneWidget);
    expect(h.songTitles(tester), ['loose.flac']);
    await unmountApp(tester);
  });

  testWidgets(
    'chains are one row, or one row per folder with the setting off',
    (tester) async {
      final (h, _) = await _single(tester);
      await h.container.read(compactFoldersProvider.notifier).set(false);
      await _settle(tester, h);
      expect(find.text('V-Pop'), findsOneWidget);
      expect(find.text('V-Pop › Singles › Deep'), findsNothing);
      await unmountApp(tester);
    },
  );

  testWidgets('a folder row opens its level in place; a chain opens its end', (
    tester,
  ) async {
    final (h, folder) = await _single(tester);
    await tester.tap(find.text('V-Pop › Singles › Deep'));
    await _settle(tester, h);
    expect(h.location, _at(folder, 'V-Pop/Singles/Deep'));
    expect(h.songTitles(tester), ['a.flac', 'b.flac']);
    expect(find.text('Songs in this folder · 2'), findsOneWidget);
    // Breadcrumb: deep path collapses on the mobile shell.
    expect(find.byTooltip('Hidden levels'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('a tap on a song plays the level with a folder context', (
    tester,
  ) async {
    final playback = FakePlaybackCommands();
    final (h, folder) = await _single(tester, playback: playback);
    await tester.tap(find.text('loose.flac'));
    await tester.pump();
    final call = playback.calls.single as PlayTracksCall;
    expect(call.tracks.length, 1);
    expect(call.context.kind, PlayContextKind.folder);
    expect(call.context.ref, '${folder.sourceUid}:');
    expect(h.playback, same(playback));
    await unmountApp(tester);
  });

  testWidgets('play and shuffle in a level use the songs below it', (
    tester,
  ) async {
    final playback = FakePlaybackCommands();
    final (h, _) = await _single(tester, playback: playback);
    await tester.tap(find.text('Play all'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    // Deep: 5 songs under the music folder.
    expect((playback.calls.single as PlayTracksCall).tracks.length, 5);
    await unmountApp(tester);
    expect(h.location, '/library/folders');
  });

  testWidgets('two music folders with one name: a list that tells them apart', (
    tester,
  ) async {
    final h = await pumpLibrary(tester, initial: '/library/folders');
    final a = await h.addFolder('Music', volume: _home, root: '/home/u/Music');
    final b = await h.addFolder(
      'Music',
      volume: _sd,
      root: '/storage/ABCD/Music',
    );
    await addLibraryTrack(h.db, source: a.sourceId, locator: 'x/1.flac');
    await addLibraryTrack(h.db, source: b.sourceId, locator: '1.flac');
    await addLibraryTrack(h.db, source: b.sourceId, locator: '2.flac');
    await h.settle(tester);
    expect(find.byType(FolderTile), findsNWidgets(2));
    expect(find.text('~/Music'), findsOneWidget);
    expect(find.text('SD card'), findsOneWidget);
    expect(find.text('2 songs · 0 folders'), findsOneWidget);
    expect(find.byIcon(KIcons.sdCard), findsOneWidget);
    await tester.tap(find.text('SD card'));
    await _settle(tester, h);
    expect(h.location, _at(b, ''));
    await unmountApp(tester);
  });

  testWidgets('Back climbs one level at a time, then leaves the tab', (
    tester,
  ) async {
    final h = await pumpLibrary(tester, initial: '/library/folders');
    final a = await h.addFolder('Music', volume: _home, root: '/home/u/Music');
    final other = await h.addFolder('Other', root: '/mnt/Other');
    await addLibraryTrack(h.db, source: a.sourceId, locator: 'A/B/C/x.flac');
    await addLibraryTrack(h.db, source: a.sourceId, locator: 'A/y.flac');
    await addLibraryTrack(h.db, source: other.sourceId, locator: 'z.flac');
    await h.settle(tester);
    // Top: the music folders.
    expect(h.location, '/library/folders');
    await tester.tap(find.text('Music'));
    await _settle(tester, h);
    await tester.tap(find.text('A'));
    await _settle(tester, h);
    await tester.tap(find.text('B › C'));
    await _settle(tester, h);
    expect(h.location, _at(a, 'A/B/C'));
    // "B" holds no file and only "C": it is part of a chain row, not a
    // level of its own, so Back goes straight to "A".
    await tester.binding.handlePopRoute();
    await _settle(tester, h);
    expect(h.location, _at(a, 'A'));
    await tester.binding.handlePopRoute();
    await _settle(tester, h);
    expect(h.location, _at(a, ''));
    await tester.binding.handlePopRoute();
    await _settle(tester, h);
    expect(h.location, '/library/folders');
    expect(find.text('Other'), findsOneWidget);
    // At the top of the tab Back is not handled: the app leaves.
    expect(await tester.binding.handlePopRoute(), isFalse);
    await unmountApp(tester);
  });

  testWidgets('opened from another page, Back climbs then returns to it', (
    tester,
  ) async {
    final h = await pumpLibrary(tester, initial: '/probe');
    final a = await h.addFolder('Music', volume: _home, root: '/home/u/Music');
    await addLibraryTrack(h.db, source: a.sourceId, locator: 'A/B/x.flac');
    await addLibraryTrack(h.db, source: a.sourceId, locator: 'A/y.flac');
    await addLibraryTrack(h.db, source: a.sourceId, locator: 'A/z.flac');
    await h.settle(tester);
    h.router.push(_at(a, 'A'));
    await tester.pumpAndSettle();
    await h.settle(tester, rounds: 1);
    await tester.tap(find.text('B'));
    await _settle(tester, h);
    expect(h.location, _at(a, 'A/B'));
    await tester.binding.handlePopRoute();
    await _settle(tester, h);
    expect(h.location, _at(a, 'A'));
    // The level it was opened at: Back now returns to the page below.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(h.location, '/probe');
    expect(find.text('probe page'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('a level that no longer exists opens its nearest ancestor', (
    tester,
  ) async {
    final h = await pumpLibrary(tester, initial: '/library/folders');
    final a = await h.addFolder('Music', volume: _home, root: '/home/u/Music');
    await addLibraryTrack(h.db, source: a.sourceId, locator: 'A/x.flac');
    await addLibraryTrack(h.db, source: a.sourceId, locator: 'A/Gone/y.flac');
    await h.settle(tester);
    h.router.go(_at(a, 'A/Gone'));
    await _settle(tester, h);
    expect(find.text('y.flac'), findsOneWidget);
    // Remove the folder's file: its level falls back to "A".
    await h.db.customUpdate(
      "UPDATE tracks SET status = 'missing', missing_since = 1 WHERE locator = 'A/Gone/y.flac'",
      updates: {h.db.tracks},
    );
    await h.settle(tester);
    expect(find.text('x.flac'), findsOneWidget);
    expect(find.text('y.flac'), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('the flat view lists folders with songs and opens one alone', (
    tester,
  ) async {
    final (h, folder) = await _single(tester);
    await tester.tap(find.byTooltip('Flat list'));
    await h.settle(tester, rounds: 2);
    expect(
      h.container.read(libraryListViewsProvider).folderView,
      FolderView.flat,
    );
    expect(find.text('3 folders'), findsOneWidget);
    expect(find.byType(FolderTile), findsNWidgets(3));
    // Rows: name, folders above, song count.
    expect(find.text('Music › V-Pop › Singles'), findsOneWidget);
    await tester.tap(find.text('Deep'));
    await _settle(tester, h);
    expect(
      h.location,
      FolderLocation(
        sourceUid: folder.sourceUid,
        key: 'V-Pop/Singles/Deep',
        flat: true,
      ).path,
    );
    expect(
      find.text('2 songs in this folder (not including subfolders)'),
      findsOneWidget,
    );
    expect(h.songTitles(tester), ['a.flac', 'b.flac']);
    expect(find.text('All folders'), findsOneWidget);
    // Back returns to the flat list.
    await tester.binding.handlePopRoute();
    await _settle(tester, h);
    expect(find.byType(FolderTile), findsNWidgets(3));
    await unmountApp(tester);
  });

  testWidgets('the flat list filters by name and by the folders above', (
    tester,
  ) async {
    final (h, _) = await _single(tester);
    await h.container
        .read(libraryListViewsProvider.notifier)
        .setFolderView(FolderView.flat);
    await _settle(tester, h);
    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'singles');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(FolderTile), findsOneWidget);
    expect(find.text('1 / 3 folders'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('with merging off Back steps through every folder', (
    tester,
  ) async {
    final h = await pumpLibrary(tester, initial: '/library/folders');
    final a = await h.addFolder('Music', volume: _home, root: '/home/u/Music');
    await addLibraryTrack(h.db, source: a.sourceId, locator: 'A/B/C/x.flac');
    await h.settle(tester);
    await h.container.read(compactFoldersProvider.notifier).set(false);
    await _settle(tester, h);
    for (final name in ['A', 'B', 'C']) {
      await tester.tap(find.text(name));
      await _settle(tester, h);
    }
    expect(h.location, _at(a, 'A/B/C'));
    for (final key in ['A/B', 'A', '']) {
      await tester.binding.handlePopRoute();
      await _settle(tester, h);
      expect(h.location, _at(a, key));
    }
    await unmountApp(tester);
  });

  testWidgets('Back never climbs past the level the page was opened at', (
    tester,
  ) async {
    final h = await pumpLibrary(tester, initial: '/probe');
    final a = await h.addFolder('Music', volume: _home, root: '/home/u/Music');
    // "X" holds no file and one subfolder: a link of a chain.
    await addLibraryTrack(h.db, source: a.sourceId, locator: 'X/Y/1.flac');
    await addLibraryTrack(h.db, source: a.sourceId, locator: 'X/Y/Z/2.flac');
    await addLibraryTrack(h.db, source: a.sourceId, locator: 'top.flac');
    await h.settle(tester);
    h.router.push(_at(a, 'X'));
    await tester.pumpAndSettle();
    await _settle(tester, h);
    await tester.tap(find.text('Y'));
    await _settle(tester, h);
    expect(h.location, _at(a, 'X/Y'));
    await tester.binding.handlePopRoute();
    await _settle(tester, h);
    expect(h.location, _at(a, 'X'));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(h.location, '/probe');
    await unmountApp(tester);
  });

  testWidgets('with the filter open Back closes it before climbing', (
    tester,
  ) async {
    final (h, folder) = await _single(tester);
    await tester.tap(find.text('Album A'));
    await _settle(tester, h);
    expect(h.location, _at(folder, 'Album A'));
    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await _settle(tester, h);
    expect(find.byType(TextField), findsNothing);
    expect(h.location, _at(folder, 'Album A'));
    await tester.binding.handlePopRoute();
    await _settle(tester, h);
    expect(h.location, _at(folder, ''));
    await unmountApp(tester);
  });

  testWidgets('a mobile folder row has its menu button and no chevron', (
    tester,
  ) async {
    await _single(tester);
    final tile = find.byType(FolderTile).first;
    expect(
      find.descendant(of: tile, matching: find.byIcon(KIcons.moreVert)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: tile, matching: find.byIcon(KIcons.chevronRight)),
      findsNothing,
    );
    await unmountApp(tester);
  });
}
