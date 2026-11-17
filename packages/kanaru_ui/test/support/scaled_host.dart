import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Like `host()` but the text scale sits above the Navigator (via
/// `MaterialApp.builder`), so dialogs, popovers and other routes inherit it.
/// Used by the sort tests that must really run at a larger text scale.
Widget scaledHost(
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
  bool reduceMotion = false,
}) {
  return MaterialApp(
    theme: buildKanaruTheme(brightness: brightness),
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: reduceMotion,
      ),
      child: app!,
    ),
    home: Scaffold(body: child),
  );
}
