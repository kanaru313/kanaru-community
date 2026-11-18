import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/state/browse/custom_cover_index_providers.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';
import 'package:kanaru/src/platform/state/platform_providers.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

class _Paths implements AppPaths {
  @override
  final dataDir = Directory('/nonexistent/data');
  @override
  final cacheDir = Directory('/nonexistent/cache');
  @override
  final configDir = Directory('/nonexistent/config');
}

const phone = Size(360, 640);
const desktop = Size(1280, 800);

/// Localizations of [locale], for building picker content before it opens.
AppLocalizations l10nOf(String locale) =>
    lookupAppLocalizations(Locale(locale));

/// The app around a "open" button: Kanaru theme, localizations, a window of
/// [size] and the providers a [PlaylistCover] reads. [onOpen] runs on tap.
Future<void> pumpOpener(
  WidgetTester tester, {
  required void Function(BuildContext context) onOpen,
  Size size = phone,
  String locale = 'en',
  Brightness brightness = Brightness.light,
  double textScale = 1,
  bool reduceMotion = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appPathsProvider.overrideWithValue(_Paths()),
        customCoverIndexProvider.overrideWith(
          (ref, kind) => Stream.value(const <String>{}),
        ),
      ],
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildKanaruTheme(brightness: brightness),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduceMotion,
          ),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => onOpen(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Taps "open" and waits for the route to settle.
Future<void> openIt(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}
