import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show OffsetLayer;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The two shell sizes of the AI settings screenshot tests.
const aiSettingsShells = <String, Size>{
  'desktop': Size(1400, 1000),
  'phone': Size(412, 915),
};

/// The language of the screenshots (the mockups are Vietnamese).
const aiSettingsLocale = Locale('vi');

/// The delegates the app itself uses (the Material ones are the app's, which
/// load Vietnamese date data; `AppLocalizations.localizationsDelegates` do not).
final appLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];

/// Vietnamese strings for finders, loaded from the same arb the app uses.
Future<AppLocalizations> loadViStrings() =>
    AppLocalizations.delegate.load(aiSettingsLocale);

/// Writes a screenshot of the whole window (root layer only) to
/// `$KANARU_IT_SHOTS/<name>-<shell>.png`. For the eye only: a failure is
/// logged, never fails the test.
Future<void> aiSettingsShot(
  WidgetTester tester,
  String name,
  String shell,
) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.runAsync(() async {
    try {
      final view = tester.binding.renderViews.first;
      final layer = view.debugLayer! as OffsetLayer;
      final image = await layer.toImage(Offset.zero & view.size);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      final dir = Directory(
        Platform.environment['KANARU_IT_SHOTS'] ??
            '/tmp/kanaru-it/shots-ai-settings',
      )..createSync(recursive: true);
      File('${dir.path}/$name-$shell.png')
          .writeAsBytesSync(bytes.buffer.asUint8List());
    } on Object catch (e) {
      debugPrint('screenshot $name-$shell failed: $e');
    }
  });
}

/// Scrolls [target] into view (the page builds lazily on a short window).
Future<void> aiSettingsReveal(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}
