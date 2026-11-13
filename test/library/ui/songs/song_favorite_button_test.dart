import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/state/favorites_providers.dart';
import 'package:kanaru/src/library/ui/songs/song_tile.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

const _track = TrackId(7);

/// Records toggles and lets the test decide when each write ends.
class _Controller implements FavoritesController {
  final calls = <TrackId>[];
  Completer<void> write = Completer<void>();

  @override
  Future<void> toggle(TrackId track) {
    calls.add(track);
    return write.future;
  }

  @override
  Future<void> setFavorite(List<TrackId> tracks, bool favorite) =>
      throw UnimplementedError();
}

Future<StreamController<Set<TrackId>>> _pump(
  WidgetTester tester,
  _Controller controller, {
  ValueNotifier<Key>? keys,
  Size size = const Size(400, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final ids = StreamController<Set<TrackId>>();
  addTearDown(ids.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        favoritesControllerProvider.overrideWithValue(controller),
        favoriteTrackIdsProvider.overrideWith((ref) => ids.stream),
      ],
      child: MaterialApp(
        theme: buildKanaruTheme(brightness: Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: ValueListenableBuilder<Key>(
              valueListenable: keys ?? ValueNotifier<Key>(const ValueKey(0)),
              builder: (_, key, _) =>
                  SongFavoriteButton(key: key, trackId: _track),
            ),
          ),
        ),
      ),
    ),
  );
  ids.add(const {});
  await tester.pump();
  return ids;
}

/// The row ♥ by its tooltip text: it names itself to screen readers with its
/// own label, so `find.byTooltip` (which reads the semantic tooltip) misses it.
Finder _heart(String tooltip) => find.byWidgetPredicate(
  (w) => w is KRowIconAction && w.tooltip == tooltip,
);

void main() {
  testWidgets('a press toggles through the controller; tooltip, icon and '
      'toggled state follow the favourite', (tester) async {
    final handle = tester.ensureSemantics();
    final controller = _Controller();
    final ids = await _pump(tester, controller);
    expect(_heart('Add to favorites'), findsOneWidget);
    expect(find.byIcon(KIcons.heart), findsOneWidget);

    await tester.tap(find.byType(KRowIconAction));
    expect(controller.calls, [_track]);
    controller.write.complete();
    ids.add({_track});
    await tester.pump();

    expect(_heart('Remove from favorites'), findsOneWidget);
    expect(find.byIcon(KIcons.heartFilled), findsOneWidget);
    final scheme = Theme.of(
      tester.element(find.byType(KRowIconAction)),
    ).colorScheme;
    expect(
      tester.widget<Icon>(find.byIcon(KIcons.heartFilled)).color,
      scheme.primary,
    );
    expect(
      tester.getSemantics(find.byType(KRowIconAction)),
      matchesSemantics(
        label: 'Favorite',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasSelectedState: true,
        isSelected: true,
        hasToggledState: true,
        isToggled: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('a failed write shows the error snack bar', (tester) async {
    final controller = _Controller();
    await _pump(tester, controller);
    await tester.tap(find.byType(KRowIconAction));
    controller.write.completeError(StateError('disk'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Could not change favorites'), findsOneWidget);
  });

  testWidgets('a failure still shows its snack bar when the row was rebuilt '
      'with another key during the write', (tester) async {
    final controller = _Controller();
    final keys = ValueNotifier<Key>(const ValueKey('a'));
    await _pump(tester, controller, keys: keys);
    await tester.tap(find.byType(KRowIconAction));
    // The row is replaced: its old state is disposed while the write runs.
    keys.value = const ValueKey('b');
    await tester.pump();
    controller.write.completeError(StateError('disk'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Could not change favorites'), findsOneWidget);
  });

  testWidgets('a press while a write runs is ignored; the next one works', (
    tester,
  ) async {
    final controller = _Controller();
    await _pump(tester, controller);
    await tester.tap(find.byType(KRowIconAction));
    await tester.tap(find.byType(KRowIconAction));
    await tester.tap(find.byType(KRowIconAction));
    expect(controller.calls, hasLength(1));
    controller.write.complete();
    await tester.pump();
    controller.write = Completer<void>();
    await tester.tap(find.byType(KRowIconAction));
    expect(controller.calls, hasLength(2));
    controller.write.complete();
  });

  testWidgets('a failure after the whole page is gone shows nothing and '
      'throws nothing', (tester) async {
    final controller = _Controller();
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final ids = StreamController<Set<TrackId>>();
    addTearDown(ids.close);
    final show = ValueNotifier<bool>(true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favoritesControllerProvider.overrideWithValue(controller),
          favoriteTrackIdsProvider.overrideWith((ref) => ids.stream),
        ],
        child: ValueListenableBuilder<bool>(
          valueListenable: show,
          builder: (_, visible, _) => MaterialApp(
            key: ValueKey(visible),
            theme: buildKanaruTheme(brightness: Brightness.light),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: visible
                  ? const Center(child: SongFavoriteButton(trackId: _track))
                  : const SizedBox(),
            ),
          ),
        ),
      ),
    );
    ids.add(const {});
    await tester.pump();
    await tester.tap(find.byType(KRowIconAction));
    // The app (and its messenger) is replaced while the write runs.
    show.value = false;
    await tester.pump();
    controller.write.completeError(StateError('disk'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    expect(find.text('Could not change favorites'), findsNothing);
  });
}
