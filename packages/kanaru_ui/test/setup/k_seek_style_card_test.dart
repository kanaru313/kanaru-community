import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/finders.dart';
import '../support/host.dart';

enum _Kind { bars, wave, flat }

/// A group of three cards: wave needs the waveform (no ★), the other two may
/// be the fallback. The chosen card carries the action.
class _Harness extends StatefulWidget {
  const _Harness({this.initial = _Kind.bars, this.longName = false});

  final _Kind initial;
  final bool longName;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late _Kind selected = widget.initial;
  _Kind fallback = _Kind.flat;
  final reopened = <_Kind>[];
  final customised = <_Kind>[];

  KPreviewOption<_Kind> _option(_Kind kind, String title, {bool star = true}) =>
      KPreviewOption<_Kind>(
        value: kind,
        preview: const SizedBox(height: 40),
        title: title,
        caption: 'Chú thích $title',
        fallback: star
            ? KFallbackMark(
                active: fallback == kind,
                tooltip: fallback == kind
                    ? 'Hiện khi chưa có sóng'
                    : 'Dùng $title khi chưa có sóng',
                onActivate: () => setState(() => fallback = kind),
              )
            : null,
        action: KCardAction(
          label: 'Tuỳ chỉnh',
          onPressed: () => customised.add(kind),
        ),
        onReselect: () => reopened.add(kind),
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: KPreviewCardGroup<_Kind>(
        selected: selected,
        onChanged: (v) => setState(() => selected = v),
        options: [
          _option(_Kind.bars, widget.longName ? 'Vạch rất dài' * 6 : 'Vạch'),
          _option(_Kind.wave, 'Dạng sóng', star: false),
          _option(_Kind.flat, 'Thanh phẳng'),
        ],
      ),
    );
  }
}

_HarnessState _state(WidgetTester tester) =>
    tester.state<_HarnessState>(find.byType(_Harness));

/// What holds primary focus: a card, a star or the action button.
String stop(WidgetTester tester) {
  final focus = FocusManager.instance.primaryFocus!;
  final cards = tester.widgetList<KSeekStyleCard>(find.byType(KSeekStyleCard));
  for (final card in cards) {
    if (card.focusNode == focus) return 'card ${card.title}';
  }
  final button = focus.context?.findAncestorWidgetOfExactType<KIconButton>();
  if (button != null) return 'star ${button.tooltip}';
  return 'action';
}

/// Presses Tab until [wanted] holds focus (at most a few times).
Future<void> tabTo(WidgetTester tester, String wanted) async {
  for (var i = 0; i < 8; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    if (stop(tester) == wanted) return;
  }
  fail('Tab never reached "$wanted"');
}

void main() {
  testWidgets('the card, its star and its action are separate nodes', (
    tester,
  ) async {
    useWindow(tester, const Size(500, 900));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(const _Harness()));
    expect(bySemanticsSelected('Vạch'), findsOneWidget);
    expect(bySemanticsSelected('Thanh phẳng'), findsNothing);
    // The star is its own toggle node, on for the fallback card only.
    expect(byToggledState('Hiện khi chưa có sóng', on: true), findsOneWidget);
    expect(
      byToggledState('Dùng Vạch khi chưa có sóng', on: false),
      findsOneWidget,
    );
    // The action is a button node of its own, on the chosen card only.
    expect(find.bySemanticsLabel('Tuỳ chỉnh'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('only eligible cards carry a star', (tester) async {
    useWindow(tester, const Size(500, 900));
    await tester.pumpWidget(host(const _Harness()));
    expect(byIconButton('Dùng Vạch khi chưa có sóng'), findsOneWidget);
    expect(byIconButton('Hiện khi chưa có sóng'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is KIconButton && w.selected != null),
      findsNWidgets(2),
    );
  });

  testWidgets('toggling a star moves it and never changes the choice', (
    tester,
  ) async {
    useWindow(tester, const Size(500, 900));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(const _Harness()));
    await tester.tap(byIconButton('Dùng Vạch khi chưa có sóng'));
    await tester.pump();
    expect(_state(tester).fallback, _Kind.bars);
    expect(_state(tester).selected, _Kind.bars);
    expect(byToggledState('Hiện khi chưa có sóng', on: true), findsOneWidget);
    expect(bySemanticsSelected('Vạch'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('tapping the filled star does nothing', (tester) async {
    useWindow(tester, const Size(500, 900));
    await tester.pumpWidget(host(const _Harness()));
    await tester.tap(byIconButton('Hiện khi chưa có sóng'));
    await tester.pump();
    expect(_state(tester).fallback, _Kind.flat);
    expect(_state(tester).selected, _Kind.bars);
    expect(_state(tester).reopened, isEmpty);
  });

  testWidgets('Tab reaches the star of an unselected card', (tester) async {
    useWindow(tester, const Size(500, 900));
    await tester.pumpWidget(host(const _Harness()));
    final stops = <String>[];
    for (var i = 0; i < 6; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      stops.add(stop(tester));
    }
    expect(stops, contains('star Hiện khi chưa có sóng'));
    expect(_state(tester).selected, _Kind.bars, reason: 'Tab never chooses');
  });

  testWidgets('Tab order: every card, then its star, then its action', (
    tester,
  ) async {
    useWindow(tester, const Size(500, 900));
    await tester.pumpWidget(host(const _Harness()));
    final stops = <String>[];
    for (var i = 0; i < 6; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      stops.add(stop(tester));
    }
    expect(stops, [
      'card Vạch',
      'star Dùng Vạch khi chưa có sóng',
      'action',
      'card Dạng sóng',
      'card Thanh phẳng',
      'star Hiện khi chưa có sóng',
    ]);
  });

  testWidgets('arrow keys on the star leave the choice, on the card move it', (
    tester,
  ) async {
    useWindow(tester, const Size(500, 900));
    await tester.pumpWidget(host(const _Harness(initial: _Kind.wave)));
    // Focus the star of the (unchosen) flat card directly.
    final flatStar = byIconButton('Hiện khi chưa có sóng');
    Focus.of(tester.element(flatStar)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(_state(tester).selected, _Kind.wave, reason: 'star ignores arrows');
    // Tab to the chosen card, then the arrow moves the choice.
    await tabTo(tester, 'card Dạng sóng');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(_state(tester).selected, _Kind.bars);
  });

  testWidgets('Enter and Space on the chosen card reopen it', (tester) async {
    useWindow(tester, const Size(500, 900));
    await tester.pumpWidget(host(const _Harness(initial: _Kind.wave)));
    await tabTo(tester, 'card Dạng sóng');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(_state(tester).selected, _Kind.flat);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(_state(tester).selected, _Kind.wave);
    // Enter / Space on a card that is already chosen: no choice change.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(_state(tester).selected, _Kind.wave);
    expect(_state(tester).reopened, [_Kind.wave]);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(_state(tester).reopened, [_Kind.wave, _Kind.wave]);
  });

  testWidgets('Enter and Space on an unselected card select it', (
    tester,
  ) async {
    useWindow(tester, const Size(500, 900));
    await tester.pumpWidget(host(const _Harness()));
    await tabTo(tester, 'card Dạng sóng');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(_state(tester).selected, _Kind.wave);
    await tabTo(tester, 'card Thanh phẳng');
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(_state(tester).selected, _Kind.flat);
    expect(_state(tester).reopened, isEmpty);
  });

  testWidgets('a tap on an unchosen card chooses it', (tester) async {
    useWindow(tester, const Size(500, 900));
    await tester.pumpWidget(host(const _Harness()));
    await tester.tap(find.text('Dạng sóng'));
    await tester.pump();
    expect(_state(tester).selected, _Kind.wave);
    expect(_state(tester).reopened, isEmpty);
  });

  testWidgets('the action shows on the chosen card only and stretches', (
    tester,
  ) async {
    useWindow(tester, const Size(500, 900));
    await tester.pumpWidget(host(const _Harness()));
    expect(find.text('Tuỳ chỉnh'), findsOneWidget);
    final card = tester.getRect(
      find.ancestor(
        of: find.text('Tuỳ chỉnh'),
        matching: find.byType(KSeekStyleCard),
      ),
    );
    final button = tester.getRect(
      find.ancestor(
        of: find.text('Tuỳ chỉnh'),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(button.height, 32);
    expect(button.width, closeTo(card.width - 2 * 12, 0.5));
    await tester.tap(find.text('Tuỳ chỉnh'));
    expect(_state(tester).customised, [_Kind.bars]);
    await tester.tap(find.text('Thanh phẳng'));
    await tester.pump();
    expect(find.text('Tuỳ chỉnh'), findsOneWidget);
    expect(_state(tester).selected, _Kind.flat);
  });

  testWidgets('re-tapping the chosen card fires the reselect callback', (
    tester,
  ) async {
    useWindow(tester, const Size(500, 900));
    await tester.pumpWidget(host(const _Harness()));
    await tester.tap(find.text('Vạch'));
    await tester.pump();
    expect(_state(tester).reopened, [_Kind.bars]);
    expect(_state(tester).selected, _Kind.bars);
  });

  testWidgets('200 % text: one column, star stays at the end of the title', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 900));
    await tester.pumpWidget(host(const _Harness(longName: true), textScale: 2));
    await tester.pump();
    expect(tester.takeException(), isNull);
    final cards = find.byType(KSeekStyleCard);
    expect(
      tester.getTopLeft(cards.at(1)).dx,
      tester.getTopLeft(cards.at(0)).dx,
      reason: 'one column',
    );
    final card = tester.getRect(cards.first);
    final star = tester.getRect(
      find
          .descendant(
            of: cards.first,
            matching: find.byWidgetPredicate(
              (w) => w is KIconButton && w.selected != null,
            ),
          )
          .first,
    );
    final title = tester.getRect(find.text('Vạch rất dài' * 6));
    expect(star.right, lessThanOrEqualTo(card.right));
    expect(star.left, greaterThanOrEqualTo(title.right - 0.5));
    expect(star.top, lessThan(title.top + 40), reason: 'on the first line');
  });

  testWidgets('renders in light, dark and with animations off', (tester) async {
    useWindow(tester, const Size(500, 900));
    for (final (_, brightness, scale) in hostVariants) {
      await tester.pumpWidget(
        host(const _Harness(), brightness: brightness, textScale: scale),
      );
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(host(const _Harness(), reduceMotion: true));
    expect(tester.takeException(), isNull);
  });
}
