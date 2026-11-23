import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/extension/state/extension_providers.dart';
import 'package:kanaru/src/extension/state/extension_registry.dart';
import 'package:kanaru/src/library/domain/info/song_details.dart';
import 'package:kanaru/src/library/state/favorites_providers.dart';
import 'package:kanaru/src/library/state/info/song_details_providers.dart';
import 'package:kanaru/src/library/ui/info/open_song_info.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/platform/state/file_manager_provider.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/memory_settings_store.dart';
import '../menus/menu_fakes.dart';
import '../menus/menu_fixtures.dart';

/// Records favorite writes.
class FakeFavorites implements FavoritesController {
  final calls = <(List<TrackId>, bool)>[];

  @override
  Future<void> setFavorite(List<TrackId> tracks, bool favorite) async =>
      calls.add((tracks, favorite));

  @override
  Future<void> toggle(TrackId track) async {}
}

/// The info route over a plain app: details, favorites and the settings are
/// fed by the test.
class InfoHarness {
  InfoHarness._();

  final details = StreamController<SongDetails?>();
  final favoriteIds = StreamController<Set<TrackId>>();
  final favorites = FakeFavorites();
  final settings = MemorySettingsStore();
  final fileManager = FakeFileManager();
  final registry = ExtensionRegistry();
  Future<void>? opened;
}

/// Pumps an app with an "open" button and opens the info of
/// `trackInfo(id: 7)`. [initial] is emitted at once; null emits nothing (the
/// loading state). [textScale] and [still] set the platform's text scale and
/// "remove animations".
Future<InfoHarness> pumpInfo(
  WidgetTester tester, {
  SongDetails? initial,
  Size size = const Size(390, 2600),
  double textScale = 1,
  bool still = false,
  bool canReveal = true,
  bool openIt = true,
}) async {
  final h = InfoHarness._();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  if (still) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  }
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearAllTestValues();
    unawaited(h.details.close());
    unawaited(h.favoriteIds.close());
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        songDetailsProvider.overrideWith((ref, id) => h.details.stream),
        favoriteTrackIdsProvider.overrideWith((ref) => h.favoriteIds.stream),
        favoritesControllerProvider.overrideWithValue(h.favorites),
        settingsStoreProvider.overrideWithValue(h.settings),
        extensionRegistryProvider.overrideWithValue(h.registry),
        fileManagerProvider.overrideWithValue(
          FakeFileManager(canReveal: canReveal),
        ),
      ],
      child: MaterialApp(
        theme: buildKanaruTheme(brightness: Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () =>
                    h.opened = openSongInfo(context, trackInfo(id: 7)),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  if (openIt) {
    await tester.tap(find.text('open'));
    await tester.pump();
    if (initial != null) h.details.add(initial);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }
  return h;
}

/// Finder of a [KTextLink] by its text.
Finder link(String text) => find.byWidgetPredicate(
  (w) => w is KTextLink && w.text == text,
  description: 'link "$text"',
);
