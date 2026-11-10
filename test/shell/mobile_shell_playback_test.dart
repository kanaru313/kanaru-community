import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/extension/state/extension_providers.dart';
import 'package:kanaru/src/extension/state/extension_registry.dart';
import 'package:kanaru/src/playback/ui/mini_player.dart';
import 'package:kanaru/src/playback/ui/queue/queue_row.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/mobile_now_playing.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/queue_sheet.dart';
import 'package:kanaru/src/screens/now_playing/ui/now_playing_page.dart';
import 'package:kanaru/src/shell/ui/mobile_shell.dart';
import 'package:material_ui/material_ui.dart';

import '../playback/support/ui_host.dart';

/// The real [MobileShell] with its default mini player wiring (no `onOpen`
/// or `onOpenQueue` override) over a stand-in page.
final _routes = <RouteBase>[
  StatefulShellRoute.indexedStack(
    builder: (context, state, shell) => MobileShell(
      navigationShell: shell,
      items: const [],
      selectionBar: const SizedBox.shrink(),
    ),
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/shell',
            builder: (_, _) => const Center(child: Text('shell page')),
          ),
        ],
      ),
    ],
  ),
  GoRoute(
    path: '/now-playing',
    builder: (context, state) => const NowPlayingPage(),
  ),
];

Future<UiHost> _open(WidgetTester tester) async {
  final host = await pumpWithPlayer(
    tester,
    const SizedBox(),
    routes: _routes,
    size: const Size(390, 844),
    overrides: [
      extensionRegistryProvider.overrideWithValue(ExtensionRegistry()),
    ],
  );
  host.router!.go('/shell');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await host.letStreamsArrive(tester);
  return host;
}

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

String _location(UiHost host) =>
    host.router!.routerDelegate.currentConfiguration.last.matchedLocation;

void main() {
  testWidgets('tapping the mini player opens Now Playing', (tester) async {
    final host = await _open(tester);
    expect(find.byType(MiniPlayer), findsOneWidget);
    await tester.tap(find.byType(MiniPlayer));
    await tester.pump();
    await _frames(tester);
    expect(_location(host), '/now-playing');
    expect(find.byType(MobileNowPlaying), findsOneWidget);
    // Back returns to the shell page.
    host.router!.pop();
    await tester.pump();
    await _frames(tester);
    expect(find.text('shell page'), findsOneWidget);
  });

  testWidgets('a long press on the mini player opens the queue sheet', (
    tester,
  ) async {
    final host = await _open(tester);
    await tester.longPress(find.byType(MiniPlayer));
    await tester.pump();
    await _frames(tester);
    await host.letStreamsArrive(tester);
    expect(find.byType(QueueSheetPage), findsOneWidget);
    expect(find.byType(QueueRow), findsWidgets);
    // A sheet, not a page: the location did not change.
    expect(_location(host), '/shell');
    await tester.binding.handlePopRoute();
    await tester.pump();
    await _frames(tester);
    expect(find.byType(QueueSheetPage), findsNothing);
  });
}
