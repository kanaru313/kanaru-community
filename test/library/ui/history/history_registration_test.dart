import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/extension/state/extension_registry.dart';
import 'package:kanaru/src/extension/state/registry_entries.dart';
import 'package:kanaru/src/library/library_extension.dart';
import 'package:kanaru/src/library/ui/history/history_locations.dart';
import 'package:kanaru/src/library/ui/history/history_page.dart';
import 'package:kanaru/src/library/ui/history/track/track_history_page.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_harness.dart';
import '../support/ui_harness.dart';

String _location(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .routerDelegate
        .currentConfiguration
        .uri
        .path;

void main() {
  test('locations nest under the Playlist tab', () {
    expect(HistoryLocations.history, '/playlists/history');
    expect(HistoryLocations.track(7), '/playlists/history/track/7');
    expect(HistoryLocations.mostPlayed, '/playlists/most-played');
    expect(
      HistoryLocations.mostPlayedTrack(7),
      '/playlists/most-played/track/7',
    );
  });

  group('nav', () {
    final registry = ExtensionRegistry()..install(const [LibraryExtension()]);
    NavItem item(String id) => registry.navItems.singleWhere((n) => n.id == id);

    test(
      'History is live, Most played is coming soon, both under Playlists',
      () {
        final history = item('history');
        expect(history.parentId, 'playlists');
        expect(history.path, HistoryLocations.history);
        expect(history.order, 240);
        expect(history.mobileTab, isFalse);
        expect(history.comingSoon, isFalse);
        final mostPlayed = item('most_played');
        expect(mostPlayed.parentId, 'playlists');
        expect(mostPlayed.order, 250);
        expect(mostPlayed.comingSoon, isTrue);
      },
    );
  });

  testWidgets('History and one song\'s plays resolve under /playlists', (
    tester,
  ) async {
    await pumpKanaruApp(tester);
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    router.go(HistoryLocations.history);
    await tester.pumpAndSettle();
    expect(find.byType(HistoryPage), findsOneWidget);
    expect(_location(tester), '/playlists/history');
    router.go(HistoryLocations.track(1));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate((w) => w is TrackHistoryPage && w.trackId == 1),
      findsOneWidget,
    );
    await unmountApp(tester);
  });
}
