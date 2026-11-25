import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

const _total = Duration(seconds: 100);
const _cancel = 'Release to cancel';

String _label(Duration d) => 't${d.inSeconds}';

KSeekState _state({
  double? pointer,
  bool holding = false,
  bool dragging = false,
  bool cancelling = false,
  bool seekable = true,
  double width = 200,
}) => KSeekState(
  progress: 0.2,
  width: width,
  active: holding || dragging,
  seekable: seekable,
  holding: holding,
  dragging: dragging,
  cancelling: cancelling,
  pointerFraction: pointer,
);

Widget _bubble(
  KSeekState state, {
  Duration? duration = _total,
  String? cancelLabel = _cancel,
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) => host(
  Center(
    child: SizedBox(
      key: const ValueKey('bar'),
      width: state.width,
      height: 56,
      child: KSeekTimeBubble(
        state: state,
        duration: duration,
        label: _label,
        cancelLabel: cancelLabel,
        horizontalInset: 6,
        child: const SizedBox.expand(),
      ),
    ),
  ),
  brightness: brightness,
  textScale: textScale,
);

Color _fill(WidgetTester tester, String text) {
  final box = tester.widget<DecoratedBox>(
    find.ancestor(of: find.text(text), matching: find.byType(DecoratedBox)),
  );
  return (box.decoration as ShapeDecoration).color!;
}

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('draws above the bar in $name', (tester) async {
      await tester.pumpWidget(
        _bubble(
          _state(pointer: 0.5, dragging: true),
          brightness: brightness,
          textScale: scale,
        ),
      );
      final bar = tester.getRect(find.byKey(const ValueKey('bar')));
      final text = tester.getRect(find.text('t50'));
      expect(text.bottom, lessThanOrEqualTo(bar.top - seekBubbleGap));
      expect(text.center.dx, moreOrLessEquals(bar.center.dx, epsilon: 1));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('hidden unless held or dragged', (tester) async {
    await tester.pumpWidget(_bubble(_state(pointer: 0.5)));
    expect(find.text('t50'), findsNothing);
    await tester.pumpWidget(_bubble(_state(pointer: 0.5, holding: true)));
    expect(find.text('t50'), findsOneWidget);
    await tester.pumpWidget(_bubble(_state(holding: true)));
    expect(find.text('t50'), findsNothing);
  });

  testWidgets('hidden without a duration or when not seekable', (tester) async {
    await tester.pumpWidget(
      _bubble(_state(pointer: 0.5, dragging: true), duration: null),
    );
    expect(find.byType(Text), findsNothing);
    await tester.pumpWidget(
      _bubble(_state(pointer: 0.5, dragging: true, seekable: false)),
    );
    expect(find.text('t50'), findsNothing);
  });

  testWidgets('time on inverseSurface, cancel on errorContainer', (
    tester,
  ) async {
    await tester.pumpWidget(_bubble(_state(pointer: 0.3, dragging: true)));
    final scheme = Theme.of(tester.element(find.text('t30'))).colorScheme;
    expect(_fill(tester, 't30'), scheme.inverseSurface);
    await tester.pumpWidget(
      _bubble(_state(pointer: 0.3, dragging: true, cancelling: true)),
    );
    expect(find.text('t30'), findsNothing);
    expect(find.text(_cancel), findsOneWidget);
    expect(_fill(tester, _cancel), scheme.errorContainer);
  });

  testWidgets('cancelling without a cancel label keeps the time', (
    tester,
  ) async {
    await tester.pumpWidget(
      _bubble(
        _state(pointer: 0.3, dragging: true, cancelling: true),
        cancelLabel: null,
      ),
    );
    expect(find.text('t30'), findsOneWidget);
  });

  testWidgets('kept off both ends of the bar', (tester) async {
    await tester.pumpWidget(_bubble(_state(pointer: 0, dragging: true)));
    final bar = tester.getRect(find.byKey(const ValueKey('bar')));
    expect(
      tester.getRect(find.text('t0')).center.dx,
      moreOrLessEquals(bar.left + 32, epsilon: 0.5),
    );
    await tester.pumpWidget(_bubble(_state(pointer: 1, dragging: true)));
    final right = tester.getRect(
      find.ancestor(of: find.text('t100'), matching: find.byType(DecoratedBox)),
    );
    expect(right.center.dx, lessThanOrEqualTo(bar.right - 32 + 0.5));
    expect(right.right, lessThanOrEqualTo(bar.right + 0.5));
    // A label wider than 64 dp keeps its whole box on the bar.
    await tester.pumpWidget(
      _bubble(_state(pointer: 0, dragging: true, cancelling: true)),
    );
    final box = tester.getRect(
      find.ancestor(
        of: find.text(_cancel),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(box.left, greaterThanOrEqualTo(bar.left - 0.5));
  });

  testWidgets('a narrow bar centres the bubble', (tester) async {
    await tester.pumpWidget(
      _bubble(_state(pointer: 0, dragging: true, width: 40)),
    );
    final bar = tester.getRect(find.byKey(const ValueKey('bar')));
    expect(
      tester.getRect(find.text('t0')).center.dx,
      moreOrLessEquals(bar.center.dx, epsilon: 0.5),
    );
  });

  testWidgets('leaves with the bar', (tester) async {
    await tester.pumpWidget(_bubble(_state(pointer: 0.5, dragging: true)));
    expect(find.text('t50'), findsOneWidget);
    await tester.pumpWidget(host(const SizedBox()));
    expect(find.text('t50'), findsNothing);
  });

  testWidgets('says nothing to a screen reader: the slider speaks', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_bubble(_state(pointer: 0.5, dragging: true)));
    expect(find.bySemanticsLabel('t50'), findsNothing);
    handle.dispose();
  });
}
