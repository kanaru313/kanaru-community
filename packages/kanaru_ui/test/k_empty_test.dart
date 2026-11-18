import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

Widget _empty({String? title, List<Widget> actions = const []}) => KEmpty(
  icon: KIcons.heart,
  title: title,
  message: 'Thêm bài hát vào danh sách phát để nghe lại sau, ở bất kỳ đâu.',
  actions: actions,
);

void main() {
  testWidgets('title above message, actions after it', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        _empty(
          title: 'Chưa có playlist',
          actions: [
            FilledButton(onPressed: () {}, child: const Text('Tạo playlist')),
            OutlinedButton(onPressed: () {}, child: const Text('Nhập tệp M3U')),
          ],
        ),
      ),
    );
    final title = tester.getTopLeft(find.text('Chưa có playlist')).dy;
    final message = tester.getTopLeft(find.textContaining('Thêm bài')).dy;
    final action = tester.getTopLeft(find.text('Tạo playlist')).dy;
    expect(title, lessThan(message));
    expect(message, lessThan(action));
    expect(find.text('Nhập tệp M3U'), findsOneWidget);
  });

  testWidgets("without title or actions it is today's empty state", (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_empty()));
    expect(find.byType(Wrap), findsNothing);
    expect(find.textContaining('Thêm bài'), findsOneWidget);
  });

  testWidgets('the single action still shows', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        KEmpty(
          icon: KIcons.heart,
          message: 'm',
          action: FilledButton(onPressed: () {}, child: const Text('Go')),
        ),
      ),
    );
    expect(find.text('Go'), findsOneWidget);
  });

  testWidgets('long text at 200 % on a 360 px phone does not overflow', (
    tester,
  ) async {
    useWindow(tester, const Size(360, 640));
    await tester.pumpWidget(
      host(
        textScale: 2,
        _empty(
          title: 'Chưa có playlist nào trong thư viện của bạn',
          actions: [
            FilledButton(
              onPressed: () {},
              child: const Text('Tạo playlist mới'),
            ),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Nhập tệp M3U…'),
            ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('inline icon replaces the token, themed, one spoken sentence', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        KEmpty(
          icon: KIcons.heart,
          message: 'Tap [icon] on a song.',
          messageIcon: KIcons.heartFilled,
          messageIconLabel: 'favorite',
        ),
      ),
    );
    final scheme = Theme.of(tester.element(find.byType(KEmpty))).colorScheme;
    final inline = find.descendant(
      of: find.byType(RichText),
      matching: find.byIcon(KIcons.heartFilled),
    );
    expect(inline, findsOneWidget);
    expect(tester.widget<Icon>(inline).color, scheme.primary);
    expect(find.textContaining('Tap ', findRichText: true), findsOneWidget);
    expect(find.textContaining('[icon]', findRichText: true), findsNothing);
    expect(find.bySemanticsLabel('Tap favorite on a song.'), findsOneWidget);
    handle.dispose();
  });
}
