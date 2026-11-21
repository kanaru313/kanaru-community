import 'package:flutter/widgets.dart' show Scrollable;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kanaru/src/library/ui/songs/song_list.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/state/now_playing_panel.dart';
import 'package:kanaru/src/playback/state/playback_position_provider.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/playback/ui/mini_player.dart';
import 'package:kanaru/src/router/state/router_provider.dart';
import 'package:kanaru/src/screens/now_playing/now_playing_path.dart';
import 'package:kanaru/src/screens/now_playing/ui/now_playing_page.dart';

import 'support/harness.dart';

/// The real app on the fixture library: the scan lists the fixture songs,
/// tapping one plays it for real, and Now Playing opens.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('scan, play a song, open Now Playing', (tester) async {
    final app = await startKanaru(tester);
    final container = app.container;
    const title = 'IT Uslt Tag';

    final scrollable = find
        .descendant(
          of: find.byType(SongList),
          matching: find.byType(Scrollable),
        )
        .first;

    // Other music may share the list (the phone's library): scroll down, then
    // back up, until the title is built.
    Future<void> reveal(String text) async {
      final target = find.text(text);
      for (var step = 0; step < 80; step++) {
        if (target.evaluate().isNotEmpty) return;
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable, Offset(0, step < 40 ? -300 : 300));
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
      }
      throw TestFailure('song "$text" is not in the Songs list');
    }

    // The songs list shows the fixture titles.
    for (final t in const ['IT Sylt Tag', 'IT No Lyrics']) {
      await reveal(t);
      expect(find.text(t), findsWidgets, reason: 'song "$t" is listed');
    }
    final row = find.text(title);
    await reveal(title);

    // Tapping a row plays that track through the real engine.
    final id = TrackId((await app.trackIdsByTitle())[title]!);
    final position = container.listen(playbackPositionProvider, (_, _) {});
    addTearDown(position.close);
    await tester.tap(row);
    await app.pumpUntil(
      () =>
          container.read(nowPlayingProvider).value?.trackId == id &&
          container.read(isPlayingProvider),
      what: 'the tapped track to be playing',
    );
    final started = position.read().value?.position ?? Duration.zero;
    await app.pumpUntil(
      () =>
          (position.read().value?.position ?? Duration.zero) >
          started + const Duration(milliseconds: 500),
      what: 'the playback position to advance',
      timeout: const Duration(seconds: 20),
    );

    // Now Playing opens from the player: the mini player on the mobile
    // shell; on the desktop shell the panel is opened through its notifier
    // (the player bar's own button is covered by the widget tests).
    if (find.byType(MiniPlayer).evaluate().isNotEmpty) {
      await tester.tap(find.byType(MiniPlayer));
      await app.pumpUntil(
        () =>
            container.read(routerProvider).state.uri.path == nowPlayingPath &&
            find.byType(NowPlayingPage).evaluate().isNotEmpty,
        what: 'the Now Playing page',
      );
    } else {
      container.read(nowPlayingPanelProvider.notifier).open();
      await app.pumpUntil(
        () => container.read(nowPlayingPanelProvider).covered,
        what: 'the Now Playing panel to open',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 4)));
}
