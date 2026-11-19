import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'package:kanaru_ui/src/widgets/collections/k_media_card_frame.dart';
import 'package:kanaru_ui/src/widgets/collections/k_media_card_right_column.dart';

import '../support/finders.dart';
import '../support/host.dart';

Widget _card({
  bool full = true,
  bool current = false,
  bool selected = false,
  bool selecting = false,
  bool dimmed = false,
  bool circle = false,
  VoidCallback? onTap,
  VoidCallback? onLongPress,
  VoidCallback? onAction,
  bool actionEnabled = true,
  Widget? accessory,
  bool loading = false,
  KMediaCardStyle style = KMediaCardStyle.auto,
  bool leading = true,
  String? currentLabel,
  bool filled = true,
  bool missing = false,
  bool editing = false,
}) {
  return Align(
    alignment: Alignment.topCenter,
    child: KMediaCard(
      title: 'Title',
      titleLabel: full ? 'tag' : null,
      line2: full ? 'Artist' : null,
      line3: full ? 'Album • 2020' : null,
      actionEnabled: actionEnabled,
      accessory: accessory,
      loading: loading,
      selecting: selecting,
      style: style,
      filled: filled,
      leading: leading
          ? const ColoredBox(key: Key('cover'), color: Color(0xFF888888))
          : null,
      circleLeading: circle,
      top: full ? const Text('3:45') : null,
      bottom: full ? const Icon(KIcons.heart) : null,
      trailing: const Icon(KIcons.moreVert),
      onAction: onAction,
      actionLabel: onAction == null ? null : 'Play',
      current: current,
      currentLabel: currentLabel,
      selected: selected,
      dimmed: dimmed,
      missing: missing,
      editing: editing,
      onTap: onTap,
      onLongPress: onLongPress,
    ),
  );
}

/// The dashed outline of a missing row (a custom painter in the card frame).
Finder dashed() => find.byKey(KMediaCardFrame.dashedKey);

void main() {
  group('text styles', () {
    testWidgets('metrics styles are what the card text uses', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(_card()));
      final theme = Theme.of(tester.element(find.byType(KMediaCard)));
      final title = KMediaCardMetrics.titleStyle(theme.textTheme)!;
      final line = KMediaCardMetrics.lineStyle(theme.textTheme)!;
      expect(title.fontSize, 15);
      expect(title.fontWeight, FontWeight.w600);
      expect(title.height, 1.35);
      expect(line.fontSize, 13);
      expect(line.height, 1.35);
      final shown = tester.widget<Text>(find.text('Title'));
      expect(shown.style?.fontSize, title.fontSize);
      expect(shown.style?.height, title.height);
      final artist = tester.widget<Text>(find.text('Artist'));
      expect(artist.style?.fontSize, line.fontSize);
      expect(artist.style?.height, line.height);
    });
  });

  group('extentOf', () {
    for (final scale in [1.0, 1.3, 1.5]) {
      testWidgets('matches the laid-out height at $scale x', (tester) async {
        useWindow(tester, const Size(400, 800));
        await tester.pumpWidget(host(_card(), textScale: scale));
        expect(
          tester.getSize(find.byType(KMediaCard)).height,
          closeTo(KMediaCard.extentOf(TextScaler.linear(scale)), 0.5),
        );
      });
    }

    testWidgets('without a leading the card is only as high as its text', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(_card(leading: false)));
      expect(
        tester.getSize(find.byType(KMediaCard)).height,
        closeTo(
          KMediaCard.extentOf(TextScaler.noScaling, hasLeading: false),
          0.5,
        ),
      );
    });

    for (final scale in [1.0, 1.5]) {
      testWidgets('a two-line title keeps the height at $scale x', (
        tester,
      ) async {
        useWindow(tester, const Size(400, 800));
        await tester.pumpWidget(
          host(
            const Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 200,
                child: KMediaCard(
                  title:
                      'Hi-Res > 24bit-96kHz > Bui Lan Huong > Nguoi bat tu OST',
                  titleLines: 2,
                  line2: 'never shown',
                  line3: '12 songs',
                  leading: ColoredBox(color: Color(0xFF888888)),
                ),
              ),
            ),
            textScale: scale,
          ),
        );
        expect(
          tester.getSize(find.byType(KMediaCard)).height,
          closeTo(KMediaCard.extentOf(TextScaler.linear(scale)), 0.5),
        );
        expect(find.text('never shown'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('empty lines keep their room', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(_card(full: false)));
      expect(
        tester.getSize(find.byType(KMediaCard)).height,
        closeTo(KMediaCard.extentOf(TextScaler.noScaling), 0.5),
      );
    });
  });

  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('renders every slot ($name)', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(_card(), brightness: brightness, textScale: scale),
      );
      for (final t in ['Title', 'tag', 'Artist', 'Album • 2020', '3:45']) {
        expect(find.text(t), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('current is a gradient, selected secondaryContainer, plain the '
      'fill; unfilled keeps the old colours', (tester) async {
    useWindow(tester, const Size(400, 800));
    Color? fill() => tester
        .widget<Material>(
          find
              .descendant(
                of: find.byType(KMediaCard),
                matching: find.byType(Material),
              )
              .first,
        )
        .color;
    final scheme = buildKanaruTheme(brightness: Brightness.light).colorScheme;

    await tester.pumpWidget(host(_card(current: true)));
    expect(fill(), Colors.transparent);
    await tester.pumpWidget(host(_card(selected: true)));
    expect(fill(), scheme.secondaryContainer);
    await tester.pumpWidget(host(_card(style: KMediaCardStyle.card)));
    expect(fill(), KRowColors.fill(Brightness.light));
    await tester.pumpWidget(
      host(_card(style: KMediaCardStyle.card, filled: false)),
    );
    expect(fill(), scheme.surfaceContainerLow);
  });

  final onCheck = find.byWidgetPredicate(
    (w) => w is KCheckMark && w.state == KCheckState.on,
  );

  testWidgets('an idle card mounts no check until a selection starts', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_card()));
    expect(find.byType(KCheckMark), findsNothing);
    await tester.pumpWidget(host(_card(selecting: true)));
    expect(find.byType(KCheckMark), findsOneWidget);
    expect(onCheck, findsNothing);
    final before = tester.element(find.byType(KCheckMark));
    await tester.pumpWidget(host(_card()));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.element(find.byType(KCheckMark)), same(before));
    await tester.pumpAndSettle();
    expect(find.byType(KCheckMark), findsOneWidget);
  });

  testWidgets('selecting shows a ring on unselected covers, no scrim', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_card(selecting: true)));
    expect(find.byType(KCheckMark), findsOneWidget);
    expect(onCheck, findsNothing);
    final box = tester.widget<AnimatedContainer>(
      find.ancestor(
        of: find.byType(KCheckMark),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect((box.decoration! as BoxDecoration).color, const Color(0x00000000));
  });

  testWidgets('toggling selected keeps the same mark (it animates)', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_card(selecting: true)));
    final before = tester.element(find.byType(KCheckMark));
    await tester.pumpWidget(host(_card(selecting: true, selected: true)));
    expect(tester.element(find.byType(KCheckMark)), same(before));
    expect(onCheck, findsOneWidget);
  });

  testWidgets('ending the selection keeps the mark mounted while it animates', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_card(selecting: true, selected: true)));
    await tester.pumpAndSettle();
    final before = tester.element(find.byType(KCheckMark));
    Color? scrim() =>
        (tester
                    .widget<AnimatedContainer>(
                      find.ancestor(
                        of: find.byType(KCheckMark),
                        matching: find.byType(AnimatedContainer),
                      ),
                    )
                    .decoration!
                as BoxDecoration)
            .color;
    final start = scrim()!.a;
    expect(start, greaterThan(0));
    await tester.pumpWidget(host(_card()));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.element(find.byType(KCheckMark)), same(before));
    expect(onCheck, findsNothing);
    final mid = scrim()!.a;
    expect(mid, lessThan(start));
    await tester.pumpAndSettle();
    expect(scrim()!.a, 0);
  });

  testWidgets('selected draws a check over the leading', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_card()));
    expect(onCheck, findsNothing);
    await tester.pumpWidget(host(_card(selected: true, circle: true)));
    expect(onCheck, findsOneWidget);
  });

  double minOpacityAbove(WidgetTester tester, Finder target) {
    var lowest = 1.0;
    for (final e
        in find
            .ancestor(
              of: target,
              matching: find.byWidgetPredicate(
                (w) => w is Opacity || w is AnimatedOpacity,
              ),
            )
            .evaluate()) {
      final w = e.widget;
      final value = w is Opacity ? w.opacity : (w as AnimatedOpacity).opacity;
      if (value < lowest) lowest = value;
    }
    return lowest;
  }

  testWidgets('a dimmed selected card keeps its check fully opaque', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_card(dimmed: true, selected: true)));
    expect(onCheck, findsOneWidget);
    expect(minOpacityAbove(tester, onCheck), 1);
    expect(minOpacityAbove(tester, find.byKey(const Key('cover'))), 0.5);
    expect(minOpacityAbove(tester, find.text('Title')), 0.5);
  });

  for (final rtl in [false, true]) {
    testWidgets('a dimmed selected check covers the cover at 2x text'
        '${rtl ? ' in RTL' : ''}', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(
          Directionality(
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            child: _card(dimmed: true, selected: true),
          ),
          textScale: 2,
        ),
      );
      expect(
        tester.getCenter(onCheck),
        tester.getCenter(find.byKey(const Key('cover'))),
      );
    });
  }

  testWidgets('a dimmed card that is not selected has no check', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_card(dimmed: true)));
    expect(onCheck, findsNothing);
    expect(minOpacityAbove(tester, find.byKey(const Key('cover'))), 0.5);
  });

  testWidgets('a selected card that is not dimmed has no opacity layer', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_card(selected: true)));
    expect(minOpacityAbove(tester, onCheck), 1);
  });

  testWidgets('dimmed halves the opacity', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_card(dimmed: true)));
    final opacity = tester.widget<AnimatedOpacity>(
      find
          .descendant(
            of: find.byType(KMediaCard),
            matching: find.byType(AnimatedOpacity),
          )
          .first,
    );
    expect(opacity.opacity, 0.5);
  });

  testWidgets('dimming fades in over the fast motion duration', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_card()));
    await tester.pumpWidget(host(_card(dimmed: true)));
    final fade = find.descendant(
      of: find.byType(KMediaCard),
      matching: find.byType(FadeTransition),
    );
    double shown() => tester.widget<FadeTransition>(fade.first).opacity.value;
    expect(shown(), 1);
    await tester.pump(KMotion.fast ~/ 2);
    expect(shown(), allOf(lessThan(1), greaterThan(0.5)));
    await tester.pump(KMotion.fast);
    expect(shown(), 0.5);
  });

  testWidgets('dimming is immediate when animations are disabled', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    Widget app(bool dimmed) => host(_card(dimmed: dimmed), reduceMotion: true);
    await tester.pumpWidget(app(false));
    await tester.pumpWidget(app(true));
    await tester.pump();
    final fade = find.descendant(
      of: find.byType(KMediaCard),
      matching: find.byType(FadeTransition),
    );
    expect(tester.widget<FadeTransition>(fade.first).opacity.value, 0.5);
  });

  testWidgets('tap and long press reach the callbacks', (tester) async {
    useWindow(tester, const Size(400, 800));
    var taps = 0;
    var longs = 0;
    await tester.pumpWidget(
      host(_card(onTap: () => taps++, onLongPress: () => longs++)),
    );
    await tester.tap(find.text('Title'));
    await tester.longPress(find.text('Title'));
    expect([taps, longs], [1, 1]);
  });

  double actionOpacity(WidgetTester tester) => tester
      .widget<AnimatedOpacity>(
        find
            .ancestor(
              of: find.byIcon(KIcons.play),
              matching: find.byType(AnimatedOpacity),
            )
            .first,
      )
      .opacity;

  testWidgets('play action is always visible on the mobile shell', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    var played = 0;
    await tester.pumpWidget(host(_card(onAction: () => played++)));
    expect(actionOpacity(tester), 1);
    await tester.tap(find.byIcon(KIcons.play));
    expect(played, 1);
  });

  testWidgets('actionEnabled false dims and disables the play action', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    var played = 0;
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(_card(onAction: () => played++, actionEnabled: false)),
    );
    final play = find.ancestor(
      of: find.byIcon(KIcons.play),
      matching: find.byType(KIconButton),
    );
    expect(tester.widget<KIconButton>(play).onPressed, isNull);
    // Still shown, not hidden.
    expect(actionOpacity(tester), 1);
    await tester.tap(find.byIcon(KIcons.play), warnIfMissed: false);
    expect(played, 0);
    // A disabled button takes no focus.
    expect(
      tester
          .widget<FocusableActionDetector>(
            find.descendant(
              of: play,
              matching: find.byType(FocusableActionDetector),
            ),
          )
          .enabled,
      isFalse,
    );
    expect(
      tester.getSemantics(play),
      isSemantics(isButton: true, isEnabled: false),
    );
    handle.dispose();
  });

  testWidgets('desktop shows the play action on hover only', (tester) async {
    useWindow(tester, const Size(1300, 800));
    await tester.pumpWidget(host(_card(onAction: () {})));
    expect(actionOpacity(tester), 0);
    // The trailing button never hides.
    expect(minOpacityAbove(tester, find.byIcon(KIcons.moreVert)), 1);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(KMediaCard)));
    await tester.pumpAndSettle();
    expect(actionOpacity(tester), 1);

    await mouse.moveTo(const Offset(5, 700));
    await tester.pumpAndSettle();
    expect(actionOpacity(tester), 0);
  });

  testWidgets('the current row announces its state', (tester) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(_card(current: true, currentLabel: 'Now playing')),
    );
    expect(find.semantics.byValue('Now playing'), findsOneWidget);
    handle.dispose();
  });

  group('slots', () {
    testWidgets('the leading is at the padding edge', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(_card()));
      final card = tester.getRect(find.byType(KMediaCard));
      final cover = tester.getRect(find.byKey(const Key('cover')));
      // The cover is centred in its 56 dp box, which starts at the padding.
      expect(
        cover.center.dx - card.left,
        KMediaCard.sidePadding + KMediaCard.coverSize / 2,
        reason: 'the row padding is 8 dp',
      );
    });

    for (final (name, style) in [
      ('flat', KMediaCardStyle.flat),
      ('card', KMediaCardStyle.card),
    ]) {
      testWidgets('$name: 8 dp padding at the start and the end', (
        tester,
      ) async {
        useWindow(tester, const Size(400, 800));
        await tester.pumpWidget(host(_card(style: style)));
        final card = tester.getRect(find.byType(KMediaCard));
        final cover = tester.getRect(find.byKey(const Key('cover')));
        final more = tester.getRect(find.byIcon(KIcons.moreVert));
        // The cover is centred in its 56 dp box, which starts at the padding.
        expect(
          cover.center.dx - card.left,
          KMediaCard.sidePadding + KMediaCard.coverSize / 2,
        );
        expect(card.right - more.right, KMediaCard.sidePadding);
      });
    }

    testWidgets('accessory sits left of the trailing', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(_card(accessory: const Icon(KIcons.heart, key: Key('acc')))),
      );
      expect(
        tester.getRect(find.byKey(const Key('acc'))).right,
        lessThanOrEqualTo(tester.getRect(find.byIcon(KIcons.moreVert)).left),
      );
      // 24 dp icons: right edge to left edge is the 4 dp gap.
      expect(
        tester.getRect(find.byIcon(KIcons.moreVert)).left -
            tester.getRect(find.byKey(const Key('acc'))).right,
        4,
      );
    });

    Widget tintedCard({bool current = true, bool selected = false}) => Align(
      alignment: Alignment.topCenter,
      child: KMediaCard(
        title: 'T',
        current: current,
        selected: selected,
        trailing: KIconButton(
          onPressed: () {},
          tooltip: 'More',
          icon: KIcons.moreVert,
        ),
        accessory: const Icon(KIcons.heart),
        onAction: () {},
        actionLabel: 'Play',
      ),
    );

    Color glyphOf(WidgetTester tester, String tooltip) => tester
        .widget<Icon>(
          find.descendant(
            of: find.byWidgetPredicate(
              (w) => w is KIconButton && w.tooltip == tooltip,
            ),
            matching: find.byType(Icon),
          ),
        )
        .color!;

    testWidgets('a tinted card gives its light buttons its own ink', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      final scheme = buildKanaruTheme(brightness: Brightness.light).colorScheme;
      await tester.pumpWidget(host(tintedCard()));
      final soft = scheme.onPrimaryContainer.withValues(
        alpha: KRowColors.containerSoftAlpha,
      );
      final colors = KIconButtonColors.maybeOf(
        tester.element(find.byIcon(KIcons.moreVert)),
      )!;
      expect(colors.rest, soft);
      expect(colors.hover, scheme.onPrimaryContainer);
      expect(glyphOf(tester, 'More'), soft);
      // The play button follows the same colours, with no disc of its own.
      expect(glyphOf(tester, 'Play'), soft);
      expect(
        IconTheme.of(tester.element(find.byIcon(KIcons.heart))).color,
        soft,
      );
    });

    testWidgets('a selected card colours its buttons with the selected ink', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      final scheme = buildKanaruTheme(brightness: Brightness.light).colorScheme;
      await tester.pumpWidget(host(tintedCard(current: false, selected: true)));
      expect(
        glyphOf(tester, 'More'),
        scheme.onSecondaryContainer.withValues(
          alpha: KRowColors.containerSoftAlpha,
        ),
      );
    });

    testWidgets('hover shows the row ink at full strength', (tester) async {
      useWindow(tester, const Size(1300, 800));
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      final scheme = buildKanaruTheme(brightness: Brightness.light).colorScheme;
      await tester.pumpWidget(host(tintedCard()));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byIcon(KIcons.moreVert)));
      await tester.pump();
      expect(glyphOf(tester, 'More'), scheme.onPrimaryContainer);
    });

    testWidgets('an untinted card leaves the theme colours', (tester) async {
      useWindow(tester, const Size(400, 800));
      final scheme = buildKanaruTheme(brightness: Brightness.light).colorScheme;
      await tester.pumpWidget(host(tintedCard(current: false)));
      expect(glyphOf(tester, 'More'), scheme.onSurfaceVariant);
      expect(glyphOf(tester, 'Play'), scheme.onSurfaceVariant);
    });

    testWidgets('a button with its own colour keeps it in a tinted card', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(
          Align(
            alignment: Alignment.topCenter,
            child: KMediaCard(
              title: 'T',
              current: true,
              trailing: KIconButton(
                onPressed: () {},
                tooltip: 'More',
                icon: KIcons.moreVert,
                color: const Color(0xFFFF0000),
              ),
            ),
          ),
        ),
      );
      expect(glyphOf(tester, 'More'), const Color(0xFFFF0000));
    });
  });

  group('loading', () {
    for (final scale in [1.0, 2.0]) {
      testWidgets('shows bars, no text, same height at $scale x', (
        tester,
      ) async {
        useWindow(tester, const Size(400, 800));
        await tester.pumpWidget(host(_card(loading: true), textScale: scale));
        expect(find.text('Title'), findsNothing);
        expect(find.text('Artist'), findsNothing);
        expect(find.byType(FractionallySizedBox), findsNWidgets(2));
        expect(
          tester.getSize(find.byType(KMediaCard)).height,
          closeTo(KMediaCard.extentOf(TextScaler.linear(scale)), 0.5),
        );
      });
    }
  });

  group('loading cover', () {
    testWidgets('no leading: 56 dp KCover.loading, radius 10, same height', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(
          const Align(
            alignment: Alignment.topCenter,
            child: KMediaCard(title: '', loading: true),
          ),
        ),
      );
      final cover = tester.widget<KCover>(find.byType(KCover));
      expect(cover.loading, isTrue);
      expect(cover.size, 56);
      expect(tester.getSize(find.byType(KCover)), const Size(56, 56));
      final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clip.borderRadius, BorderRadius.circular(10));
      expect(
        tester.getSize(find.byType(KMediaCard)).height,
        closeTo(KMediaCard.extentOf(TextScaler.noScaling), 0.5),
      );
    });

    testWidgets('circleLeading makes the skeleton round', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(
          const Align(
            alignment: Alignment.topCenter,
            child: KMediaCard(title: '', loading: true, circleLeading: true),
          ),
        ),
      );
      expect(find.byType(ClipOval), findsOneWidget);
    });

    testWidgets('a given leading wins over the skeleton', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(_card(loading: true)));
      expect(find.byType(KCover), findsNothing);
      expect(find.byKey(const Key('cover')), findsOneWidget);
    });
  });

  group('style', () {
    ShapeBorder? shape(WidgetTester tester) => tester
        .widget<Material>(
          find
              .descendant(
                of: find.byType(KMediaCard),
                matching: find.byType(Material),
              )
              .first,
        )
        .shape;

    Color? fill(WidgetTester tester) => tester
        .widget<Material>(
          find
              .descendant(
                of: find.byType(KMediaCard),
                matching: find.byType(Material),
              )
              .first,
        )
        .color;

    double radius(WidgetTester tester) =>
        ((shape(tester) as RoundedRectangleBorder).borderRadius as BorderRadius)
            .topLeft
            .x;

    testWidgets('mobile auto is flat with the row fill when idle', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(_card()));
      expect(radius(tester), 0);
      expect(fill(tester), KRowColors.fill(Brightness.light));
      await tester.pumpWidget(host(_card(filled: false)));
      expect(fill(tester)!.a, 0, reason: 'fully transparent');
    });

    testWidgets('mobile auto paints the gradient full width when current', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(_card(current: true)));
      expect(radius(tester), 0);
      final ink = tester.widget<Ink>(
        find
            .descendant(of: find.byType(KMediaCard), matching: find.byType(Ink))
            .first,
      );
      expect((ink.decoration! as BoxDecoration).gradient, isNotNull);
      expect(tester.getSize(find.byType(KMediaCard)).width, 400);
    });

    testWidgets('desktop auto is a rounded card', (tester) async {
      useWindow(tester, const Size(1300, 800));
      await tester.pumpWidget(host(_card()));
      expect(radius(tester), 14);
    });

    testWidgets('explicit flat on desktop is flat', (tester) async {
      useWindow(tester, const Size(1300, 800));
      await tester.pumpWidget(host(_card(style: KMediaCardStyle.flat)));
      expect(radius(tester), 0);
    });

    for (final style in KMediaCardStyle.values) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('card height with gap equals extentOf ($style, $scale x)', (
          tester,
        ) async {
          useWindow(tester, const Size(400, 800));
          await tester.pumpWidget(host(_card(style: style), textScale: scale));
          final scaler = TextScaler.linear(scale);
          expect(
            tester.getSize(find.byType(KMediaCard)).height,
            closeTo(KMediaCard.extentOf(scaler), 0.5),
          );
        });

        testWidgets('height holds with play and accessory ($style, $scale x)', (
          tester,
        ) async {
          useWindow(tester, const Size(700, 800));
          await tester.pumpWidget(
            host(
              _card(
                style: style,
                accessory: const Icon(KIcons.heart),
                onAction: () {},
              ),
              textScale: scale,
            ),
          );
          final scaler = TextScaler.linear(scale);
          expect(
            tester.getSize(find.byType(KMediaCard)).height,
            closeTo(KMediaCard.extentOf(scaler), 0.5),
          );
        });
      }
    }
  });

  group('right column', () {
    // Song-row shape: duration over a small heart (icon + padding 8), then
    // the ⋮ button.

    Widget heartButton(VoidCallback onHeart, {Key? key}) => KIconButton(
      key: key ?? const Key('heart'),
      tooltip: 'Heart',
      size: KIconSize.sm,
      padding: const EdgeInsets.all(KSpace.x2),
      onPressed: onHeart,
      icon: KIcons.heart,
    );

    Widget song({
      String duration = '5:53',
      required VoidCallback onHeart,
      VoidCallback? onAction,
      VoidCallback? onMore,
      VoidCallback? onTap,
    }) => Align(
      alignment: Alignment.topCenter,
      child: KMediaCard(
        title: 'T',
        line2: 'a',
        line3: 'b',
        leading: const ColoredBox(color: Color(0xFF888888)),
        top: Text(duration, key: const Key('dur')),
        bottom: heartButton(onHeart),
        onAction: onAction,
        actionLabel: 'Play',
        onTap: onTap,
        trailing: KMoreButton(
          key: const Key('more'),
          tooltip: 'More',
          onPressed: ({required viaKeyboard}) => onMore?.call(),
        ),
      ),
    );

    // The press hold of a light button keeps a timer alive for a moment.
    Future<void> settle(WidgetTester tester) async {
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(KMotion.press);
    }

    testWidgets('duration and heart share a centre and sit tight', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(song(onHeart: () {})));
      final text = tester.getRect(find.byKey(const Key('dur')));
      final icon = tester.getRect(find.byIcon(KIcons.heart));
      expect((text.center.dx - icon.center.dx).abs(), lessThan(1));
      expect(icon.top - text.bottom, closeTo(2, 0.5));
    });

    testWidgets('the heart box is the icon plus its padding', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(song(onHeart: () {})));
      expect(
        tester.getSize(find.byKey(const Key('heart'))),
        const Size(KIconSize.sm + 16, KIconSize.sm + 16),
      );
      expect(KMediaCardRightColumn.iconSize, KIconSize.sm);
    });

    testWidgets('the heart takes taps on its edges, not the row', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      var taps = 0, rowTaps = 0;
      await tester.pumpWidget(
        host(song(onHeart: () => taps++, onTap: () => rowTaps++)),
      );
      final box = tester.getRect(find.byKey(const Key('heart')));
      for (final p in [
        box.topLeft + const Offset(1, 1),
        box.bottomRight - const Offset(1, 1),
        box.center,
      ]) {
        await tester.tapAt(p);
        await settle(tester);
      }
      expect((taps, rowTaps), (3, 0));
    });

    testWidgets('the gap before the right column absorbs a tap', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      var taps = 0, rowTaps = 0;
      await tester.pumpWidget(
        host(song(onHeart: () => taps++, onTap: () => rowTaps++)),
      );
      final box = tester.getRect(find.byKey(const Key('heart')));
      final column = tester.getRect(find.byType(KMediaCardRightColumn));
      // Just left of the column: the gap, not the heart and not the row.
      await tester.tapAt(Offset(column.left - 3, box.center.dy));
      await tester.pump(const Duration(milliseconds: 100));
      expect((taps, rowTaps), (0, 0));
      // Past the gap, on the text block, the row takes it.
      await tester.tapAt(Offset(column.left - KSpace.x2 - 3, box.center.dy));
      await tester.pump(const Duration(milliseconds: 100));
      expect((taps, rowTaps), (0, 1));
    });

    // Every tap inside the right column's heart band, at any duration width
    // and text scale, belongs to the heart (or to the more button beside it),
    // never to the row. The duration text above the band is the row's.
    for (final duration in ['3:45', '1:02:33']) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('near the heart: duration $duration at $scale x', (
          tester,
        ) async {
          useWindow(tester, const Size(400, 800));
          var hearts = 0, mores = 0, rowTaps = 0;
          await tester.pumpWidget(
            host(
              song(
                duration: duration,
                onHeart: () => hearts++,
                onMore: () => mores++,
                onTap: () => rowTaps++,
              ),
              textScale: scale,
            ),
          );
          final heart = tester.getRect(find.byKey(const Key('heart')));
          final more = tester.getRect(find.byKey(const Key('more')));
          final column = tester.getRect(find.byType(KMediaCardRightColumn));
          final text = tester.getRect(find.byKey(const Key('dur')));
          Future<void> tapAt(Offset p) async {
            await tester.tapAt(p);
            await settle(tester);
          }

          // Left and right of the heart inside the column (a wide duration
          // leaves strips there; a narrow one leaves none), and the heart's
          // own edges.
          final taps = <Offset>[
            Offset(heart.left + 1, heart.center.dy),
            Offset(heart.right - 1, heart.center.dy),
            Offset(column.left + 0.5, heart.center.dy),
            Offset(column.right - 0.5, heart.center.dy),
            // The strip between the heart and the more button (the column's
            // right side; the more button starts where the column ends).
            Offset((heart.right + column.right) / 2 - 0.25, heart.center.dy),
            // Where the heart's box overlaps the lower edge of the duration.
            Offset(heart.center.dx, text.bottom - 1),
          ];
          for (final p in taps) {
            await tapAt(p);
          }
          expect(rowTaps, 0, reason: 'no near miss plays the row');
          expect(mores, 0);
          expect(hearts, taps.length);

          // The more button takes its own edge.
          await tapAt(Offset(more.left + 1, more.center.dy));
          expect((hearts, mores, rowTaps), (taps.length, 1, 0));

          // The duration text itself is the row's.
          await tester.tapAt(Offset(text.center.dx, text.top + 1));
          await tester.pump(const Duration(milliseconds: 100));
          expect((hearts, rowTaps), (taps.length, 1));
        });
      }
    }

    testWidgets('the row end padding right of the more button is the button', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      var mores = 0, rowTaps = 0;
      await tester.pumpWidget(
        host(
          song(onHeart: () {}, onMore: () => mores++, onTap: () => rowTaps++),
        ),
      );
      final card = tester.getRect(find.byType(KMediaCard));
      final more = tester.getRect(find.byKey(const Key('more')));
      // The padding stays: the button ends one row padding before the edge.
      expect(card.right - more.right, KMediaCard.sidePadding);
      for (final dx in [
        1.0,
        KMediaCard.sidePadding / 2,
        KMediaCard.sidePadding - 1,
      ]) {
        await tester.tapAt(Offset(more.right + dx, more.center.dy));
        await settle(tester);
      }
      expect((mores, rowTaps), (3, 0));
      // Above the button's band the padding is still the row's.
      await tester.tapAt(Offset(more.right + 4, more.top - 4));
      await tester.pump(const Duration(milliseconds: 100));
      expect((mores, rowTaps), (3, 1));
    });

    testWidgets('a tap on the duration behaves like a tap on the row', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      var taps = 0, rowTaps = 0;
      await tester.pumpWidget(
        host(song(onHeart: () => taps++, onTap: () => rowTaps++)),
      );
      await tester.tapAt(tester.getCenter(find.byKey(const Key('dur'))));
      await tester.pump(const Duration(milliseconds: 100));
      expect((taps, rowTaps), (0, 1));
    });

    testWidgets('with play: right column, gap, play, more in that order', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(song(onHeart: () {}, onAction: () {})));
      final column = tester.getRect(find.byType(KMediaCardRightColumn));
      final play = tester.getRect(byIconButton('Play'));
      final more = tester.getRect(find.byKey(const Key('more')));
      expect(play.left - column.right, KSpace.x2);
      expect(more.left - play.right, 0);
      expect(play.size, const Size(KIconSize.sm + 16, KIconSize.sm + 16));
    });

    testWidgets('the gap before play absorbs a tap', (tester) async {
      useWindow(tester, const Size(400, 800));
      var played = 0, rowTaps = 0;
      await tester.pumpWidget(
        host(
          song(
            onHeart: () {},
            onAction: () => played++,
            onTap: () => rowTaps++,
          ),
        ),
      );
      final column = tester.getRect(find.byType(KMediaCardRightColumn));
      await tester.tapAt(Offset(column.right + 3, column.center.dy));
      await tester.pump(const Duration(milliseconds: 100));
      expect((played, rowTaps), (0, 0));
    });

    for (final platform in [TargetPlatform.android, TargetPlatform.linux]) {
      for (final scale in [0.8, 1.0, 1.3, 2.0]) {
        testWidgets('the pair is centred in the row on $platform at $scale x', (
          tester,
        ) async {
          debugDefaultTargetPlatformOverride = platform;
          try {
            useWindow(tester, const Size(1300, 800));
            await tester.pumpWidget(
              host(song(onHeart: () {}), textScale: scale),
            );
            final card = tester.getRect(find.byType(KMediaCard));
            final text = tester.getRect(find.byKey(const Key('dur')));
            final icon = tester.getRect(find.byIcon(KIcons.heart));
            expect((text.center.dx - icon.center.dx).abs(), lessThan(1));
            expect(icon.top - text.bottom, closeTo(2, 0.5));
            // Centre of the pair (text top to icon bottom) = centre of the
            // row content, which sits inside the card's 10 dp padding.
            final rowCentre = card.top + 10 + (card.height - 10 - 4 - 10) / 2;
            expect((text.top + icon.bottom) / 2, closeTo(rowCentre, 0.5));
          } finally {
            debugDefaultTargetPlatformOverride = null;
          }
        });
      }
    }

    for (final scale in [0.8, 1.0, 1.3, 2.0]) {
      testWidgets('height equals extentOf at $scale x', (tester) async {
        useWindow(tester, const Size(400, 800));
        await tester.pumpWidget(host(song(onHeart: () {}), textScale: scale));
        expect(
          tester.getSize(find.byType(KMediaCard)).height,
          KMediaCard.extentOf(TextScaler.linear(scale)),
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('play stays hidden until hover on desktop', (tester) async {
      useWindow(tester, const Size(1300, 800));
      await tester.pumpWidget(host(song(onHeart: () {}, onAction: () {})));
      expect(actionOpacity(tester), 0);
    });

    testWidgets('a bare Icon in bottom does not overlap the duration', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(
          const Align(
            alignment: Alignment.topCenter,
            child: KMediaCard(
              title: 'T',
              leading: ColoredBox(color: Color(0xFF888888)),
              top: Text('5:53', key: Key('dur')),
              bottom: Icon(KIcons.heart),
            ),
          ),
        ),
      );
      final text = tester.getRect(find.byKey(const Key('dur')));
      final icon = tester.getRect(find.byIcon(KIcons.heart));
      expect(icon.top, greaterThanOrEqualTo(text.bottom));
    });

    testWidgets('top and bottom without a leading at 0.85 x lay out cleanly', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(
          Align(
            alignment: Alignment.topCenter,
            child: KMediaCard(
              title: 'T',
              top: const Text('5:53'),
              bottom: heartButton(() {}),
            ),
          ),
          textScale: 0.85,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(KMediaCard)).height,
        closeTo(
          KMediaCard.extentOf(const TextScaler.linear(0.85), hasLeading: false),
          0.5,
        ),
      );
    });

    testWidgets('the heart is at the same height with or without a duration', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      Future<double> heartTop(Widget? top) async {
        await tester.pumpWidget(
          host(
            Align(
              alignment: Alignment.topCenter,
              child: KMediaCard(
                title: 'T',
                leading: const ColoredBox(color: Color(0xFF888888)),
                top: top,
                bottom: heartButton(() {}),
              ),
            ),
            textScale: 2.0,
          ),
        );
        return tester.getTopLeft(find.byKey(const Key('heart'))).dy;
      }

      final with_ = await heartTop(const Text('5:53'));
      final without = await heartTop(null);
      expect(with_, closeTo(without, 0.5));
    });

    testWidgets('only a duration, only a heart: no overflow, inside the row', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      for (final only in ['top', 'bottom']) {
        await tester.pumpWidget(
          host(
            Align(
              alignment: Alignment.topCenter,
              child: KMediaCard(
                title: 'T',
                leading: const ColoredBox(color: Color(0xFF888888)),
                top: only == 'top' ? const Text('5:53') : null,
                bottom: only == 'bottom' ? heartButton(() {}) : null,
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final card = tester.getRect(find.byType(KMediaCard));
        final item = only == 'top'
            ? tester.getRect(find.text('5:53'))
            : tester.getRect(find.byIcon(KIcons.heart));
        expect(card.contains(item.center), isTrue);
      }
    });

    testWidgets('play shows on hover on desktop', (tester) async {
      useWindow(tester, const Size(1300, 800));
      await tester.pumpWidget(host(song(onHeart: () {}, onAction: () {})));
      expect(actionOpacity(tester), 0);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(KMediaCard)));
      await tester.pumpAndSettle();
      expect(actionOpacity(tester), 1);
    });
  });

  group('right column intrinsics', () {
    testWidgets('a card inside IntrinsicWidth does not overflow', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(
          Align(
            alignment: Alignment.topLeft,
            child: IntrinsicWidth(
              child: KMediaCard(
                title: 'Title',
                line2: 'Artist',
                top: const Text('5:53'),
                bottom: KIconButton(
                  onPressed: () {},
                  tooltip: 'Heart',
                  size: KIconSize.sm,
                  padding: const EdgeInsets.all(KSpace.x2),
                  icon: KIcons.heart,
                ),
                trailing: const Icon(KIcons.moreVert),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the column reports the wider child and its fixed height', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(
          const Align(
            alignment: Alignment.topLeft,
            child: IntrinsicWidth(
              child: KMediaCardRightColumn(
                height: 56,
                topLine: 16,
                top: SizedBox(width: 30, height: 16),
                bottom: SizedBox(width: 48, height: 48),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(KMediaCardRightColumn)),
        const Size(48, 56),
      );
      final box = tester.renderObject<RenderBox>(
        find.byType(KMediaCardRightColumn),
      );
      expect(box.getMinIntrinsicWidth(double.infinity), 48);
      expect(box.getMaxIntrinsicWidth(double.infinity), 48);
      expect(box.getMinIntrinsicHeight(48), 56);
      expect(box.getMaxIntrinsicHeight(48), 56);
    });
  });

  group('skeleton list', () {
    testWidgets('draws exactly ceil(height / extentOf) loading rows', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(const KMediaCardSkeletonList()));
      final extent = KMediaCard.extentOf(TextScaler.noScaling);
      final body = tester.getSize(find.byType(KMediaCardSkeletonList)).height;
      final cards = tester.widgetList<KMediaCard>(find.byType(KMediaCard));
      expect(cards.every((c) => c.loading), isTrue);
      expect(cards.length, (body / extent).ceil());
      expect(
        tester.getSize(find.byType(KMediaCard).first).height,
        closeTo(extent, 0.5),
      );
    });

    testWidgets('a short viewport draws exactly its ceil count', (
      tester,
    ) async {
      final extent = KMediaCard.extentOf(TextScaler.noScaling);
      await tester.pumpWidget(
        host(
          SizedBox(height: extent * 2.5, child: const KMediaCardSkeletonList()),
        ),
      );
      expect(find.byType(KMediaCard), findsNWidgets(3));
    });

    testWidgets('a header takes its measured height off the row count', (
      tester,
    ) async {
      final extent = KMediaCard.extentOf(TextScaler.noScaling);
      await tester.pumpWidget(
        host(
          SizedBox(
            height: extent * 5,
            child: KMediaCardSkeletonList(
              header: SizedBox(height: extent * 1.5),
            ),
          ),
        ),
      );
      // 5 - 1.5 = 3.5 rows of room: 4 rows, not the 5 of a headerless list.
      expect(find.byType(KMediaCard), findsNWidgets(4));
    });

    testWidgets('an unbounded parent draws unboundedCount rows, no error', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(const SingleChildScrollView(child: KMediaCardSkeletonList())),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.byType(KMediaCard, skipOffstage: false),
        findsNWidgets(KMediaCardSkeletonList.unboundedCount),
      );
    });

    testWidgets('skeleton rows add no semantics nodes', (tester) async {
      useWindow(tester, const Size(400, 800));
      final handle = tester.ensureSemantics();
      int nodes() {
        var n = 0;
        void walk(SemanticsNode node) {
          n++;
          node.visitChildren((c) {
            walk(c);
            return true;
          });
        }

        final root =
            tester.binding.rootPipelineOwner.semanticsOwner?.rootSemanticsNode;
        if (root != null) walk(root);
        return n;
      }

      await tester.pumpWidget(host(const SizedBox.shrink()));
      final empty = nodes();
      await tester.pumpWidget(host(const KMediaCardSkeletonList()));
      expect(nodes(), empty);
      handle.dispose();
    });

    testWidgets('roundCover draws circles', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(const KMediaCardSkeletonList(roundCover: true)),
      );
      expect(find.byType(ClipOval), findsWidgets);
    });
  });

  group('editing', () {
    final ringFinder = find.byWidgetPredicate(
      (w) =>
          w is DecoratedBox &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).border is Border,
      description: 'focus ring',
    );
    bool ring() => ringFinder.evaluate().isNotEmpty;

    void traditional() => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    tearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );

    testWidgets('Tab focuses an editing row and shows the ring', (
      tester,
    ) async {
      traditional();
      useWindow(tester, const Size(1300, 800));
      await tester.pumpWidget(host(_card(editing: true)));
      expect(ring(), isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(ring(), isTrue);
    });

    testWidgets('a row not in edit mode without a tap is not focusable', (
      tester,
    ) async {
      traditional();
      useWindow(tester, const Size(1300, 800));
      await tester.pumpWidget(host(_card()));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(ring(), isFalse);
    });

    testWidgets('a click takes focus and shows the ring, no tap runs', (
      tester,
    ) async {
      traditional();
      useWindow(tester, const Size(1300, 800));
      await tester.pumpWidget(host(_card(editing: true)));
      await tester.tap(find.text('Title'), kind: PointerDeviceKind.mouse);
      await tester.pump();
      expect(ring(), isTrue);
    });

    testWidgets('an editing row announces no tap action', (tester) async {
      useWindow(tester, const Size(1300, 800));
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_card(editing: true)));
      final data = tester
          .getSemantics(find.byType(KMediaCard))
          .getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      handle.dispose();
    });

    testWidgets('touch focus shows no ring', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTouch;
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(_card(editing: true)));
      await tester.tap(find.text('Title'));
      await tester.pump();
      expect(ring(), isFalse);
    });

    testWidgets('with missing, the ring replaces the dashes', (tester) async {
      traditional();
      useWindow(tester, const Size(1300, 800));
      await tester.pumpWidget(host(_card(editing: true, missing: true)));
      expect(dashed(), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(ring(), isTrue);
      expect(dashed(), findsNothing);
    });
  });

  group('missing', () {
    testWidgets('dims, draws a dashed outline, line 3 in the error colour', (
      tester,
    ) async {
      useWindow(tester, const Size(1300, 800));
      await tester.pumpWidget(host(_card(missing: true)));
      final opacity = tester.widget<AnimatedOpacity>(
        find
            .descendant(
              of: find.byType(KMediaCard),
              matching: find.byType(AnimatedOpacity),
            )
            .first,
      );
      expect(opacity.opacity, 0.5);
      expect(dashed(), findsOneWidget);
      final scheme = Theme.of(tester.element(find.byType(KMediaCard)));
      expect(
        tester.widget<Text>(find.text('Album • 2020')).style?.color,
        scheme.colorScheme.error,
      );
      expect(
        tester.widget<Text>(find.text('Artist')).style?.color,
        isNot(scheme.colorScheme.error),
      );
    });

    testWidgets('a normal card has no outline and keeps line 3 quiet', (
      tester,
    ) async {
      useWindow(tester, const Size(1300, 800));
      await tester.pumpWidget(host(_card()));
      expect(dashed(), findsNothing);
    });

    for (final (name, style) in [
      ('flat', KMediaCardStyle.flat),
      ('card', KMediaCardStyle.card),
    ]) {
      testWidgets('draws in the $name style, selected and current', (
        tester,
      ) async {
        useWindow(tester, const Size(400, 800));
        await tester.pumpWidget(
          host(_card(missing: true, style: style, selected: true)),
        );
        expect(dashed(), findsOneWidget);
        await tester.pumpWidget(
          host(_card(missing: true, style: style, current: true)),
        );
        expect(dashed(), findsOneWidget);
      });
    }

    testWidgets('semantics are those of a normal row', (tester) async {
      useWindow(tester, const Size(400, 800));
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_card(onTap: () {})));
      final normal = tester.getSemantics(find.byType(KMediaCard));
      await tester.pumpWidget(host(_card(onTap: () {}, missing: true)));
      final gone = tester.getSemantics(find.byType(KMediaCard));
      expect(gone.label, normal.label);
      expect(
        gone.getSemanticsData().flagsCollection,
        normal.getSemanticsData().flagsCollection,
      );
      handle.dispose();
    });

    testWidgets('fits at 200 % text, dark', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(_card(missing: true), brightness: Brightness.dark, textScale: 2),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
