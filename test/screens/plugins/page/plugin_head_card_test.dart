import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/online/lyrics_source.dart';
import 'package:kanaru/src/lyrics/state/online/lyrics_sources_provider.dart';

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
}
