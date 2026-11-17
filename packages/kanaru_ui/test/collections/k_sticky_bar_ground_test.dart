import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

const _shot = ValueKey('shot');
const _barKey = ValueKey('bar');
const _red = [Color(0xFFFF0000), Color(0xFF0000FF)];
const _green = [Color(0xFF00FF00), Color(0xFFFFFF00)];

/// A detail page. With [bar] the list has a [KStickyBarSliver]; without, an
/// empty sliver of the same height, so what the ground paints at the bar's
/// place can be read as the reference.
Widget _page({
  required bool bar,
  List<Color>? palette,
  bool ground = true,
  bool fadeIn = false,
  Brightness brightness = Brightness.light,
  double? maxWidth,
}) {
  final layout = KDetailLayout(
    header: const SizedBox(height: 200),
    slivers: [
      bar
          ? const KStickyBarSliver(height: 52, child: SizedBox(key: _barKey))
          : const SliverToBoxAdapter(child: SizedBox(height: 52)),
      SliverList.builder(
        itemCount: 40,
        itemBuilder: (context, i) => const SizedBox(height: 48),
      ),
    ],
  );
  final body = maxWidth == null
      ? layout
      : Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: layout,
          ),
        );
  return host(
    brightness: brightness,
    RepaintBoundary(
      key: _shot,
      child: ground
          ? CoverTintBackground(
              palette: palette,
              fadeIn: fadeIn,
              strength: 1,
              child: body,
            )
          : body,
    ),
  );
}

Future<Color> _pixel(WidgetTester tester, Offset p) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_shot),
  );
  final color = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = (await image.toByteData())!;
    final i = (p.dy.floor() * image.width + p.dx.floor()) * 4;
    final c = Color.fromARGB(
      data.getUint8(i + 3),
      data.getUint8(i),
      data.getUint8(i + 1),
      data.getUint8(i + 2),
    );
    image.dispose();
    return c;
  });
  return color!;
}

bool _near(Color a, Color b) =>
    (a.r - b.r).abs() * 255 <= 2 &&
    (a.g - b.g).abs() * 255 <= 2 &&
    (a.b - b.b).abs() * 255 <= 2;

/// The colour of the bar at a point of it, and of the ground at that very
/// point (the same page with the bar left out). Both pages are pumped without
/// time passing, so a running tint tween is at the same place in both.
Future<(Color bar, Color ground)> _sample(
  WidgetTester tester,
  List<Color> palette, {
  Brightness brightness = Brightness.light,
  double? maxWidth,
}) async {
  await tester.pumpWidget(
    _page(
      bar: true,
      palette: palette,
      brightness: brightness,
      maxWidth: maxWidth,
    ),
  );
  final rect = tester.getRect(find.byKey(_barKey));
  final p = Offset(rect.left + 30, rect.center.dy);
  final bar = await _pixel(tester, p);
  await tester.pumpWidget(
    _page(
      bar: false,
      palette: palette,
      brightness: brightness,
      maxWidth: maxWidth,
    ),
  );
  final ground = await _pixel(tester, p);
  return (bar, ground);
}

void main() {
  final surface = buildKanaruTheme(brightness: Brightness.light)
      .colorScheme
      .surface;

  testWidgets('narrow: the bar continues the tint at rest, on its way up and '
      'pinned', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(_page(bar: true, palette: _red));
    await tester.pump(coverTintTransition);
    final seen = <Color>[];
    for (final scroll in [0.0, 100.0, 300.0]) {
      if (scroll > 0) {
        await tester.drag(find.byType(CustomScrollView), Offset(0, -scroll));
        await tester.pumpAndSettle();
      }
      final (bar, ground) = await _sample(tester, _red);
      expect(
        _near(bar, ground),
        isTrue,
        reason: 'scroll $scroll: $bar $ground',
      );
      expect(_near(bar, surface), isFalse, reason: 'tint must show');
      seen.add(bar);
    }
    // The bar moved up the page, so the colour under it moved too.
    expect(_near(seen.first, seen.last), isFalse);
  });

  testWidgets('narrow: still the ground while the tint is tweening', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(_page(bar: true, palette: _green));
    await tester.pump(coverTintTransition);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -100));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_page(bar: true, palette: _red));
    await tester.pump(const Duration(milliseconds: 150));
    final rect = tester.getRect(find.byKey(_barKey));
    final p = Offset(rect.left + 30, rect.center.dy);
    final midBar = await _pixel(tester, p);
    await tester.pumpWidget(_page(bar: false, palette: _red));
    final midGround = await _pixel(tester, p);
    expect(_near(midBar, midGround), isTrue, reason: '$midBar $midGround');
    // It really was mid-way: neither the old nor the new settled colour.
    await tester.pump(coverTintTransition);
    final end = await _pixel(tester, p);
    expect(_near(midGround, end), isFalse);
  });

  testWidgets('wide: the bar in the right column lines up with the ground '
      'across both columns', (tester) async {
    useWindow(tester, const Size(1300, 800));
    await tester.pumpWidget(_page(bar: true, palette: _red));
    await tester.pump(coverTintTransition);
    for (final scroll in [0.0, 300.0]) {
      if (scroll > 0) {
        await tester.drag(find.byType(CustomScrollView), Offset(0, -scroll));
        await tester.pumpAndSettle();
      }
      await tester.pumpWidget(_page(bar: true, palette: _red));
      expect(
        tester.getRect(find.byKey(_barKey)).left,
        KDetailLayout.columnWidth,
      );
      final (bar, ground) = await _sample(tester, _red);
      expect(
        _near(bar, ground),
        isTrue,
        reason: 'scroll $scroll: $bar $ground',
      );
      expect(_near(bar, surface), isFalse);
    }
  });

  testWidgets('no ground above: the bar is the surface', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(_page(bar: true, ground: false));
    final rect = tester.getRect(find.byKey(_barKey));
    final c = await _pixel(tester, Offset(rect.left + 30, rect.center.dy));
    expect(_near(c, surface), isTrue, reason: '$c');
  });

  testWidgets('a ground that has drawn nothing yet: the bar is the surface', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(_page(bar: true, fadeIn: true));
    final rect = tester.getRect(find.byKey(_barKey));
    final c = await _pixel(tester, Offset(rect.left + 30, rect.center.dy));
    expect(_near(c, surface), isTrue, reason: '$c');
  });

  testWidgets('no BackdropFilter, with or without a ground', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(_page(bar: true, palette: _red));
    expect(find.byType(BackdropFilter), findsNothing);
    await tester.pumpWidget(_page(bar: true, ground: false));
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets(
    'a bar removed while the ground lives leaves no listener behind',
    (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(_page(bar: true, palette: _red));
      await tester.pumpWidget(_page(bar: false, palette: _red));
      // A listener left on the disposed bar would call markNeedsPaint on it.
      await tester.pumpWidget(_page(bar: false, palette: _green));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(coverTintTransition);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('light to dark while pinned: the bar follows the ground', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(_page(bar: true, palette: _red));
    await tester.pump(coverTintTransition);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    final (light, _) = await _sample(tester, _red);
    await tester.pumpWidget(
      _page(bar: true, palette: _red, brightness: Brightness.dark),
    );
    await tester.pumpAndSettle();
    final (bar, ground) = await _sample(
      tester,
      _red,
      brightness: Brightness.dark,
    );
    expect(_near(bar, ground), isTrue, reason: '$bar $ground');
    expect(_near(bar, light), isFalse, reason: 'the theme really switched');
  });

  testWidgets('a centred max-width page widened while pinned: no seam', (
    tester,
  ) async {
    useWindow(tester, const Size(700, 800));
    await tester.pumpWidget(_page(bar: true, palette: _red, maxWidth: 600));
    await tester.pump(coverTintTransition);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    useWindow(tester, const Size(1400, 800));
    await tester.pumpWidget(_page(bar: true, palette: _red, maxWidth: 600));
    await tester.pump();
    final (bar, ground) = await _sample(tester, _red, maxWidth: 600);
    expect(_near(bar, ground), isTrue, reason: '$bar $ground');
    expect(_near(bar, surface), isFalse);
  });
}
