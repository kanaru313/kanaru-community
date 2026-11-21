import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/extension/state/extension_registry.dart';
import 'package:kanaru/src/extension/state/registry_entries.dart';
import 'package:kanaru/src/library/domain/history/history_days.dart';
import 'package:kanaru/src/library/library_extension.dart';
import 'package:kanaru/src/library/state/history/local_day_provider.dart';
import 'package:kanaru/src/library/ui/history/history_locations.dart';
import 'package:kanaru/src/library/ui/history/history_page.dart';
import 'package:kanaru/src/library/ui/history/track/track_history_page.dart';
import 'package:kanaru/src/library/ui/most_played/most_played_page.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_harness.dart';
import '../support/ui_harness.dart';

class _DayWithoutTimer extends LocalDayNotifier {
  @override
  DateTime build() => localDay(DateTime.now());
}

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

    test('History and Most played are live, both under Playlists', () {
      final history = item('history');
      expect(history.parentId, 'playlists');
      expect(history.path, HistoryLocations.history);
      expect(history.order, 240);
      expect(history.mobileTab, isFalse);
      expect(history.comingSoon, isFalse);
      final mostPlayed = item('most_played');
      expect(mostPlayed.parentId, 'playlists');
      expect(mostPlayed.order, 250);
      expect(mostPlayed.comingSoon, isFalse);
    });
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

  testWidgets('Most played and one song\'s plays from it resolve under '
      '/playlists', (tester) async {
    await pumpKanaruApp(
      tester,
      // No midnight timer to leave pending when the page is left.
      overrides: [localDayProvider.overrideWith(_DayWithoutTimer.new)],
    );
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    router.go(HistoryLocations.mostPlayed);
    await tester.pumpAndSettle();
    expect(find.byType(MostPlayedPage), findsOneWidget);
    expect(_location(tester), '/playlists/most-played');
    router.go(HistoryLocations.mostPlayedTrack(3));
    await tester.pumpAndSettle();
    expect(find.byType(MostPlayedPage), findsNothing);
    expect(
      find.byWidgetPredicate((w) => w is TrackHistoryPage && w.trackId == 3),
      findsOneWidget,
    );
    expect(_location(tester), '/playlists/most-played/track/3');
    await unmountApp(tester);
  });
}
