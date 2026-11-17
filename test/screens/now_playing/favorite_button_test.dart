import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/state/favorites_providers.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/screens/now_playing/ui/favorite_button.dart';

import '../../playback/support/ui_host.dart';
import '../../support/icon_button_finders.dart';

class _FailingFavorites implements FavoritesController {
  @override
  Future<void> setFavorite(List<TrackId> tracks, bool favorite) async =>
      throw StateError('write failed');

  @override
  Future<void> toggle(TrackId track) async => throw StateError('write failed');
}

/// Every toggle waits for [done] of its own, so a test decides when it ends.
class _SlowFavorites implements FavoritesController {
  final calls = <TrackId>[];
  final done = <Completer<void>>[];

  @override
  Future<void> setFavorite(List<TrackId> tracks, bool favorite) async {}

  @override
  Future<void> toggle(TrackId track) {
    calls.add(track);
    final c = Completer<void>();
    done.add(c);
    return c.future;
  }
}

void main() {
  testWidgets('shows an empty heart, fills it after a tap, empties it again', (
    tester,
  ) async {
    late UiHost host;
    host = await pumpWithPlayer(
      tester,
      Builder(builder: (_) => const SizedBox()),
      play: false,
    );
    final id = host.h.tracks.first;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: host.container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: FavoriteButton(trackId: id)),
        ),
      ),
    );
    await host.letStreamsArrive(tester);
    expect(byIconButton('Add to favorites'), findsOneWidget);
    expect(host.container.read(isFavoriteProvider(id)), isFalse);

    await tester.tap(find.byType(FavoriteButton));
    await host.letStreamsArrive(tester);
    expect(host.container.read(isFavoriteProvider(id)), isTrue);
    expect(byIconButton('Remove from favorites'), findsOneWidget);

    await tester.tap(find.byType(FavoriteButton));
    await host.letStreamsArrive(tester);
    expect(host.container.read(isFavoriteProvider(id)), isFalse);
    expect(byIconButton('Add to favorites'), findsOneWidget);
  });

  testWidgets('a failed write shows a message and the heart stays empty', (
    tester,
  ) async {
    final host = await pumpWithPlayer(
      tester,
      Builder(builder: (_) => const SizedBox()),
      play: false,
      overrides: [
        favoritesControllerProvider.overrideWithValue(_FailingFavorites()),
      ],
    );
    final id = host.h.tracks.first;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: host.container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: FavoriteButton(trackId: id)),
        ),
      ),
    );
    await host.letStreamsArrive(tester);
    await tester.tap(find.byType(FavoriteButton));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Could not change favorites'), findsOneWidget);
    expect(byIconButton('Add to favorites'), findsOneWidget);
  });

  Future<(UiHost, _SlowFavorites)> pumpSlow(WidgetTester tester) async {
    final slow = _SlowFavorites();
    final host = await pumpWithPlayer(
      tester,
      Builder(builder: (_) => const SizedBox()),
      play: false,
      overrides: [favoritesControllerProvider.overrideWithValue(slow)],
    );
    return (host, slow);
  }

  Future<void> show(WidgetTester tester, UiHost host, TrackId id) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: host.container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: FavoriteButton(trackId: id)),
        ),
      ),
    );
    await host.letStreamsArrive(tester);
  }

  testWidgets('a tap while a write runs is ignored, a later one goes', (
    tester,
  ) async {
    final (host, slow) = await pumpSlow(tester);
    await show(tester, host, host.h.tracks.first);
    await tester.tap(find.byType(FavoriteButton));
    await tester.tap(find.byType(FavoriteButton));
    expect(slow.calls, hasLength(1));
    slow.done.first.complete();
    await tester.pump();
    await tester.tap(find.byType(FavoriteButton));
    expect(slow.calls, hasLength(2));
    slow.done.last.complete();
    await tester.pump();
  });

  testWidgets('the end of the old track write does not free the new one', (
    tester,
  ) async {
    final (host, slow) = await pumpSlow(tester);
    final (a, b) = (host.h.tracks[0], host.h.tracks[1]);
    await show(tester, host, a);
    await tester.tap(find.byType(FavoriteButton));
    await show(tester, host, b);
    await tester.tap(find.byType(FavoriteButton));
    expect(slow.calls, [a, b]);
    slow.done.first.complete(); // the write of the first track ends late
    await tester.pump();
    await tester.tap(find.byType(FavoriteButton)); // b's write still runs
    expect(slow.calls, [a, b]);
    slow.done.last.complete();
    await tester.pump();
  });
}
