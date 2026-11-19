import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:kanaru_ui/src/widgets/k_focus_ring.dart';
import 'package:material_ui/material_ui.dart';

import '../support/finders.dart';
import '../support/host.dart';

const _sizes = [0, 100, 200, 300, 1000, 1500, 10000]; // uneven, KB

String _size(int kb) => kb == 0 ? 'Tắt' : '$kb KB';

KStopSliderSpec<int> _spec(List<int> commits, {int value = 200}) =>
    KStopSliderSpec<int>(
      stops: _sizes,
      value: value,
      liveLabel: _size,
      minLabel: 'Tắt',
      maxLabel: '10 MB',
      onCommitted: commits.add,
    );

Future<void> _open(
  WidgetTester tester,
  List<KSliderSpec> sliders, {
  double textScale = 1,
  bool reduceMotion = false,
}) async {
  await tester.pumpWidget(
    host(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showSliderSheet(
            context,
            title: const Text('Bỏ qua tệp nhỏ hơn'),
            caption: const Text('Tệp nhỏ hơn mức này không được quét.'),
            sliders: sliders,
          ),
          child: const Text('open'),
        ),
      ),
      textScale: textScale,
      reduceMotion: reduceMotion,
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows title, caption, live label and both end labels', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await _open(tester, [_spec([])]);
    expect(find.text('Bỏ qua tệp nhỏ hơn'), findsOneWidget);
    expect(find.text('Tệp nhỏ hơn mức này không được quét.'), findsOneWidget);
    expect(find.text('200 KB'), findsOneWidget);
    expect(find.text('10 MB'), findsOneWidget);
    expect(bySliderValue('200 KB'), findsOneWidget);
    expect(tester.widget<Slider>(find.byType(Slider)).divisions, 6);
  });

  testWidgets('dragging updates the live label, commits only on release', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final commits = <int>[];
    await _open(tester, [_spec(commits)]);
    final slider = find.byType(Slider);
    final gesture = await tester.startGesture(tester.getCenter(slider));
    await gesture.moveTo(tester.getTopRight(slider) - const Offset(30, -10));
    await tester.pump();
    expect(find.text('10000 KB'), findsOneWidget);
    expect(commits, isEmpty);
    await gesture.up();
    await tester.pump();
    expect(commits, [10000]);
  });

  testWidgets('uneven stops map by index; 0 shows the caller label', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final commits = <int>[];
    await _open(tester, [_spec(commits, value: 0)]);
    expect(bySliderValue('Tắt'), findsOneWidget);
    await tester.tapAt(tester.getCenter(find.byType(Slider)));
    await tester.pump();
    // The middle of a 7-stop slider is stop 3, not the numeric middle.
    expect(commits.last, 300);
  });

  testWidgets('arrow keys move one stop, are consumed, commit each step', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final commits = <int>[];
    var leaked = false;
    await tester.pumpWidget(
      host(
        Focus(
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent) leaked = true;
            return KeyEventResult.ignored;
          },
          child: _InlineBody(commits),
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(commits, [300, 200]);
    expect(leaked, isFalse, reason: 'slider consumes the arrows');
  });

  testWidgets('Home and End jump to the ends and commit', (tester) async {
    useWindow(tester, const Size(400, 800));
    final commits = <int>[];
    await tester.pumpWidget(host(_InlineBody(commits)));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    expect(commits, [10000, 0]);
  });

  testWidgets('two sliders of different types in one sheet', (tester) async {
    useWindow(tester, const Size(400, 900));
    final seconds = <int>[];
    final percent = <double>[];
    await _open(tester, [
      KStopSliderSpec<int>(
        stops: const [0, 10, 30, 60],
        value: 30,
        liveLabel: (s) => s == 0 ? 'Không dùng' : '$s giây',
        minLabel: 'Không dùng',
        maxLabel: '60 giây',
        onCommitted: seconds.add,
      ),
      KStopSliderSpec<double>(
        stops: const [0.1, 0.5, 1.0],
        value: 0.5,
        liveLabel: (p) => p == 1 ? 'hết bài' : '${(p * 100).round()} %',
        minLabel: '10 %',
        maxLabel: 'hết bài',
        onCommitted: percent.add,
      ),
    ]);
    expect(find.byType(Slider), findsNWidgets(2));
    expect(bySliderValue('30 giây'), findsOneWidget);
    expect(bySliderValue('50 %'), findsOneWidget);
  });

  testWidgets('desktop: opens as a panel anchored under the row', (
    tester,
  ) async {
    useWindow(tester, const Size(1400, 900));
    final key = GlobalKey();
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => Align(
            alignment: Alignment.topLeft,
            child: TextButton(
              key: key,
              onPressed: () => showSliderSheet(
                context,
                title: const Text('T'),
                sliders: [_spec([])],
                anchor: key,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(
      tester.getTopLeft(find.text('T')).dy,
      greaterThan(tester.getBottomLeft(find.text('open')).dy),
    );
  });

  testWidgets('desktop: anchorAlign end right-aligns the panel to the row', (
    tester,
  ) async {
    useWindow(tester, const Size(1400, 900));
    final key = GlobalKey();
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 600,
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  key: key,
                  onPressed: () => showSliderSheet(
                    context,
                    title: const Text('T'),
                    sliders: [_spec([])],
                    anchor: key,
                    anchorAlign: KAnchorAlign.end,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final panel = tester.getRect(
      find
          .descendant(
            of: find.byType(CustomSingleChildLayout),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(panel.right, closeTo(tester.getRect(find.byKey(key)).right, 1));
  });

  testWidgets('200 % text with long Vietnamese labels does not overflow', (
    tester,
  ) async {
    useWindow(tester, const Size(360, 800));
    await _open(tester, [
      KStopSliderSpec<int>(
        stops: const [0, 1],
        value: 1,
        liveLabel: (_) => 'Một khoảng thời gian rất dài để quan sát',
        minLabel: 'Không bao giờ bỏ qua tệp nào cả',
        maxLabel: 'Ba phút trở lên thì mới bỏ qua',
        onCommitted: (_) {},
      ),
    ], textScale: 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('animations off: still opens and works', (tester) async {
    useWindow(tester, const Size(400, 800));
    await _open(tester, [_spec([])], reduceMotion: true);
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('keyboard focus on the slider shows the ring', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_InlineBody(<int>[])));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(tester.widget<KFocusRing>(find.byType(KFocusRing)).visible, isTrue);
  });
}

/// A slider body without a route, for key tests.
class _InlineBody extends StatelessWidget {
  const _InlineBody(this.commits);

  final List<int> commits;

  @override
  Widget build(BuildContext context) => _spec(commits).build(autofocus: true);
}
