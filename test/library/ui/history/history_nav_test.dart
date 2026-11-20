import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/library/ui/history/history_locations.dart';
import 'package:kanaru/src/library/ui/history/history_page.dart';
import 'package:kanaru/src/router/state/router_provider.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_harness.dart';

GoRouter _router(ProviderContainer c) => c.read(routerProvider);

String _location(ProviderContainer c) =>
    _router(c).routerDelegate.currentConfiguration.last.matchedLocation;

Future<void> _go(WidgetTester tester, ProviderContainer c, String path) async {
  _router(c).go(path);
  await tester.pumpAndSettle();
}

Future<bool> _back(WidgetTester tester) async {
  final handled = await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
  return handled;
}

/// The sidebar row labelled [label].
Finder _sidebarRow(String label) => find.descendant(
  of: find.byKey(const ValueKey('sidebar')),
  matching: find.text(label),
);

void main() {
  testWidgets('desktop: the History sidebar item stays highlighted on its '
      'page, and its parent does not take the highlight', (tester) async {
    final semantics = tester.ensureSemantics();
    final c = await pumpKanaruApp(tester, width: 1400, height: 900);
    await _go(tester, c, HistoryLocations.history);
    expect(find.byType(HistoryPage), findsOneWidget);
    expect(_location(c), HistoryLocations.history);
    expect(
      tester.getSemantics(_sidebarRow('History')),
      isSemantics(isSelected: true, hasSelectedState: true, isButton: true),
    );
    expect(
      tester.getSemantics(_sidebarRow('Playlists')),
      isSemantics(isSelected: false, hasSelectedState: true, isButton: true),
    );
    semantics.dispose();
  });

  testWidgets('mobile: Back from History goes to the Playlist root, then to '
      'Home', (tester) async {
    // The platform side of Back: the app exits only on the last step.
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final c = await pumpKanaruApp(tester, width: 400, height: 800);
    await _go(tester, c, HistoryLocations.history);
    expect(find.byType(HistoryPage), findsOneWidget);

    expect(await _back(tester), isTrue);
    expect(_location(c), '/playlists');
    expect(find.byType(HistoryPage), findsNothing);

    expect(await _back(tester), isTrue);
    expect(_location(c), '/');
  });
}
