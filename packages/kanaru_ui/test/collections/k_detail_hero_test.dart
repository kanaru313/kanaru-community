import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';
import '../support/scaled_host.dart';

const _longTitle =
    'Những bài hát hay nhất của Trịnh Công Sơn tuyển tập đặc biệt';

BorderRadius? lastRadius;

Widget _page({
  bool circle = false,
  String title = 'Album',
  KDetailLine? line2 = const KDetailLine(text: 'by artist', trailing: '2020'),
  String? line3 = '3 songs',
  Widget? description,
}) => KDetailLayout(
  header: KDetailHero(
    circle: circle,
    title: title,
    line2: line2,
    line3: line3,
    description: description,
    coverBuilder: (context, side, radius) {
      lastRadius = radius;
      return ColoredBox(
        key: const ValueKey('cover'),
        color: const Color(0xFFFF0000),
        child: SizedBox.square(dimension: side),
      );
    },
    actions: const Text('buttons'),
  ),
  slivers: [
    SliverList.builder(
      itemCount: 5,
      itemBuilder: (_, i) => SizedBox(height: 48, child: Text('row $i')),
    ),
  ],
);

void main() {
  testWidgets('narrow: 132 cover on the left, text centred on it', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_page()));
    expect(tester.getSize(find.byKey(const ValueKey('cover'))).width, 132);
    final cover = tester.getRect(find.byKey(const ValueKey('cover')));
    final top = tester.getRect(find.text('Album')).top;
    final bottom = tester.getRect(find.text('buttons')).bottom;
    expect(tester.getRect(find.text('buttons')).left, greaterThan(cover.right));
    expect((top + bottom) / 2, closeTo(cover.center.dy, 1));
  });

  testWidgets('wide: 320 cover column, lines in order under the cover', (
    tester,
  ) async {
    useWindow(tester, const Size(840, 800));
    await tester.pumpWidget(host(_page()));
    expect(tester.getSize(find.byKey(const ValueKey('cover'))).width, 320);
    final cover = tester.getRect(find.byKey(const ValueKey('cover')));
    final ys = [
      for (final t in ['Album', 'by artist', '3 songs', 'buttons'])
        tester.getTopLeft(find.text(t)).dy,
    ];
    expect(ys.first, greaterThanOrEqualTo(cover.bottom));
    expect(ys, orderedEquals([...ys]..sort()));
    // Only the bottom edge fades.
    expect(find.byType(ShaderMask), findsOneWidget);
    expect(lastRadius, BorderRadius.zero);
  });

  testWidgets(
    'wide: the cover is opaque at the right edge, clear at the foot',
    (tester) async {
      useWindow(tester, const Size(840, 800));
      final key = GlobalKey();
      await tester.pumpWidget(host(RepaintBoundary(key: key, child: _page())));
      final cover = tester.getRect(find.byKey(const ValueKey('cover')));
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = (await tester.runAsync(() async {
        final image = await boundary.toImage();
        return image.toByteData();
      }))!;
      final width = boundary.size.width.toInt();
      int alphaAt(double x, double y) =>
          bytes.getUint8((y.toInt() * width + x.toInt()) * 4 + 3);
      // Top right corner and mid-height of the right edge: not faded.
      expect(alphaAt(cover.right - 2, cover.top + 2), 255);
      expect(alphaAt(cover.right - 2, cover.center.dy), 255);
      // Last pixels of the foot: nearly clear (the page ground is transparent).
      expect(alphaAt(cover.center.dx, cover.bottom - 1), lessThan(20));
    },
  );

  testWidgets('narrow: the cover is round', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_page()));
    expect(lastRadius, KDetailHero.narrowCoverRadius);
  });

  testWidgets('a round photo is not faded', (tester) async {
    useWindow(tester, const Size(1300, 800));
    await tester.pumpWidget(host(_page(circle: true)));
    expect(find.byType(ShaderMask), findsNothing);
    expect(tester.getSize(find.byKey(const ValueKey('cover'))).width, 288);
  });

  testWidgets('a long Vietnamese title is two lines narrow, three wide', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_page()));
    final oneNarrow = tester.getSize(find.text('Album')).height;
    await tester.pumpWidget(host(_page(title: _longTitle)));
    expect(
      tester.getSize(find.text(_longTitle)).height,
      closeTo(oneNarrow * 2, 1),
    );
    useWindow(tester, const Size(840, 800));
    await tester.pumpWidget(host(_page()));
    final oneWide = tester.getSize(find.text('Album')).height;
    await tester.pumpWidget(
      host(_page(title: '$_longTitle $_longTitle $_longTitle')),
    );
    expect(
      tester.getSize(find.text('$_longTitle $_longTitle $_longTitle')).height,
      closeTo(oneWide * 3, 1),
    );
  });

  testWidgets('empty line 2 and line 3 leave no widget', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_page(line2: null, line3: '')));
    expect(find.byType(KDetailLine), findsNothing);
    expect(find.text('3 songs'), findsNothing);
    await tester.pumpWidget(host(_page(line2: null, line3: null)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the hero is as tall with a link on line 2 as with plain text', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        _page(
          line2: KDetailLine(text: 'by artist', onTap: () {}),
        ),
      ),
    );
    final link = tester.getSize(find.byType(KDetailHero)).height;
    await tester.pumpWidget(host(_page()));
    expect(tester.getSize(find.byType(KDetailHero)).height, link);
  });

  for (final width in [400.0, 1000.0]) {
    testWidgets('200% text does not overflow at $width', (tester) async {
      useWindow(tester, Size(width, 800));
      await tester.pumpWidget(
        scaledHost(_page(title: _longTitle), textScale: 2),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('narrow: the description runs under the whole row', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_page(description: const Text('about'))));
    final cover = tester.getRect(find.byKey(const ValueKey('cover')));
    final about = tester.getRect(find.text('about'));
    expect(about.top, greaterThanOrEqualTo(cover.bottom + 12));
    expect(
      about.left,
      tester.getRect(find.byKey(const ValueKey('cover'))).left,
    );
  });

  testWidgets('wide: the description sits under the buttons', (tester) async {
    useWindow(tester, const Size(840, 800));
    await tester.pumpWidget(host(_page(description: const Text('about'))));
    expect(
      tester.getTopLeft(find.text('about')).dy,
      greaterThanOrEqualTo(tester.getRect(find.text('buttons')).bottom + 12),
    );
  });

  testWidgets('the title is a semantics header', (tester) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(_page()));
    expect(
      tester.getSemantics(find.text('Album')),
      isSemantics(isHeader: true, label: 'Album'),
    );
    handle.dispose();
  });

  testWidgets('the year stays whole at 200% text in the narrow hero', (
    tester,
  ) async {
    useWindow(tester, const Size(480, 800));
    await tester.pumpWidget(scaledHost(_page(), textScale: 2));
    final year = find.text(' · 2020');
    final painter = TextPainter(
      text: TextSpan(text: ' · 2020', style: tester.widget<Text>(year).style),
      textDirection: TextDirection.ltr,
      textScaler: const TextScaler.linear(2),
      maxLines: 1,
    )..layout();
    expect(tester.getSize(year).width, closeTo(painter.width, 0.5));
    painter.dispose();
    expect(tester.takeException(), isNull);
  });
}
