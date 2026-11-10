import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/ui/queue/queue_row.dart';
import 'package:kanaru/src/screens/now_playing/ui/desktop/lyrics_tab_placeholder.dart';
import 'package:kanaru/src/playback/state/now_playing_panel.dart';
import 'package:kanaru/src/shell/ui/player_bar.dart';
import 'package:material_ui/material_ui.dart';

import '../../../shell/support/desktop_now_playing_host.dart';

NowPlayingPanelState _state(DesktopHost host) =>
    host.container.read(nowPlayingPanelProvider);

Future<void> _settle(WidgetTester tester, [DesktopHost? host]) async {
  await tester.pump();
  await settleSlide(tester);
  await host?.letStreamsArrive(tester);
}

void main() {
  testWidgets('the right side is the lyrics, titled like one tab', (
    tester,
  ) async {
    final host = await pumpDesktopShell(tester);
    host.container.read(nowPlayingPanelProvider.notifier).open();
    await _settle(tester, host);
    expect(find.byType(LyricsTabPlaceholder), findsOneWidget);
    expect(find.text('Lyrics: coming soon'), findsOneWidget);
    // One tab, no Queue tab, and no queue rows inside Now Playing.
    expect(find.byType(Tab), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Lyrics'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Queue'), findsNothing);
    expect(find.byType(QueueRow), findsNothing);
  });

  testWidgets('the player bar Lyrics, cover and expand buttons open it', (
    tester,
  ) async {
    final host = await pumpDesktopShell(tester);
    expect(find.byType(PlayerBar), findsOneWidget);
    await tester.tap(find.byTooltip('Lyrics'));
    await _settle(tester, host);
    expect(_state(host).open, isTrue);
    expect(find.byType(LyricsTabPlaceholder), findsOneWidget);
    host.container.read(nowPlayingPanelProvider.notifier).close();
    await _settle(tester, host);
    await tester.tap(find.byTooltip('Open Now Playing').first);
    await _settle(tester, host);
    expect(_state(host).open, isTrue);
  });
}
