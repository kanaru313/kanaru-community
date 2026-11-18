import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/add_to_playlist/add_to_playlist.dart';
import 'package:kanaru/src/playback/ui/queue/queue_header.dart';
import 'package:kanaru/src/screens/now_playing/ui/queue_host.dart';
import 'package:kanaru/src/screens/now_playing/ui/queue_panel.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../playback/support/controller_harness.dart' show ctx;
import '../../playback/support/ui_host.dart';
import '../../support/icon_button_finders.dart';
import 'support/add_to_playlist_support.dart';

final _save = byIconButton('Save as playlist');

bool _saveEnabled(WidgetTester tester) =>
    tester.widget<KIconButton>(_save).onPressed != null;

Future<UiHost> _pump(
  WidgetTester tester,
  QueueHost kind, {
  bool play = true,
}) async {
  addTearDown(resetAddToPlaylistGuard);
  return pumpWithPlayer(
    tester,
    QueuePanel(host: kind),
    size: kind == QueueHost.sheet ? const Size(400, 800) : const Size(900, 800),
    play: play,
  );
}

/// Queues the harness tracks at [indexes] (a track may repeat).
Future<void> _queue(WidgetTester tester, UiHost host, List<int> indexes) =>
    host.run(
      tester,
      () => host.h.c.playTracks([
        for (final i in indexes) host.h.tracks[i],
      ], context: ctx),
    );

Future<void> _newPlaylist(WidgetTester tester, String name) async {
  await tick(tester, 'New playlist…');
  await settle(tester);
  await tester.enterText(find.byType(TextField).last, name);
  await tester.tap(find.text('Add to list'));
  await settle(tester);
}

void main() {
  for (final kind in QueueHost.values) {
    group('${kind.name} head', () {
      testWidgets('Save is enabled with a queue and opens the picker', (
        tester,
      ) async {
        await _pump(tester, kind);
        expect(_saveEnabled(tester), isTrue);
        expect(find.text('Coming soon'), findsNothing);

        await tester.tap(_save);
        await tester.pump();
        await waitForPicker(tester);
        expect(find.text('6 songs · from the queue'), findsOneWidget);
        expect(pickerReachable(), isTrue);

        await cancelPicker(tester);
        expect(find.text('New playlist…'), findsNothing);
        expect(find.byType(QueueCounts), findsOneWidget);
      });

      testWidgets('Save is disabled while the queue is empty', (tester) async {
        await _pump(tester, kind, play: false);
        expect(_saveEnabled(tester), isFalse);
      });

      testWidgets('a queue of 5 with a repeat is saved as 5 entries in order', (
        tester,
      ) async {
        final host = await _pump(tester, kind, play: false);
        await _queue(tester, host, [2, 0, 3, 0, 1]);
        expect(_saveEnabled(tester), isTrue);

        await tester.tap(_save);
        await tester.pump();
        await waitForPicker(tester);
        expect(find.text('4 songs · from the queue'), findsOneWidget);

        await _newPlaylist(tester, 'Road trip');
        await pressAdd(tester);
        // The picker counts distinct songs; the playlist keeps every entry.
        await pumpUntil(tester, () => toast('Added 4 songs to “Road trip”'));

        final t = host.h.tracks;
        final uid = (await tester.runAsync(
          () => host.h.db
              .customSelect(
                "SELECT uid FROM playlists WHERE name = 'Road trip'",
              )
              .getSingle(),
        ))!.read<String>('uid');
        expect(await heldTracks(tester, host, uid), [
          for (final i in [2, 0, 3, 0, 1]) t[i].value,
        ]);
        await drainAfterAdd(tester);
      });
    });
  }

  testWidgets('the toast of a save from the queue sheet is visible above it', (
    tester,
  ) async {
    addTearDown(resetAddToPlaylistGuard);
    final host = await pumpWithPlayer(
      tester,
      const Text('home'),
      routes: nowPlayingRoutes,
      size: const Size(390, 844),
    );
    host.router!.push('/now-playing');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await host.letStreamsArrive(tester);
    await tester.tap(byIconButton('Queue'));
    await tester.pump();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await host.letStreamsArrive(tester);
    final uid = await createPlaylist(tester, host, 'Chill');

    await tester.tap(_save);
    await tester.pump();
    await waitForPicker(tester);
    await tick(tester, 'Chill');
    await pressAdd(tester);
    await pumpUntil(
      tester,
      () => toast('Added 6 songs to “Chill”'),
      reason: 'a toast that can be reached above the sheet',
    );

    expect((await heldTracks(tester, host, uid)).length, 6);
    await drainAfterAdd(tester);
  });
}
