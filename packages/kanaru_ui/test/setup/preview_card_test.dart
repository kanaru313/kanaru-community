import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/finders.dart';
import '../support/host.dart';

enum _Bar { wave, flat }

const _options = [
  KPreviewOption<_Bar>(
    value: _Bar.wave,
    preview: SizedBox(height: 40),
    title: 'Dạng sóng',
    caption: 'Vẽ theo âm thanh của bài.',
  ),
  KPreviewOption<_Bar>(
    value: _Bar.flat,
    preview: SizedBox(height: 40),
    title: 'Thanh phẳng',
    caption: 'Một thanh đơn giản.',
  ),
];

Widget _group(_Bar selected, ValueChanged<_Bar> onChanged) =>
    KPreviewCardGroup<_Bar>(
      options: _options,
      selected: selected,
      onChanged: onChanged,
    );

void main() {
  testWidgets('only the chosen card reports selected, as a radio group', (
    tester,
  ) async {
    useWindow(tester, const Size(500, 800));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(_group(_Bar.wave, (_) {})));
    expect(bySelected('Dạng sóng'), findsOneWidget);
    expect(bySelected('Thanh phẳng'), findsNothing);
    expect(
      tester.getSemantics(find.text('Dạng sóng')),
      matchesSemantics(
        label: 'Dạng sóng',
        hint: 'Vẽ theo âm thanh của bài.',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('a tap chooses the other card', (tester) async {
    useWindow(tester, const Size(500, 800));
    final chosen = <_Bar>[];
    await tester.pumpWidget(host(_group(_Bar.wave, chosen.add)));
    await tester.tap(find.text('Thanh phẳng'));
    expect(chosen, [_Bar.flat]);
  });

  testWidgets('arrow keys move the choice and the focus', (tester) async {
    useWindow(tester, const Size(500, 800));
    var selected = _Bar.wave;
    late StateSetter set;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) {
            set = setState;
            return _group(selected, (v) => set(() => selected = v));
          },
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(selected, _Bar.flat);
    expect(bySelected('Thanh phẳng'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(selected, _Bar.flat, reason: 'stops at the last card');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(selected, _Bar.wave);
  });

  /// Number of cards on the first row of six cards in a window of [size].
  Future<int> firstRowCount(
    WidgetTester tester,
    Size size, {
    double textScale = 1,
  }) async {
    useWindow(tester, size);
    await tester.pumpWidget(
      host(
        KPreviewCardGroup<int>(
          options: [
            for (var i = 0; i < 6; i++)
              KPreviewOption<int>(
                value: i,
                preview: const SizedBox(height: 20),
                title: 'Kiểu $i',
                caption: 'Chú thích $i',
              ),
          ],
          selected: 0,
          onChanged: (_) {},
        ),
        textScale: textScale,
      ),
    );
    final top = tester.getTopLeft(find.text('Kiểu 0')).dy;
    var count = 0;
    for (var i = 0; i < 6; i++) {
      if (tester.getTopLeft(find.text('Kiểu $i')).dy == top) count++;
    }
    expect(tester.takeException(), isNull);
    return count;
  }

  testWidgets('mobile shell: two columns, also on a wide phone', (
    tester,
  ) async {
    expect(await firstRowCount(tester, const Size(400, 900)), 2);
    expect(await firstRowCount(tester, const Size(1100, 900)), 2);
  });

  testWidgets('desktop shell: three columns', (tester) async {
    expect(await firstRowCount(tester, const Size(1200, 900)), 3);
    expect(await firstRowCount(tester, const Size(1600, 900)), 3);
  });

  testWidgets('text scale 200 % or more: one column on both shells', (
    tester,
  ) async {
    expect(await firstRowCount(tester, const Size(400, 900), textScale: 2), 1);
    expect(await firstRowCount(tester, const Size(1400, 900), textScale: 2), 1);
    expect(
      await firstRowCount(tester, const Size(400, 900), textScale: 1.9),
      2,
    );
  });

  testWidgets('two options on the desktop shell fill one row of two columns', (
    tester,
  ) async {
    useWindow(tester, const Size(1400, 900));
    await tester.pumpWidget(host(_group(_Bar.wave, (_) {})));
    final wave = tester.getSize(find.text('Dạng sóng')).width;
    expect(
      tester.getTopLeft(find.text('Thanh phẳng')).dx,
      greaterThan(tester.getTopLeft(find.text('Dạng sóng')).dx + wave),
    );
    expect(
      tester.getTopLeft(find.text('Thanh phẳng')).dx,
      lessThan(1400 / 2 + 40),
    );
  });

  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('renders without overflow ($name), 200 % too', (tester) async {
      useWindow(tester, const Size(360, 800));
      await tester.pumpWidget(
        host(
          _group(_Bar.flat, (_) {}),
          brightness: brightness,
          textScale: scale,
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(host(_group(_Bar.flat, (_) {}), textScale: 2));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('animations off: the choice shows at once', (tester) async {
    useWindow(tester, const Size(500, 800));
    await tester.pumpWidget(
      host(_group(_Bar.wave, (_) {}), reduceMotion: true),
    );
    await tester.pumpWidget(
      host(_group(_Bar.flat, (_) {}), reduceMotion: true),
    );
    expect(bySelected('Thanh phẳng'), findsOneWidget);
    for (final scale in tester.widgetList<AnimatedScale>(
      find.byType(AnimatedScale),
    )) {
      expect(scale.duration, Duration.zero);
    }
  });

  testWidgets('a changed option count rebuilds without errors', (tester) async {
    useWindow(tester, const Size(500, 800));
    Widget group(int n) => host(
      KPreviewCardGroup<int>(
        options: [
          for (var i = 0; i < n; i++)
            KPreviewOption<int>(
              value: i,
              preview: const SizedBox(height: 20),
              title: 'Kiểu $i',
              caption: 'Chú thích $i',
            ),
        ],
        selected: 0,
        onChanged: (_) {},
      ),
    );
    await tester.pumpWidget(group(3));
    await tester.pumpWidget(group(4));
    await tester.pumpWidget(group(2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Kiểu 3'), findsNothing);
    expect(bySelected('Kiểu 0'), findsOneWidget);
  });

  bool cardHasFocus(WidgetTester tester, String title) {
    final ink = find.ancestor(
      of: find.text(title),
      matching: find.byType(InkWell),
    );
    return tester.widget<InkWell>(ink.first).focusNode!.hasPrimaryFocus;
  }

  testWidgets('Tab lands on the chosen card, also after an outside change', (
    tester,
  ) async {
    useWindow(tester, const Size(500, 800));
    Widget group(_Bar v) => host(_group(v, (_) {}));
    await tester.pumpWidget(group(_Bar.flat));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(cardHasFocus(tester, 'Thanh phẳng'), isTrue);
    expect(cardHasFocus(tester, 'Dạng sóng'), isFalse);
    // Leave the group, change the choice from outside, Tab back in.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpWidget(group(_Bar.wave));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(cardHasFocus(tester, 'Dạng sóng'), isTrue);
    expect(cardHasFocus(tester, 'Thanh phẳng'), isFalse);
  });

  testWidgets('keyboard focus shows the ring, pointer focus does not', (
    tester,
  ) async {
    useWindow(tester, const Size(500, 800));
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.pumpWidget(host(_group(_Bar.wave, (_) {})));
    int visibleRings() => tester
        .widgetList<KFocusRing>(find.byType(KFocusRing))
        .where((r) => r.visible)
        .length;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(visibleRings(), 1);
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTouch;
    await tester.pump();
    expect(visibleRings(), 0);
  });
}
