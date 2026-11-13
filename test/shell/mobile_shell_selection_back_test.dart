import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/extension/state/extension_providers.dart';
import 'package:kanaru/src/extension/state/extension_registry.dart';
import 'package:kanaru/src/library/state/browse/selection_providers.dart';
import 'package:kanaru/src/library/ui/selection/selection_panel.dart';
import 'package:kanaru/src/playback/ui/mini_player.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/queue_sheet.dart';
import 'package:kanaru/src/shell/ui/mobile_shell.dart';
import 'package:material_ui/material_ui.dart';

import '../playback/support/ui_host.dart';

/// The real [MobileShell] with its own selection bar mounted, so the queue
/// sheet opened over it meets a second selection panel underneath.
final _routes = <RouteBase>[
  StatefulShellRoute.indexedStack(
    builder: (context, state, shell) =>
        MobileShell(navigationShell: shell, items: const []),
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
];

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('Back over the shell bar collapses the sheet panel once, then '
      'closes the sheet, the selection kept', (tester) async {
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

    final selection = host.container.read(librarySelectionProvider.notifier);
    selection.toggle(host.h.tracks[1]);
    await tester.pump();
    await tester.longPress(find.byType(MiniPlayer));
    await tester.pump();
    await _frames(tester);
    await host.letStreamsArrive(tester);
    expect(find.byType(QueueSheetPage), findsOneWidget);
    // The shell's panel under the sheet and the sheet's own.
    expect(find.byType(SelectionPanel, skipOffstage: false), findsNWidgets(2));
    selection.setExpanded(true);
    await tester.pump();
    await _frames(tester);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await _frames(tester);
    expect(find.byType(QueueSheetPage), findsOneWidget);
    expect(host.container.read(librarySelectionProvider).expanded, isFalse);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await _frames(tester);
    expect(find.byType(QueueSheetPage), findsNothing);
    expect(host.container.read(librarySelectionProvider).ids, [
      host.h.tracks[1],
    ]);

    selection.clear();
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
  });
}
