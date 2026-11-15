import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/finders.dart';
import '../support/host.dart';

/// Counts how often its State was created: a remount shows as a second one.
class _Probe extends StatefulWidget {
  const _Probe(this.inits);

  final List<int> inits;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.inits.add(1);
  }

  @override
  Widget build(BuildContext context) => const SizedBox(width: 56, height: 56);
}

Widget _card({
  bool current = false,
  bool selected = false,
  bool dimmed = false,
  bool loading = false,
  bool filled = true,
  KMediaCardStyle style = KMediaCardStyle.card,
  List<int>? inits,
  FocusNode? buttonNode,
  VoidCallback? onTap,
}) {
  return Align(
    alignment: Alignment.topCenter,
    child: KMediaCard(
      title: 'Title',
      line2: 'Artist',
      style: style,
      filled: filled,
      loading: loading,
      current: current,
      selected: selected,
      dimmed: dimmed,
      onTap: onTap,
      leading: inits == null
          ? const SizedBox(width: 56, height: 56)
          : _Probe(inits),
      trailing: buttonNode == null
          ? null
          : Focus(
              focusNode: buttonNode,
              child: const SizedBox(key: Key('more'), width: 48, height: 48),
            ),
    ),
  );
}

Finder get _inCard => find.descendant(
  of: find.byType(KMediaCard),
  matching: find.byType(Material),
);

Material _material(WidgetTester tester) =>
    tester.widget<Material>(_inCard.first);

Gradient? _gradient(WidgetTester tester) {
  final ink = tester.widget<Ink>(
    find
        .descendant(of: find.byType(KMediaCard), matching: find.byType(Ink))
        .first,
  );
  return (ink.decoration as BoxDecoration?)?.gradient;
}

bool _ringShown() => find
    .descendant(
      of: find.byType(KMediaCard),
      matching: find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).border != null,
      ),
    )
    .evaluate()
    .isNotEmpty;

void main() {
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
    debugDefaultTargetPlatformOverride = null;
  });

  group('fill', () {
    for (final brightness in Brightness.values) {
      for (final style in [KMediaCardStyle.flat, KMediaCardStyle.card]) {
        testWidgets('plain $style row on $brightness is the token', (
          tester,
        ) async {
          useWindow(tester, const Size(400, 800));
          await tester.pumpWidget(
            host(_card(style: style), brightness: brightness),
          );
          expect(_material(tester).color, KRowColors.fill(brightness));
          expect(_gradient(tester), isNull);
        });
      }
    }

    testWidgets('filled: false keeps flat transparent and card tonal', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      final scheme = buildKanaruTheme(brightness: Brightness.light).colorScheme;
      await tester.pumpWidget(
        host(_card(style: KMediaCardStyle.flat, filled: false)),
      );
      expect(_material(tester).color, Colors.transparent);
      await tester.pumpWidget(host(_card(filled: false)));
      expect(_material(tester).color, scheme.surfaceContainerLow);
    });

    testWidgets('a loading row keeps the fill', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(_card(loading: true)));
      expect(_material(tester).color, KRowColors.fill(Brightness.light));
    });

    testWidgets('dimmed: the 0.5 opacity wraps the filled material', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(_card(dimmed: true)));
      final opacity = find.ancestor(
        of: _inCard.first,
        matching: find.byWidgetPredicate(
          (w) => w is AnimatedOpacity && w.opacity == 0.5,
        ),
      );
      expect(opacity, findsOneWidget);
      expect(_material(tester).color, KRowColors.fill(Brightness.light));
    });
  });

  group('playing and selected', () {
    testWidgets('current: transparent material, token gradient', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      final scheme = buildKanaruTheme(brightness: Brightness.light).colorScheme;
      await tester.pumpWidget(host(_card(current: true)));
      expect(_material(tester).color, Colors.transparent);
      expect(_gradient(tester), KRowColors.playingGradient(scheme));
    });

    testWidgets('right to left: the gradient starts at the right', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(
          Directionality(
            textDirection: TextDirection.rtl,
            child: _card(current: true),
          ),
        ),
      );
      final g = _gradient(tester)! as LinearGradient;
      final context = tester.element(find.byType(KMediaCard));
      expect(Directionality.of(context), TextDirection.rtl);
      expect(
        g.begin.resolve(Directionality.of(context)),
        Alignment.centerRight,
      );
    });

    testWidgets('current + selected: gradient and the check', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(_card(current: true, selected: true)));
      expect(_gradient(tester), isNotNull);
      expect(byCheckState(KCheckState.on), findsOneWidget);
    });

    testWidgets('selected: secondaryContainer, no gradient', (tester) async {
      useWindow(tester, const Size(400, 800));
      final scheme = buildKanaruTheme(brightness: Brightness.light).colorScheme;
      await tester.pumpWidget(host(_card(selected: true)));
      expect(_material(tester).color, scheme.secondaryContainer);
      expect(_gradient(tester), isNull);
    });
  });

  group('no remount', () {
    testWidgets('current, selected and dimmed flips keep focus and State', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      final inits = <int>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      Widget build({
        bool c = false,
        bool s = false,
        bool d = false,
        bool l = false,
      }) => host(
        _card(
          loading: l,
          current: c,
          selected: s,
          dimmed: d,
          inits: inits,
          buttonNode: node,
        ),
      );
      await tester.pumpWidget(build());
      node.requestFocus();
      await tester.pump();
      expect(node.hasPrimaryFocus, isTrue);
      for (final (c, s, d, l) in [
        (true, false, false, false),
        (false, false, false, false),
        (true, false, false, false),
        (false, true, false, false),
        (false, true, true, false),
        (false, false, true, false),
        (true, true, true, false),
        (false, false, false, false),
        (false, false, false, true),
        (true, false, false, true),
        (false, false, false, false),
      ]) {
        await tester.pumpWidget(build(c: c, s: s, d: d, l: l));
        expect(node.hasPrimaryFocus, isTrue, reason: '$c $s $d $l');
        expect(inits, hasLength(1), reason: '$c $s $d $l');
      }
    });
  });

  group('focus ring', () {
    testWidgets('shown on the card own focus in keyboard mode only', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      final button = FocusNode();
      addTearDown(button.dispose);
      await tester.pumpWidget(host(_card(onTap: () {}, buttonNode: button)));
      expect(_ringShown(), isFalse);

      final own = tester
          .widget<InkWell>(
            find.descendant(
              of: find.byType(KMediaCard),
              matching: find.byType(InkWell),
            ),
          )
          .focusNode!;
      own.requestFocus();
      await tester.pump();
      expect(_ringShown(), isTrue);

      // Focus on a button inside the row: no ring on the row.
      button.requestFocus();
      await tester.pump();
      expect(_ringShown(), isFalse);

      // Back on the row, touch mode hides it; keyboard mode brings it back
      // without any focus change.
      own.requestFocus();
      await tester.pump();
      expect(_ringShown(), isTrue);
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTouch;
      await tester.pump();
      expect(own.hasPrimaryFocus, isTrue);
      expect(_ringShown(), isFalse);
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      await tester.pump();
      expect(_ringShown(), isTrue);
    });

    testWidgets('removes its highlight-mode listener on dispose', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(_card(onTap: () {})));
      await tester.pumpWidget(host(const SizedBox()));
      // A mode change after dispose must not reach the dead State.
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTouch;
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('hover and press are onSurface state layers', (tester) async {
    useWindow(tester, const Size(400, 800));
    final scheme = buildKanaruTheme(brightness: Brightness.light).colorScheme;
    await tester.pumpWidget(host(_card(onTap: () {})));
    final overlay = tester
        .widget<InkWell>(
          find.descendant(
            of: find.byType(KMediaCard),
            matching: find.byType(InkWell),
          ),
        )
        .overlayColor!;
    expect(
      overlay.resolve({WidgetState.hovered}),
      scheme.onSurface.withValues(alpha: 0.08),
    );
    expect(
      overlay.resolve({WidgetState.pressed}),
      scheme.onSurface.withValues(alpha: 0.10),
    );
    expect(overlay.resolve({WidgetState.focused}), Colors.transparent);
  });

  group('contrast of painted colours', () {
    // Seeds: spec warm, spec cool, the default (spec gray) and a near-gray raw
    // seed. Palettes of the album page tint, one per seed.
    const seeds = <(String, Color, List<Color>)>[
      (
        'warm',
        Color(0xFFD9822B),
        [Color(0xFFE0703A), Color(0xFF8A2C14), Color(0xFFF2C14E)],
      ),
      (
        'cool',
        Color(0xFF3A7BD5),
        [Color(0xFF3A7BD5), Color(0xFF0F2A5C), Color(0xFF5FC3E4)],
      ),
      (
        'default',
        kanaruSeed,
        [Color(0xFF8A8580), Color(0xFF5C5955), Color(0xFFB4AFA8)],
      ),
      (
        'near-gray',
        Color(0xFF8A8580),
        [Color(0xFF8A8580), Color(0xFF5C5955), Color(0xFFB4AFA8)],
      ),
    ];

    // Contrast of [a] painted over [b]: a translucent text colour is blended
    // over the background first.
    double ratio(Color a, Color b) {
      a = Color.alphaBlend(a, b);
      final la = a.computeLuminance(), lb = b.computeLuminance();
      return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
    }

    Color colorOf(WidgetTester tester, Finder f) {
      final text = tester.widget<Text>(f);
      return text.style?.color ??
          DefaultTextStyle.of(tester.element(f)).style.color!;
    }

    testWidgets('text >= 4.5:1 and icons >= 3:1 on every row state', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      final failures = <String>[];
      void check(String key, double got, double min) {
        if (got < min) failures.add('$key ${got.toStringAsFixed(2)} < $min');
      }

      for (final (name, seed, palette) in seeds) {
        for (final brightness in Brightness.values) {
          final theme = buildKanaruTheme(brightness: brightness, seed: seed);
          final scheme = theme.colorScheme;
          // What lies under a row: page, sheet, and every stop of the album
          // tint at strength 0.5 over the page.
          final stops = readableGradientStops(
            palette,
            base: scheme.surface,
            onSurface: scheme.onSurface,
            onSurfaceVariant: scheme.onSurfaceVariant,
            brightness: brightness,
          );
          final bases = <String, Color>{
            'surface': scheme.surface,
            'sheet': scheme.surfaceContainerLow,
            for (var i = 0; i < stops.length; i++)
              'tint$i': Color.alphaBlend(
                stops[i].withValues(alpha: stops[i].a * 0.5),
                scheme.surface,
              ),
          };
          final tag = '$name/${brightness.name}';

          Future<
            ({
              Color bg,
              Gradient? gradient,
              Color title,
              Color soft,
              Color handle,
              Color heart,
            })
          >
          paint({bool current = false, bool selected = false}) async {
            await tester.pumpWidget(
              MaterialApp(
                theme: theme,
                themeAnimationDuration: Duration.zero,
                home: Scaffold(
                  body: KMediaCard(
                    title: 'Title',
                    line2: 'Artist',
                    style: KMediaCardStyle.card,
                    current: current,
                    selected: selected,
                    onTap: () {},
                    leading: const SizedBox(width: 56, height: 56),
                    // A favourite that is on is `primary` whatever the row,
                    // like the song rows' heart.
                    bottom: KIconButton(
                      icon: KIcons.heart,
                      selectedIcon: KIcons.heartFilled,
                      selected: true,
                      tooltip: 'f',
                      onPressed: () {},
                    ),
                    // The drag handle paints its icon without a colour.
                    trailing: const Icon(KIcons.dragHandle),
                  ),
                ),
              ),
            );
            final heart = find.byIcon(KIcons.heartFilled);
            return (
              bg: _material(tester).color!,
              gradient: _gradient(tester),
              title: colorOf(tester, find.text('Title')),
              soft: colorOf(tester, find.text('Artist')),
              handle: IconTheme.of(
                tester.element(find.byIcon(KIcons.dragHandle)),
              ).color!,
              heart:
                  tester.widget<Icon>(heart).color ??
                  IconTheme.of(tester.element(heart)).color!,
            );
          }

          // Plain: the fill over each base.
          final plain = await paint();
          for (final e in bases.entries) {
            final bg = Color.alphaBlend(plain.bg, e.value);
            final k = '$tag plain on ${e.key}';
            check('$k title', ratio(plain.title, bg), 4.5);
            check('$k soft', ratio(plain.soft, bg), 4.5);
            check('$k handle', ratio(plain.handle, bg), 3);
            check('$k heart-on', ratio(plain.heart, bg), 3);
          }
          // Selected: opaque secondaryContainer. Playing: both gradient ends.
          final sel = await paint(selected: true);
          final cur = await paint(current: true);
          final g = cur.gradient! as LinearGradient;
          for (final (label, bg, row) in [
            ('selected', sel.bg, sel),
            ('playing start', g.colors.first, cur),
            ('playing end', g.colors.last, cur),
          ]) {
            final k = '$tag $label';
            check('$k title', ratio(row.title, bg), 4.5);
            check('$k soft', ratio(row.soft, bg), 4.5);
            check('$k handle', ratio(row.handle, bg), 3);
            check('$k heart-on', ratio(row.heart, bg), 3);
          }
        }
      }
      expect(failures, isEmpty);
    });
  });
}
