import 'package:flutter/semantics.dart';
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
            lines: ['12 artists'],
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

  testWidgets('fill is the cover placeholder colour of the seed', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    const tile = SizedBox(
      width: 150,
      child: KColorTile(seed: 'Indie', title: 'Indie', icon: KIcons.genres),
    );
    await tester.pumpWidget(host(tile));
    expect(
      _fill(tester, find.byType(KColorTile)),
      KCoverPlaceholderColors.of('Indie', Brightness.light).fill,
    );
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

  testWidgets('a long banner headline is clamped to two lines', (tester) async {
    useWindow(tester, const Size(300, 800));
    const long =
        'Những bài hát hay nhất của Trịnh Công Sơn tuyển tập đặc biệt nhiều '
        'năm tháng và còn rất nhiều chữ nữa cho dài';
    Widget banner(String text) =>
        host(KColorBanner(seed: 's', icon: KIcons.genres, headline: text));
    await tester.pumpWidget(banner('Short'));
    final one = tester.getSize(find.text('Short')).height;
    await tester.pumpWidget(banner(long));
    expect(tester.getSize(find.text(long)).height, closeTo(one * 2, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('banner lines show in order, one line each', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        const KColorBanner(
          seed: 's',
          icon: KIcons.genres,
          headline: 'Indie',
          lines: ['120 songs · 8 h', 'No language tag'],
        ),
      ),
    );
    final first = tester.getTopLeft(find.text('120 songs · 8 h')).dy;
    final second = tester.getTopLeft(find.text('No language tag')).dy;
    expect(tester.getTopLeft(find.text('Indie')).dy, lessThan(first));
    expect(first, lessThan(second));
  });

  testWidgets('the banner headline is a semantics header', (tester) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        const KColorBanner(seed: 's', icon: KIcons.genres, headline: 'Indie'),
      ),
    );
    expect(
      tester.getSemantics(find.text('Indie')),
      isSemantics(isHeader: true, label: 'Indie'),
    );
    handle.dispose();
  });

  testWidgets('the menu is a screen-reader action, no button', (tester) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    var menus = 0;
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 150,
          child: KColorTile(
            seed: 'x',
            title: 'Rock',
            icon: KIcons.genres,
            onMenu: () => menus++,
            menuLabel: 'More options',
          ),
        ),
      ),
    );
    expect(find.byType(IconButton), findsNothing);
    final node = tester.getSemantics(find.byType(KColorTile));
    final id = node.getSemanticsData().customSemanticsActionIds!.single;
    expect(CustomSemanticsAction.getAction(id)!.label, 'More options');
    tester.semantics.performAction(
      find.semantics.byLabel(RegExp('Rock')),
      SemanticsAction.customAction,
      args: id,
    );
    expect(menus, 1);
    handle.dispose();
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('two-line name and count fit extentOf (text x$scale)', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      late double extent;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              extent = KColorTile.extentOf(
                MediaQuery.textScalerOf(context),
                Theme.of(context).textTheme,
              );
              return Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 150,
                  height: extent,
                  child: const KColorTile(
                    seed: 'vie',
                    title:
                        'Tiếng Việt Nam miền Nam · Vietnamese của người Việt',
                    subtitle: '1 234 bài hát',
                    icon: KIcons.genres,
                  ),
                ),
              );
            },
          ),
          textScale: scale,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(extent, greaterThanOrEqualTo(KColorTile.minHeight));
      expect(tester.getSize(find.byType(KColorTile)).height, extent);
    });
  }

  testWidgets('a text theme without font sizes still lays out and fits', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    late double extent;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => Theme(
            data: Theme.of(context).copyWith(
              textTheme: const TextTheme(
                titleMedium: TextStyle(fontWeight: FontWeight.w600),
                bodySmall: TextStyle(),
              ),
            ),
            child: Builder(
              builder: (context) {
                extent = KColorTile.extentOf(
                  MediaQuery.textScalerOf(context),
                  Theme.of(context).textTheme,
                );
                return Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 150,
                    height: extent,
                    child: const KColorTile(
                      seed: 'vie',
                      title: 'Tiếng Việt Nam miền Nam · Vietnamese',
                      subtitle: '1 234 bài hát',
                      icon: KIcons.genres,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(extent, greaterThanOrEqualTo(KColorTile.minHeight));
  });
}
