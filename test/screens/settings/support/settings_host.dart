import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/extension/state/extension_providers.dart';
import 'package:kanaru/src/extension/state/extension_registry.dart';
import 'package:kanaru/src/platform/domain/media_permissions.dart';
import 'package:kanaru/src/platform/state/media_permissions_provider.dart';
import 'package:kanaru/src/platform/state/platform_providers.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/screens/settings/settings_routes.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/memory_settings_store.dart';

class _FakePermissions implements MediaPermissions {
  _FakePermissions(this.state);
  final MediaPermissionState state;

  @override
  Future<MediaPermissionState> status() async => state;
  @override
  Future<MediaPermissionState> requestAudio() async => state;
  @override
  Future<MediaPermissionState> requestImages() async => state;
  @override
  Future<bool> openSettings() async => false;
}

/// What a Settings page test holds on to.
class SettingsHarness {
  SettingsHarness(this.container, this.store, this.router);

  final ProviderContainer container;
  final MemorySettingsStore store;
  final GoRouter router;
}

/// Pumps the Settings routes at [location] on a window of [size], with an
/// in-memory store and a registry that holds [registry].
Future<SettingsHarness> pumpSettings(
  WidgetTester tester, {
  String location = SettingsPaths.root,
  Size size = const Size(400, 800),
  double textScale = 1,
  MediaPermissionState permission = const MediaPermissionState.notApplicable(),
  ExtensionRegistry? registry,
  List<Override> overrides = const [],
  ThemeData? theme,

  /// False when [overrides] bring their own `mediaPermissionsProvider`.
  bool fakePermissions = true,

  /// Puts a [Scaffold] under the router, as the shells do (snack bars need
  /// one).
  bool scaffold = false,

  /// The page at `/`, for tests that start elsewhere and navigate.
  Widget home = const SizedBox.shrink(),

  /// Platform asks for reduced motion.
  bool reduceMotion = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  final store = MemorySettingsStore();
  final container = ProviderContainer(
    overrides: [
      settingsStoreProvider.overrideWithValue(store),
      nativeVersionsProvider.overrideWithValue('bridge 0.1.0, media 0.1.0'),
      extensionRegistryProvider.overrideWithValue(
        registry ?? ExtensionRegistry(),
      ),
      if (fakePermissions)
        mediaPermissionsProvider.overrideWithValue(
          _FakePermissions(permission),
        ),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      buildSettingsRoute(),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: theme ?? buildKanaruTheme(brightness: Brightness.light),
        darkTheme: buildKanaruTheme(brightness: Brightness.dark),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduceMotion,
          ),
          child: scaffold ? Scaffold(body: child) : child!,
        ),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return SettingsHarness(container, store, router);
}
