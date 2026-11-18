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
  bool framedCover = false,
  List<double>? sides,
  Widget? actions,
}) => KDetailLayout(
  header: KDetailHero(
    circle: circle,
    framedCover: framedCover,
    title: title,
    line2: line2,
    line3: line3,
    description: description,
    coverBuilder: (context, side, radius) {
      lastRadius = radius;
      sides?.add(side);
      return ColoredBox(
        key: const ValueKey('cover'),
        color: const Color(0xFFFF0000),
        child: SizedBox.square(dimension: side),
      );
    },
    actions: actions ?? const Text('buttons'),
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

  group('framedCover', () {
    Finder card() => find.byKey(const ValueKey('cover')).last;

    testWidgets('wide: backdrop fills the column, card 240 centred on it', (
      tester,
    ) async {
      useWindow(tester, const Size(1000, 900));
      await tester.pumpWidget(host(_page(framedCover: true)));
      final covers = find.byKey(const ValueKey('cover'));
      expect(covers, findsNWidgets(2));
      final backdrop = tester.getRect(covers.first);
      final inner = tester.getRect(covers.last);
      expect(backdrop.size, const Size.square(320));
      expect(inner.size, const Size.square(KDetailHero.frameInnerSize));
      expect(inner.center.dx, closeTo(backdrop.center.dx, 0.5));
      expect(inner.center.dy, closeTo(backdrop.center.dy, 0.5));
    });

    testWidgets('wide: backdrop is washed out at 0.35 and faded, the card '
        'is not', (tester) async {
      useWindow(tester, const Size(1000, 900));
      await tester.pumpWidget(host(_page(framedCover: true)));
      final covers = find.byKey(const ValueKey('cover'));
      final opacity = tester.widget<Opacity>(
        find.ancestor(of: covers.first, matching: find.byType(Opacity)).first,
      );
      expect(opacity.opacity, KDetailHero.backdropOpacity);
      expect(KDetailHero.backdropOpacity, 0.35);
      expect(
        find.ancestor(of: covers.first, matching: find.byType(ShaderMask)),
        findsNWidgets(2),
      );
      expect(
        find.ancestor(of: card(), matching: find.byType(ShaderMask)),
        findsNothing,
      );
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('wide: the card has the 4 dp border and a radius 16 frame', (
      tester,
    ) async {
      useWindow(tester, const Size(1000, 900));
      await tester.pumpWidget(host(_page(framedCover: true)));
      final frame = tester.getRect(
        find.ancestor(of: card(), matching: find.byType(DecoratedBox)).first,
      );
      expect(frame.size, const Size.square(KDetailHero.frameSize));
      final deco =
          tester
                  .widget<DecoratedBox>(
                    find
                        .ancestor(
                          of: card(),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(deco.borderRadius, BorderRadius.circular(KDetailHero.frameRadius));
      expect(deco.boxShadow, isNotEmpty);
    });

    testWidgets('wide: the cover is built once, at the card side', (
      tester,
    ) async {
      useWindow(tester, const Size(1000, 900));
      final sides = <double>[];
      await tester.pumpWidget(host(_page(framedCover: true, sides: sides)));
      expect(sides.toSet(), {KDetailHero.frameInnerSize});
      expect(sides, hasLength(1));
    });

    testWidgets('wide: name has 2 lines, the default keeps 3', (tester) async {
      useWindow(tester, const Size(1000, 900));
      await tester.pumpWidget(
        host(_page(framedCover: true, title: _longTitle)),
      );
      int lines() => tester
          .widget<Text>(find.text(_longTitle, findRichText: false))
          .maxLines!;
      expect(lines(), 2);
      await tester.pumpWidget(host(_page(title: _longTitle)));
      expect(lines(), 3);
    });

    testWidgets('wide: the action row starts at the text edge', (tester) async {
      useWindow(tester, const Size(1000, 900));
      await tester.pumpWidget(
        host(
          _page(
            framedCover: true,
            actions: const Row(children: [Text('buttons')]),
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.text('buttons')).dx,
        tester.getTopLeft(find.text('Album')).dx,
      );
      expect(tester.getTopLeft(find.text('Album')).dx, 16);
    });

    testWidgets('narrow: unchanged, one 132 cover, framedCover ignored', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(_page(framedCover: true)));
      expect(find.byKey(const ValueKey('cover')), findsOneWidget);
      expect(tester.getSize(find.byKey(const ValueKey('cover'))).width, 132);
      expect(lastRadius, KDetailHero.narrowCoverRadius);
    });

    testWidgets('long name at 200 % text does not overflow', (tester) async {
      useWindow(tester, const Size(1000, 900));
      await tester.pumpWidget(
        scaledHost(_page(framedCover: true, title: _longTitle)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('wide: a description sits under the actions', (tester) async {
      useWindow(tester, const Size(1000, 900));
      await tester.pumpWidget(
        host(_page(framedCover: true, description: const Text('Xem thêm'))),
      );
      expect(
        tester.getTopLeft(find.text('Xem thêm')).dy,
        greaterThan(tester.getBottomLeft(find.text('buttons')).dy - 1),
      );
    });

    testWidgets('wide: dark theme builds the framed cover', (tester) async {
      useWindow(tester, const Size(1000, 900));
      await tester.pumpWidget(
        host(_page(framedCover: true), brightness: Brightness.dark),
      );
      expect(find.byKey(const ValueKey('cover')), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('wide: a short window scrolls the column, no overflow', (
      tester,
    ) async {
      useWindow(tester, const Size(1000, 300));
      await tester.pumpWidget(
        host(_page(framedCover: true, description: const Text('Xem thêm'))),
      );
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('wide: a multi-tile cover is built once at the card side', (
      tester,
    ) async {
      useWindow(tester, const Size(1000, 900));
      final sides = <double>[];
      await tester.pumpWidget(
        host(
          KDetailLayout(
            header: KDetailHero(
              framedCover: true,
              title: 'Mix',
              actions: const Text('buttons'),
              coverBuilder: (context, side, radius) {
                sides.add(side);
                return SizedBox.square(
                  dimension: side,
                  child: Row(
                    children: [
                      for (final c in [0xFFFF0000, 0xFF00FF00])
                        Expanded(child: ColoredBox(color: Color(c))),
                    ],
                  ),
                );
              },
            ),
            slivers: const [],
          ),
        ),
      );
      expect(sides, [KDetailHero.frameInnerSize]);
      expect(tester.takeException(), isNull);
    });

    test('circle and framedCover together are refused', () {
      expect(
        () => KDetailHero(
          circle: true,
          framedCover: true,
          title: 't',
          actions: const SizedBox(),
          coverBuilder: (c, s, r) => const SizedBox(),
        ),
        throwsAssertionError,
      );
    });
  });

  group('line3Trailing', () {
    Widget hero({String? semantics}) => KDetailLayout(
      header: KDetailHero(
        title: 'Fav',
        line3: 'Songs you tapped',
        line3Semantics: semantics,
        line3Trailing: const Icon(KIcons.heartFilled, key: ValueKey('heart')),
        coverBuilder: (c, s, r) => SizedBox.square(dimension: s),
        actions: const Text('buttons'),
      ),
      slivers: const [],
    );

    for (final width in [400.0, 1300.0]) {
      testWidgets('sits right after the text, centred on it ($width)', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(host(hero()));
        final text = tester.getRect(find.text('Songs you tapped'));
        final heart = tester.getRect(find.byKey(const ValueKey('heart')));
        expect(heart.left, greaterThanOrEqualTo(text.right));
        expect(heart.center.dy, closeTo(text.center.dy, 1.5));
      });
    }

    testWidgets('heart grows with text scale', (tester) async {
      await tester.pumpWidget(host(hero()));
      final base = tester.getSize(find.byKey(const ValueKey('heart'))).height;
      await tester.pumpWidget(host(hero(), textScale: 2));
      final big = tester.getSize(find.byKey(const ValueKey('heart'))).height;
      expect(big, greaterThan(base));
      expect(tester.takeException(), isNull);
    });

    testWidgets('reads the label and leaves the icon out of semantics', (
      tester,
    ) async {
      await tester.pumpWidget(host(hero(semantics: 'Songs you liked')));
      expect(find.bySemanticsLabel('Songs you liked'), findsOneWidget);
      expect(find.bySemanticsLabel('Songs you tapped'), findsNothing);
    });

    testWidgets('without a trailing widget the line is plain text', (
      tester,
    ) async {
      await tester.pumpWidget(host(_page()));
      expect(find.byKey(const ValueKey('heart')), findsNothing);
      expect(find.text('3 songs'), findsOneWidget);
      expect(find.bySemanticsLabel('3 songs'), findsOneWidget);
    });
  });
}
