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
}
