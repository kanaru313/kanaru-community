import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Light, dark and 150 % text: every widget is checked in all three.
const hostVariants = <(String, Brightness, double)>[
  ('light', Brightness.light, 1.0),
  ('dark', Brightness.dark, 1.0),
  ('text 150%', Brightness.light, 1.5),
];

Widget host(
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
  bool reduceMotion = false,
}) {
  return MaterialApp(
    theme: buildKanaruTheme(brightness: brightness),
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: Scaffold(body: child),
      ),
    ),
  );
}

/// Sets a logical window size for the test and restores it afterwards.
void useWindow(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
