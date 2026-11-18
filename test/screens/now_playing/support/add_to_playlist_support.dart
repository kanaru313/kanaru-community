import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/data/playlists/playlist_repository.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/screens/now_playing/ui/now_playing_page.dart';
import 'package:go_router/go_router.dart';

import '../../../library/ui/add_to_playlist/support/flow_harness.dart';
import '../../../library/ui/add_to_playlist/support/picker_host.dart';
import '../../../playback/support/ui_host.dart';

export '../../../library/ui/add_to_playlist/support/flow_harness.dart'
    show pumpUntil, pumpUntilFound, pressAdd, tick, toast;

/// Now Playing as its own route, for hosts that push it over a home page.
final nowPlayingRoutes = <RouteBase>[
  GoRoute(
    path: '/now-playing',
    builder: (context, state) => const NowPlayingPage(),
  ),
];

/// Creates a playlist named [name] holding [tracks] and returns its uid.
Future<String> createPlaylist(
  WidgetTester tester,
  UiHost host,
  String name, [
  List<TrackId> tracks = const [],
]) async {
  late String uid;
  await host.run(tester, () async {
    uid = await PlaylistRepository(host.h.db)
        .createPlaylist(name: name, tracks: tracks);
  });
  return uid;
}

/// Track ids held by the playlist [uid] in playlist order, tombstones left out.
Future<List<int>> heldTracks(
  WidgetTester tester,
  UiHost host,
  String uid,
) async {
  late List<int> ids;
  await tester.runAsync(() async {
    final rows = await host.h.db
        .customSelect(
          'SELECT e.track_id FROM playlist_entries e '
          'JOIN playlists p ON p.id = e.playlist_id '
          'WHERE p.uid = ? AND e.deleted_at IS NULL '
          'ORDER BY e.sort_key, e.uid',
          variables: [Variable.withString(uid)],
        )
        .get();
    ids = [for (final r in rows) r.read<int>('track_id')];
  });
  return ids;
}

/// Waits for the picker to show, then lets it finish sliding in. Its "New
/// playlist…" row is the signal: the title is also the label of the menu
/// items that open it.
Future<void> waitForPicker(WidgetTester tester) async {
  await pumpUntilFound(tester, find.text('New playlist…'));
  await settle(tester);
}

/// Whether the picker is on screen and reachable (not under another route).
bool pickerReachable() => toast('New playlist…');

/// Cancels the picker and waits for it to leave.
Future<void> cancelPicker(WidgetTester tester) async {
  await tester.tap(find.text(l10nOf('en').playlistCancel));
  await settle(tester);
}

/// Lets sheets and dialogs finish sliding. Now Playing never goes idle (the
/// progress and cover animations run), so `pumpAndSettle` would time out.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Ends a test that added songs: lets the toast time out and the database
/// streams of the picker close, so no timer outlives the widget tree.
Future<void> drainAfterAdd(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump(const Duration(seconds: 1));
}
