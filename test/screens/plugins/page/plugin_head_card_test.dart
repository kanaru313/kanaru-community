import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/online/lyrics_source.dart';
import 'package:kanaru/src/lyrics/state/online/lyrics_sources_provider.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_settings.dart';

import '../support/page_fixtures.dart';
import '../support/plugin_fixtures.dart';

void main() {
  testWidgets('the lyrics row opens Settings › Lyrics at the sources', (
    tester,
  ) async {
    final h = await pumpPlugins(
      tester,
      StoreFixture(),
      location: pagePath,
      size: const Size(400, 2400),
      overrides: [
        ...pageOverrides(AsyncData(pageData())),
        lyricsSourcesLoadedProvider.overrideWithValue(true),
        lyricsSourcesProvider.overrideWithValue(const [
          LyricsSource(
            id: 'id-demo',
            name: 'Demo',
            version: 3,
            origin: LyricsSourceOrigin.repo,
            enabled: true,
          ),
        ]),
      ],
    );
    await tester.tap(find.text('Find lyrics automatically'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      h.router.routerDelegate.currentConfiguration.last.matchedLocation,
      '/settings/lyrics',
    );
    expect(find.text('Online sources'), findsOneWidget);
  });

  group('translate plugin', () {
    Future<void> open(WidgetTester tester, {String kind = 'translate'}) =>
        pumpPlugins(
          tester,
          StoreFixture(),
          location: pagePath,
          size: const Size(400, 2400),
          overrides: pageOverrides(
            AsyncData(pageData(row: pageRow(kind: kind))),
          ),
        );

    testWidgets('not the default: a button sets it, then it reads Default', (
      tester,
    ) async {
      await open(tester);
      expect(find.text('Default translation service'), findsOneWidget);
      expect(find.text('Default'), findsNothing);
      await tester.tap(find.text('Set as default'));
      await tester.pumpAndSettle();
      expect(find.text('Default'), findsOneWidget);
      expect(find.text('Set as default'), findsNothing);
    });

    testWidgets('the chosen service reads Default with no button', (
      tester,
    ) async {
      await open(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.text('Default translation service')),
      );
      await container.read(translationServiceProvider.notifier).set('id-demo');
      await tester.pumpAndSettle();
      expect(find.text('Default'), findsOneWidget);
      expect(find.text('Set as default'), findsNothing);
    });

    testWidgets('an ai-translate plugin has the same row and the AI tag', (
      tester,
    ) async {
      await open(tester, kind: 'ai-translate');
      expect(find.text('Default translation service'), findsOneWidget);
      expect(find.text('Set as default'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);
    });
  });
}
