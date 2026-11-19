import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

const _transitionKey = ValueKey('inner-transition');

/// Stands for the platform transition: marks the page it wraps.
class _MarkingTransitions extends PageTransitionsBuilder {
  const _MarkingTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => KeyedSubtree(key: _transitionKey, child: child);
}

/// App shell whose MediaQuery sits above the Navigator, as in the real app.
Widget _app(Widget home, {required bool reduceMotion}) => MaterialApp(
  theme: buildKanaruTheme(brightness: Brightness.light).copyWith(
    platform: TargetPlatform.linux,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.linux: KPageTransitionsBuilder(_MarkingTransitions()),
      },
    ),
  ),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: child!,
  ),
  home: home,
);

Widget _opener(void Function(BuildContext) open) => Builder(
  builder: (context) => Scaffold(
    body: TextButton(onPressed: () => open(context), child: const Text('open')),
  ),
);

/// Lowest opacity among the fades that wrap the text 'content'.
double _minOpacity(WidgetTester tester) {
  final fades = find.ancestor(
    of: find.text('content'),
    matching: find.byType(FadeTransition),
  );
  var lowest = 1.0;
  for (final fade in tester.widgetList<FadeTransition>(fades)) {
    if (fade.opacity.value < lowest) lowest = fade.opacity.value;
  }
  return lowest;
}

Future<void> _openAndPumpOnce(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
}

void main() {
  const content = Padding(padding: EdgeInsets.all(24), child: Text('content'));

  group('dialog', () {
    for (final reduce in [true, false]) {
      testWidgets('reduceMotion $reduce', (tester) async {
        useWindow(tester, const Size(700, 800));
        await tester.pumpWidget(
          _app(
            _opener((c) => showKDialog<void>(c, builder: (_) => content)),
            reduceMotion: reduce,
          ),
        );
        await _openAndPumpOnce(tester);
        if (reduce) {
          expect(_minOpacity(tester), 1);
        } else {
          expect(_minOpacity(tester), lessThan(1));
        }
        await tester.pumpAndSettle();
        expect(_minOpacity(tester), 1);
      });
    }
  });

  group('sheet', () {
    for (final reduce in [true, false]) {
      testWidgets('bottom sheet, reduceMotion $reduce', (tester) async {
        useWindow(tester, const Size(400, 800));
        await tester.pumpWidget(
          _app(
            _opener((c) => showKSheet<void>(c, builder: (_) => content)),
            reduceMotion: reduce,
          ),
        );
        await _openAndPumpOnce(tester);
        final early = tester.getTopLeft(find.text('content')).dy;
        await tester.pumpAndSettle();
        final settled = tester.getTopLeft(find.text('content')).dy;
        if (reduce) {
          expect(early, settled);
        } else {
          expect(early, greaterThan(settled));
        }
      });

      testWidgets('dialog sheet, reduceMotion $reduce', (tester) async {
        useWindow(tester, const Size(700, 800));
        await tester.pumpWidget(
          _app(
            _opener((c) => showKSheet<void>(c, builder: (_) => content)),
            reduceMotion: reduce,
          ),
        );
        await _openAndPumpOnce(tester);
        if (reduce) {
          expect(_minOpacity(tester), 1);
        } else {
          expect(_minOpacity(tester), lessThan(1));
        }
      });
    }

    testWidgets('closing is instant with reduceMotion', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        _app(
          _opener((c) => showKSheet<void>(c, builder: (_) => content)),
          reduceMotion: true,
        ),
      );
      await _openAndPumpOnce(tester);
      Navigator.of(tester.element(find.text('content'))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('content'), findsNothing);
    });
  });

  group('page', () {
    for (final reduce in [true, false]) {
      testWidgets('push, reduceMotion $reduce', (tester) async {
        useWindow(tester, const Size(700, 800));
        await tester.pumpWidget(
          _app(
            _opener(
              (c) => Navigator.of(c).push(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Center(child: content)),
                ),
              ),
            ),
            reduceMotion: reduce,
          ),
        );
        await _openAndPumpOnce(tester);
        // The platform transition wraps the page only when motion is on.
        expect(
          find.ancestor(
            of: find.text('content'),
            matching: find.byKey(_transitionKey),
          ),
          reduce ? findsNothing : findsOneWidget,
        );
        await tester.pumpAndSettle();
        expect(find.text('content'), findsOneWidget);
      });
    }
  });

  test(
    'theme rebuilt twice compares equal (no theme animation on rebuild)',
    () {
      expect(
        buildKanaruTheme(brightness: Brightness.light),
        buildKanaruTheme(brightness: Brightness.light),
      );
    },
  );
}
