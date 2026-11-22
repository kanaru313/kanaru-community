import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/screens/plugins/config/config_form.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'config_harness.dart';

const phoneSize = Size(400, 900);
const desktopSize = Size(1400, 900);

/// Pumps the settings form of plugin `id-demo` over [harness], in English.
Future<void> pumpConfigForm(
  WidgetTester tester,
  ConfigHarness harness, {
  Size size = phoneSize,
  bool locked = false,
  double textScale = 1,
  bool reduceMotion = false,
  List<Override> extra = const [],

  /// False while something spins on purpose (a card that is still reading).
  bool settle = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...harness.overrides, ...extra],
      child: MaterialApp(
        theme: buildKanaruTheme(brightness: Brightness.light),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduceMotion,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ConfigForm(installId: 'id-demo', locked: locked),
            ),
          ),
        ),
      ),
    ),
  );
  settle ? await tester.pumpAndSettle() : await tester.pump();
}
