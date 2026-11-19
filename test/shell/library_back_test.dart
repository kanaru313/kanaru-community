import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/library/domain/library_tabs.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:material_ui/material_ui.dart';

import '../support/app_harness.dart';

/// Android Back through the real Library routes and the real nav items
/// (`builtInExtensions`) on the mobile shell. Folders levels (`?at=`) are not
/// covered here: they need a music folder with songs in the test database.

GoRouter _router(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first));

String _location(WidgetTester tester) =>
    _router(tester).routerDelegate.currentConfiguration.uri.path;

/// Records `SystemNavigator.pop` calls (the app exits).
List<int> _trackExit(WidgetTester tester) {
  final exits = <int>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'SystemNavigator.pop') exits.add(exits.length);
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return exits;
}

Future<bool> _back(WidgetTester tester) async {
  final handled = await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
  return handled;
}

bool _isListRoot(String path) =>
    LibraryTab.values.any((t) => path == LibraryLocations.list(t));

void main() {
  testWidgets('a list page: Back goes Home, Back again exits', (tester) async {
    final exits = _trackExit(tester);
    await pumpKanaruApp(tester, width: 400);
    _router(tester).go('/library/songs');
    await tester.pumpAndSettle();

    expect(await _back(tester), isTrue);
    expect(_location(tester), '/');
    expect(exits, isEmpty);

    expect(await _back(tester), isTrue);
    expect(exits, hasLength(1));
  });

  testWidgets('an album pushed from a list, then Home: Back exits', (
    tester,
  ) async {
    final exits = _trackExit(tester);
    await pumpKanaruApp(tester, width: 400);
    _router(tester).go('/library/songs');
    await tester.pumpAndSettle();
    _router(tester).push('/library/albums/x');
    await tester.pumpAndSettle();
    _router(tester).go('/');
    await tester.pumpAndSettle();
    expect(_location(tester), '/');

    expect(await _back(tester), isTrue);
    expect(_location(tester), '/');
    expect(exits, hasLength(1));
  });

  testWidgets('an album opened with go: Back goes to a list, then Home, then '
      'exits', (tester) async {
    final exits = _trackExit(tester);
    await pumpKanaruApp(tester, width: 400);
    _router(tester).go('/library/albums/x');
    await tester.pumpAndSettle();

    expect(await _back(tester), isTrue);
    expect(_isListRoot(_location(tester)), isTrue, reason: _location(tester));

    expect(await _back(tester), isTrue);
    expect(_location(tester), '/');
    expect(exits, isEmpty);

    expect(await _back(tester), isTrue);
    expect(exits, hasLength(1));
  });
}
