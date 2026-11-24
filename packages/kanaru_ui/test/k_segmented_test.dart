import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/fit.dart';
import 'support/host.dart';

const _segments = [
  KSegment(value: 'min', label: 'Phút'),
  KSegment(value: 'tracks', label: 'Số bài'),
];

Widget _segmented({
  String value = 'min',
  ValueChanged<String>? onChanged,
  double width = 280,
}) => Center(
  child: SizedBox(
    width: width,
    child: KSegmented<String>(
      segments: _segments,
      value: value,
      onChanged: onChanged ?? (_) {},
      semanticLabel: 'Kiểu',
    ),
  ),
);

Finder _seg(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byType(FocusableActionDetector),
);

Color? _fill(WidgetTester tester, String label) {
  final box = tester.widget<AnimatedContainer>(
    find.ancestor(
      of: find.text(label),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return (box.decoration! as ShapeDecoration).color;
}

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('chosen segment reports selected, one exclusive group '
        '($name)', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(_segmented(), brightness: brightness, textScale: scale),
      );
      expect(
        tester.getSemantics(find.text('Phút')),
        isSemantics(
          label: 'Phút',
          isButton: true,
          isSelected: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
        ),
      );
      expect(
        tester.getSemantics(find.text('Số bài')),
        isSemantics(
          label: 'Số bài',
          isButton: true,
          isSelected: false,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
        ),
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('only the chosen segment is tinted, no check mark', (
    tester,
  ) async {
    await tester.pumpWidget(host(_segmented()));
    final scheme = Theme.of(tester.element(find.text('Phút'))).colorScheme;
    expect(_fill(tester, 'Phút'), scheme.secondaryContainer);
    expect(_fill(tester, 'Số bài')!.a, 0);
    expect(find.byType(KCheckMark), findsNothing);
    expect(find.byIcon(KIcons.check), findsNothing);
  });

  testWidgets('tap chooses; the tint follows the new value', (tester) async {
    String? chosen;
    await tester.pumpWidget(host(_segmented(onChanged: (v) => chosen = v)));
    await tester.tap(find.text('Số bài'));
    expect(chosen, 'tracks');
    await tester.pumpWidget(host(_segmented(value: 'tracks')));
    await tester.pumpAndSettle();
    final scheme = Theme.of(tester.element(find.text('Phút'))).colorScheme;
    expect(_fill(tester, 'Số bài'), scheme.secondaryContainer);
  });

  testWidgets('height is 48 on touch shells and 36 on desktop', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_segmented()));
    expect(tester.getSize(find.byType(KSegmented<String>)).height, 48);
    useWindow(tester, const Size(1300, 800));
    await tester.pumpWidget(host(_segmented()));
    await tester.pump();
    expect(tester.getSize(find.byType(KSegmented<String>)).height, 36);
  });

  testWidgets('hover 8 % and press 10 % layers', (tester) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.pumpWidget(host(_segmented(value: 'min')));
    final scheme = Theme.of(tester.element(find.text('Phút'))).colorScheme;
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.text('Số bài')));
    await tester.pumpAndSettle();
    expect(_fill(tester, 'Số bài'), scheme.onSurface.withValues(alpha: 0.08));
    await mouse.down(tester.getCenter(find.text('Số bài')));
    await tester.pump(kPressTimeout);
    await tester.pumpAndSettle();
    expect(_fill(tester, 'Số bài'), scheme.onSurface.withValues(alpha: 0.10));
    await mouse.up();
    await tester.pumpAndSettle();
  });

  testWidgets('keyboard: Tab focuses, arrows move focus, Enter and Space '
      'choose', (tester) async {
    final chosen = <String>[];
    await tester.pumpWidget(host(_segmented(onChanged: chosen.add)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    FocusNode node(String l) =>
        tester.widget<FocusableActionDetector>(_seg(l)).focusNode!;
    expect(node('Phút').hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(node('Số bài').hasFocus, isTrue);
    expect(chosen, isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(node('Số bài').hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(chosen, ['tracks', 'tracks']);
    expect(node('Phút').hasFocus, isTrue);
  });

  testWidgets('keyboard focus draws a 2 dp primary ring', (tester) async {
    await tester.pumpWidget(host(_segmented()));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      tester
          .widgetList<KFocusRing>(find.byType(KFocusRing))
          .where((r) => r.visible),
      hasLength(1),
    );
  });

  testWidgets('320 wide with 200 % text: no overflow', (tester) async {
    useWindow(tester, const Size(320, 640));
    await tester.pumpWidget(
      host(
        const Padding(
          padding: EdgeInsets.all(16),
          child: KSegmented<String>(
            segments: _segments,
            value: 'min',
            onChanged: _noop,
          ),
        ),
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
    // 'Số bài' at 28 dp is wider than the half track in Ahem: ellipsis is
    // allowed here, the painted text must still stay inside the track.
    expectTextsFit(
      tester,
      find.byType(KSegmented<String>),
      allowEllipsis: true,
    );
  });

  for (final (name, size, min) in [
    ('desktop', const Size(1300, 800), 36.0),
    ('touch', const Size(400, 800), 48.0),
  ]) {
    testWidgets('200 % text on $name: the track grows, labels stay inside it', (
      tester,
    ) async {
      useWindow(tester, size);
      await tester.pumpWidget(host(_segmented(width: 500), textScale: 2));
      await tester.pump();
      expect(tester.takeException(), isNull);
      final track = tester.getRect(find.byType(KSegmented<String>));
      for (final label in ['Phút', 'Số bài']) {
        final text = tester.getRect(find.text(label));
        expect(track.top, lessThanOrEqualTo(text.top), reason: label);
        expect(track.bottom, greaterThanOrEqualTo(text.bottom), reason: label);
      }
      expect(track.height, name == 'desktop' ? greaterThan(min) : min);
      expectTextsFit(tester, find.byType(KSegmented<String>));
    });
  }

  testWidgets('semantics: focusable, focused only on the focused segment', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host(_segmented()));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      tester.getSemantics(find.text('Phút')),
      isSemantics(isButton: true, isFocusable: true, isFocused: true),
    );
    expect(
      tester.getSemantics(find.text('Số bài')),
      isSemantics(isButton: true, isFocusable: true, isFocused: false),
    );
    semantics.dispose();
  });

  testWidgets('a disabled segment is dimmed, inert and skipped by arrows', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final chosen = <String>[];
    await tester.pumpWidget(
      host(
        Center(
          child: SizedBox(
            width: 360,
            child: KSegmented<String>(
              segments: const [
                KSegment(value: 'a', label: 'Một'),
                KSegment(value: 'b', label: 'Hai', enabled: false),
                KSegment(value: 'c', label: 'Ba'),
              ],
              value: 'a',
              onChanged: chosen.add,
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.text('Hai')),
      isSemantics(
        label: 'Hai',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
        isFocusable: false,
      ),
    );
    expect(
      tester.getSemantics(find.text('Ba')),
      isSemantics(
        label: 'Ba',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
      ),
    );
    final dim = tester.widget<Opacity>(
      find.ancestor(of: find.text('Hai'), matching: find.byType(Opacity)).first,
    );
    expect(dim.opacity, 0.38);

    await tester.tap(find.text('Hai'));
    await tester.pump();
    expect(chosen, isEmpty);

    FocusNode node(String l) =>
        tester.widget<FocusableActionDetector>(_seg(l)).focusNode!;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(node('Một').hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(node('Ba').hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(node('Một').hasFocus, isTrue);
    semantics.dispose();
  });

  testWidgets('reduced motion: the tint moves at once', (tester) async {
    await tester.pumpWidget(host(_segmented(), reduceMotion: true));
    await tester.pumpWidget(
      host(_segmented(value: 'tracks'), reduceMotion: true),
    );
    await tester.pump();
    final scheme = Theme.of(tester.element(find.text('Phút'))).colorScheme;
    expect(_fill(tester, 'Số bài'), scheme.secondaryContainer);
  });
}

void _noop(String _) {}
