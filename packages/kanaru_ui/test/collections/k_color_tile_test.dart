import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

Color _fill(WidgetTester tester, Finder tile) => tester
    .widget<Material>(
      find.descendant(of: tile, matching: find.byType(Material)).first,
    )
    .color!;

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('tile renders ($name)', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(
          const Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 180,
              child: KColorTile(
                seed: 'Indie',
                title: 'Indie',
                subtitle: '120 songs',
                icon: KIcons.genres,
              ),
            ),
          ),
          brightness: brightness,
          textScale: scale,
        ),
      );
      expect(find.text('Indie'), findsOneWidget);
      expect(find.text('120 songs'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('banner renders ($name)', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(
          const KColorBanner(
            seed: 'Indie',
            icon: KIcons.genres,
            headline: '120 songs',
            caption: '12 artists',
            actions: Text('buttons'),
          ),
          brightness: brightness,
          textScale: scale,
        ),
      );
      expect(find.text('120 songs'), findsOneWidget);
      expect(find.text('12 artists'), findsOneWidget);
      expect(find.text('buttons'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the same seed gives the same colour, others differ', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    Widget tile(String key, String seed) => SizedBox(
      width: 150,
      child: KColorTile(
        key: ValueKey(key),
        seed: seed,
        title: seed,
        icon: KIcons.genres,
      ),
    );
    await tester.pumpWidget(
      host(
        Wrap(
          children: [tile('a', 'Indie'), tile('b', 'Indie'), tile('c', 'Rock')],
        ),
      ),
    );
    final a = _fill(tester, find.byKey(const ValueKey('a')));
    final b = _fill(tester, find.byKey(const ValueKey('b')));
    final c = _fill(tester, find.byKey(const ValueKey('c')));
    expect(a, b);
    expect(a, isNot(c));
  });

  testWidgets('dark mode uses a darker fill', (tester) async {
    useWindow(tester, const Size(400, 800));
    const tile = SizedBox(
      width: 150,
      child: KColorTile(seed: 'Indie', title: 'Indie', icon: KIcons.genres),
    );
    await tester.pumpWidget(host(tile));
    final light = _fill(tester, find.byType(KColorTile));
    await tester.pumpWidget(host(tile, brightness: Brightness.dark));
    await tester.pumpAndSettle();
    final dark = _fill(tester, find.byType(KColorTile));
    expect(
      HSLColor.fromColor(dark).lightness,
      lessThan(HSLColor.fromColor(light).lightness),
    );
  });

  testWidgets('tap and long press reach the callbacks', (tester) async {
    useWindow(tester, const Size(400, 800));
    var taps = 0;
    var longs = 0;
    await tester.pumpWidget(
      host(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 150,
            child: KColorTile(
              seed: 'x',
              title: 'Tap me',
              icon: KIcons.genres,
              onTap: () => taps++,
              onLongPress: () => longs++,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Tap me'));
    await tester.longPress(find.text('Tap me'));
    expect([taps, longs], [1, 1]);
  });
}
