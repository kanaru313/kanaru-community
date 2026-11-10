import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/state/favorites_providers.dart';
import 'package:kanaru/src/screens/now_playing/ui/favorite_button.dart';

import '../../playback/support/ui_host.dart';

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
    expect(find.byTooltip('Add to favorites'), findsOneWidget);
    expect(host.container.read(isFavoriteProvider(id)), isFalse);

    await tester.tap(find.byType(FavoriteButton));
    await host.letStreamsArrive(tester);
    expect(host.container.read(isFavoriteProvider(id)), isTrue);
    expect(find.byTooltip('Remove from favorites'), findsOneWidget);

    await tester.tap(find.byType(FavoriteButton));
    await host.letStreamsArrive(tester);
    expect(host.container.read(isFavoriteProvider(id)), isFalse);
    expect(find.byTooltip('Add to favorites'), findsOneWidget);
  });
}
