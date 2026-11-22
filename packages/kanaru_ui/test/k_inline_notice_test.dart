import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

const _msg = 'Đang tắt ghi lịch sử nghe. Những gì đã ghi vẫn còn.';

Widget _notice({
  String? title,
  String message = _msg,
  KInlineNoticeTone tone = KInlineNoticeTone.normal,
  String? action,
  VoidCallback? onAction,
  String? actionSemantics,
}) => KInlineNotice(
  icon: KIcons.info,
  title: title,
  message: message,
  tone: tone,
  actionLabel: action,
  onAction: onAction,
  actionSemanticsLabel: actionSemantics,
);

Color _iconColor(WidgetTester tester) =>
    tester.widget<Icon>(find.byIcon(KIcons.info)).color!;

void main() {
  testWidgets('icon, text and action share the first line', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(_notice(message: 'Đã tắt ghi.', action: 'Bật', onAction: () {})),
    );
    expect(find.text('Đã tắt ghi.'), findsOneWidget);
    expect(find.text('Bật'), findsOneWidget);
    final line = tester.getRect(find.text('Đã tắt ghi.'));
    final button = tester.getRect(find.byType(TextButton));
    expect((button.center.dy - line.center.dy).abs(), lessThan(6));
    expect(button.left, greaterThan(line.right - 1));
  });

  testWidgets('text only has no button', (tester) async {
    await tester.pumpWidget(host(_notice()));
    expect(find.byType(TextButton), findsNothing);
    expect(find.text(_msg), findsOneWidget);
  });

  testWidgets('title sits above the message', (tester) async {
    await tester.pumpWidget(host(_notice(title: 'Tệp này thiếu thẻ')));
    expect(
      tester.getTopLeft(find.text('Tệp này thiếu thẻ')).dy,
      lessThan(tester.getTopLeft(find.text(_msg)).dy),
    );
  });

  testWidgets('error tone recolours only the icon', (tester) async {
    await tester.pumpWidget(host(_notice()));
    final scheme = Theme.of(tester.element(find.byType(KInlineNotice)))
        .colorScheme;
    expect(_iconColor(tester), scheme.primary);
    await tester.pumpWidget(host(_notice(tone: KInlineNoticeTone.error)));
    expect(_iconColor(tester), scheme.error);
    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(KInlineNotice),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(
      (box.decoration as BoxDecoration).color,
      scheme.surfaceContainerHigh,
    );
  });

  testWidgets('long Vietnamese text wraps without overflow', (tester) async {
    useWindow(tester, const Size(300, 800));
    final long = List.filled(3, _msg).join(' ');
    await tester.pumpWidget(
      host(_notice(message: long, action: 'Bật', onAction: () {})),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.text(long)).height, greaterThan(60));
  });

  testWidgets('200 % text puts the button under the text, right aligned', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(_notice(action: 'Bật', onAction: () {}), textScale: 2.0),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(find.byType(TextButton)).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(find.text(_msg)).dy),
    );
    expect(
      tester.getRect(find.byType(TextButton)).right,
      greaterThan(tester.getRect(find.byType(KInlineNotice)).right - 24),
    );
  });

  for (final (name, brightness, _) in hostVariants) {
    testWidgets('renders in $name', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(
          _notice(action: 'Bật', onAction: () {}),
          brightness: brightness,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text(_msg), findsOneWidget);
    });
  }

  testWidgets('tap runs the action; label for screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      host(
        _notice(
          action: 'Bật',
          onAction: () => taps++,
          actionSemantics: 'Bật ghi lịch sử nghe',
        ),
      ),
    );
    expect(find.bySemanticsLabel('Bật ghi lịch sử nghe'), findsOneWidget);
    await tester.tap(find.text('Bật'));
    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('action label doubles as semantics label by default', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(_notice(action: 'Bật', onAction: () {})));
    expect(find.bySemanticsLabel('Bật'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('is a polite live region', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(_notice()));
    final node = tester.getSemantics(find.text(_msg));
    expect(node.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
    handle.dispose();
  });

  testWidgets('screen reader can activate the action', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      host(
        _notice(
          action: 'Bật',
          onAction: () => taps++,
          actionSemantics: 'Bật ghi lịch sử nghe',
        ),
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Bật ghi lịch sử nghe')),
      isSemantics(
        label: 'Bật ghi lịch sử nghe',
        isButton: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    tester.semantics.tap(find.semantics.byLabel('Bật ghi lịch sử nghe'));
    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('stacks the button from 1.5x, not below', (tester) async {
    useWindow(tester, const Size(400, 800));
    Future<bool> stacked(double scale) async {
      await tester.pumpWidget(
        host(
          _notice(action: 'Bật', onAction: () {}),
          textScale: scale,
        ),
      );
      return tester.getTopLeft(find.byType(TextButton)).dy >=
          tester.getBottomLeft(find.text(_msg)).dy;
    }

    expect(await stacked(1.49), isFalse);
    expect(await stacked(1.5), isTrue);
  });

  testWidgets('action label without handler is rejected', (tester) async {
    expect(
      () => KInlineNotice(icon: KIcons.info, message: _msg, actionLabel: 'Bật'),
      throwsAssertionError,
    );
  });

  testWidgets('filled tones tint the strip and keep the action', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      host(
        _notice(
          tone: KInlineNoticeTone.errorFilled,
          action: 'Thử lại',
          onAction: () => tapped = true,
        ),
      ),
    );
    final scheme = Theme.of(tester.element(find.byType(KInlineNotice)))
        .colorScheme;
    Color? fill() {
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(KInlineNotice),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      return (box.decoration as BoxDecoration).color;
    }

    expect(fill(), scheme.errorContainer);
    expect(_iconColor(tester), scheme.onErrorContainer);
    await tester.tap(find.text('Thử lại'));
    expect(tapped, isTrue);
    await tester.pumpWidget(
      host(_notice(tone: KInlineNoticeTone.primaryFilled)),
    );
    expect(fill(), scheme.primaryContainer);
    await tester.pumpWidget(host(_notice(tone: KInlineNoticeTone.error)));
    expect(fill(), scheme.surfaceContainerHigh);
    expect(_iconColor(tester), scheme.error);
  });

  testWidgets('a busy action is a spinner that cannot be pressed again', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    var taps = 0;
    await tester.pumpWidget(
      host(
        KInlineNotice(
          icon: KIcons.info,
          message: 'Có bản mới.',
          actionLabel: 'Cập nhật',
          onAction: () => taps++,
          actionBusy: true,
          actionBusyLabel: 'Đang xử lý',
        ),
      ),
    );
    expect(find.text('Cập nhật'), findsNothing);
    expect(find.bySemanticsLabel('Đang xử lý'), findsOneWidget);
    await tester.tap(find.byType(TextButton), warnIfMissed: false);
    expect(taps, 0);
  });
}
