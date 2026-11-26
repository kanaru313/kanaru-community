import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/finders.dart';
import '../support/host.dart';

const _previewKey = ValueKey('preview');

Widget _frame({
  bool resetEnabled = true,
  VoidCallback? onReset,
  VoidCallback? onClose,
  String? caption,
  String value = 'a',
  ValueChanged<String>? onChanged,
  int rows = 1,
}) => KCustomiseSheetFrame(
  title: 'Tuỳ chỉnh · Lượn',
  closeTooltip: 'Đóng',
  onClose: onClose ?? () {},
  preview: const SizedBox(key: _previewKey, height: 56),
  caption: caption,
  resetLabel: 'Đặt lại mặc định',
  resetEnabled: resetEnabled,
  onReset: onReset ?? () {},
  children: [
    for (var i = 0; i < rows; i++)
      KSegmentedRow<String>(
        title: 'Chuyển động $i',
        segments: const [
          KSegment(value: 'a', label: 'Theo nhạc'),
          KSegment(value: 'b', label: 'Đều'),
        ],
        value: value,
        onChanged: onChanged ?? (_) {},
      ),
  ],
);

void main() {
  testWidgets('reset is disabled while everything is default', (tester) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    var resets = 0;
    await tester.pumpWidget(
      host(_frame(resetEnabled: false, onReset: () => resets++)),
    );
    expect(byEnabledState('Đặt lại mặc định', enabled: false), findsOneWidget);
    await tester.tap(find.text('Đặt lại mặc định'));
    expect(resets, 0);
    handle.dispose();
  });

  testWidgets('reset is enabled after a change and fires without a confirm', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    var resets = 0;
    await tester.pumpWidget(host(_frame(onReset: () => resets++)));
    expect(byEnabledState('Đặt lại mặc định', enabled: true), findsOneWidget);
    await tester.tap(find.text('Đặt lại mặc định'));
    await tester.pump();
    expect(resets, 1);
    expect(find.byType(Dialog), findsNothing);
    handle.dispose();
  });

  testWidgets('the close button fires its callback', (tester) async {
    useWindow(tester, const Size(400, 800));
    var closed = 0;
    await tester.pumpWidget(host(_frame(onClose: () => closed++)));
    await tester.tap(byIconButton('Đóng'));
    expect(closed, 1);
    expect(find.text('Tuỳ chỉnh · Lượn'), findsOneWidget);
  });

  testWidgets('a segmented row reports the choice, tonal and without a tick', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    final chosen = <String>[];
    await tester.pumpWidget(host(_frame(onChanged: chosen.add)));
    expect(bySemanticsSelected('Theo nhạc'), findsOneWidget);
    expect(bySemanticsSelected('Đều'), findsNothing);
    await tester.tap(find.text('Đều'));
    expect(chosen, ['b']);
    expect(byCheckState(KCheckState.on), findsNothing);
    handle.dispose();
  });

  testWidgets('the caption sits under the preview, before the rows', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(_frame(caption: 'Bài chưa có dạng sóng thì trôi đều.')),
    );
    final preview = tester.getRect(find.byKey(_previewKey));
    final caption = tester.getRect(
      find.text('Bài chưa có dạng sóng thì trôi đều.'),
    );
    final row = tester.getRect(find.text('Chuyển động 0'));
    expect(caption.top, greaterThanOrEqualTo(preview.bottom));
    expect(row.top, greaterThan(caption.bottom));
  });

  testWidgets('segmented rows are 48 high on mobile and 40 on desktop', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_frame()));
    expect(tester.getSize(find.byType(KSegmented<String>)).height, 48);
    useWindow(tester, const Size(1300, 800));
    await tester.pumpWidget(host(_frame()));
    final size = tester.getSize(find.byType(KSegmented<String>));
    expect(size.height, 40);
    expect(size.width, lessThanOrEqualTo(420));
  });

  testWidgets('200 % text: no overflow, the body scrolls to the reset', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 600));
    await tester.pumpWidget(
      host(SizedBox(height: 500, child: _frame(rows: 4)), textScale: 2),
    );
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Đặt lại mặc định'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Đặt lại mặc định').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('renders without overflow ($name)', (tester) async {
      useWindow(tester, const Size(360, 800));
      await tester.pumpWidget(
        host(
          _frame(caption: 'Ghi chú'),
          brightness: brightness,
          textScale: scale,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
