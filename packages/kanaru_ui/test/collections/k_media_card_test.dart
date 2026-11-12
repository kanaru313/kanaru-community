import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

Widget _card({
  bool full = true,
  bool current = false,
  bool selected = false,
  bool dimmed = false,
  bool circle = false,
  VoidCallback? onTap,
  VoidCallback? onLongPress,
  VoidCallback? onAction,
  Widget? prefix,
  Widget? accessory,
  bool loading = false,
  KMediaCardStyle style = KMediaCardStyle.auto,
  bool leading = true,
  String? currentLabel,
}) {
  return Align(
    alignment: Alignment.topCenter,
    child: KMediaCard(
      title: 'Title',
      titleLabel: full ? 'tag' : null,
      line2: full ? 'Artist' : null,
      line3: full ? 'Album • 2020' : null,
      prefix: prefix,
      accessory: accessory,
      loading: loading,
      style: style,
      leading: leading
          ? const ColoredBox(key: Key('cover'), color: Color(0xFF888888))
          : null,
      circleLeading: circle,
      top: full ? const Text('3:45') : null,
      bottom: full ? const Icon(KIcons.heart) : null,
      trailing: const Icon(KIcons.moreVert),
      onAction: onAction,
      current: current,
      currentLabel: currentLabel,
      selected: selected,
      dimmed: dimmed,
      onTap: onTap,
      onLongPress: onLongPress,
    ),
  );
}

void main() {
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

  testWidgets('current uses primaryContainer, selected secondaryContainer', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    Color fill() => tester
        .widget<Material>(
          find
              .descendant(
                of: find.byType(KMediaCard),
                matching: find.byType(Material),
              )
              .first,
        )
        .color!;
    final scheme = buildKanaruTheme(brightness: Brightness.light).colorScheme;

    await tester.pumpWidget(host(_card(current: true)));
    expect(fill(), scheme.primaryContainer);
    await tester.pumpWidget(host(_card(selected: true)));
    expect(fill(), scheme.secondaryContainer);
    await tester.pumpWidget(host(_card(style: KMediaCardStyle.card)));
    expect(fill(), scheme.surfaceContainerLow);
  });

  testWidgets('selected draws a check over the leading', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_card()));
    expect(find.byIcon(KIcons.check), findsNothing);
    await tester.pumpWidget(host(_card(selected: true, circle: true)));
    expect(find.byIcon(KIcons.check), findsOneWidget);
  });

  testWidgets('dimmed halves the opacity', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_card(dimmed: true)));
    final opacity = tester.widget<Opacity>(
      find
          .descendant(
            of: find.byType(KMediaCard),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(opacity.opacity, 0.5);
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

  testWidgets('desktop shows the play action on hover only', (tester) async {
    useWindow(tester, const Size(1300, 800));
    await tester.pumpWidget(host(_card(onAction: () {})));
    expect(actionOpacity(tester), 0);
    // The trailing button never hides.
    expect(
      find.ancestor(
        of: find.byIcon(KIcons.moreVert),
        matching: find.byType(AnimatedOpacity),
      ),
      findsNothing,
    );

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
    testWidgets('prefix sits left of the leading', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(_card(prefix: const Icon(KIcons.dragHandle))),
      );
      final prefixBox = tester.getRect(find.byIcon(KIcons.dragHandle));
      final cover = tester.getRect(find.byKey(const Key('cover')));
      expect(prefixBox.right, lessThan(cover.left));
    });

    testWidgets('without a prefix the leading is at the padding edge', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(_card()));
      final card = tester.getRect(find.byType(KMediaCard));
      final cover = tester.getRect(find.byKey(const Key('cover')));
      // The cover is centred in its 56 dp box, which starts at the padding.
      expect(
        cover.center.dx - card.left,
        KLayout.gutterMobile + KMediaCard.coverSize / 2,
      );
    });

    testWidgets('accessory sits left of the trailing', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(_card(accessory: const Icon(KIcons.heart, key: Key('acc')))),
      );
      expect(
        tester.getRect(find.byKey(const Key('acc'))).right,
        lessThan(tester.getRect(find.byIcon(KIcons.moreVert)).left),
      );
    });

    testWidgets('a tinted card colours icon buttons with its own ink', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      final scheme = buildKanaruTheme(brightness: Brightness.light).colorScheme;
      await tester.pumpWidget(
        host(
          Align(
            alignment: Alignment.topCenter,
            child: KMediaCard(
              title: 'T',
              current: true,
              trailing: IconButton(
                onPressed: () {},
                icon: const Icon(KIcons.moreVert),
              ),
              accessory: const Icon(KIcons.heart),
            ),
          ),
        ),
      );
      final soft = scheme.onPrimaryContainer.withValues(alpha: 0.8);
      final button = tester.widget<IconButton>(find.byType(IconButton));
      final theme = IconButtonTheme.of(tester.element(find.byWidget(button)));
      expect(theme.style?.foregroundColor?.resolve({}), soft);
      expect(
        IconTheme.of(tester.element(find.byIcon(KIcons.heart))).color,
        soft,
      );
    });

    testWidgets('the play button keeps its own colours in a tinted card', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(
          Align(
            alignment: Alignment.topCenter,
            child: KMediaCard(title: 'T', current: true, onAction: () {}),
          ),
        ),
      );
      final theme = IconButtonTheme.of(
        tester.element(find.byIcon(KIcons.play)),
      );
      expect(theme.style?.foregroundColor, isNull);
    });

    testWidgets('an untinted card leaves icon buttons alone', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(
          IconButtonTheme(
            data: IconButtonThemeData(
              style: IconButton.styleFrom(foregroundColor: Colors.red),
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: KMediaCard(
                title: 'T',
                trailing: IconButton(
                  onPressed: () {},
                  icon: const Icon(KIcons.moreVert),
                ),
              ),
            ),
          ),
        ),
      );
      final theme = IconButtonTheme.of(
        tester.element(find.byIcon(KIcons.moreVert)),
      );
      expect(theme.style?.foregroundColor?.resolve({}), Colors.red);
    });

    testWidgets('the card tint wins over an inherited foreground', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      final scheme = buildKanaruTheme(brightness: Brightness.light).colorScheme;
      await tester.pumpWidget(
        host(
          IconButtonTheme(
            data: IconButtonThemeData(
              style: IconButton.styleFrom(
                foregroundColor: Colors.red,
                visualDensity: VisualDensity.compact,
              ),
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: KMediaCard(
                title: 'T',
                current: true,
                trailing: IconButton(
                  onPressed: () {},
                  icon: const Icon(KIcons.moreVert),
                ),
              ),
            ),
          ),
        ),
      );
      final theme = IconButtonTheme.of(
        tester.element(find.byIcon(KIcons.moreVert)),
      );
      expect(theme.style?.foregroundColor?.resolve({}), isNot(Colors.red));
      expect(
        theme.style?.foregroundColor?.resolve({}),
        scheme.onPrimaryContainer.withValues(alpha: 0.8),
      );
      expect(theme.style?.visualDensity, VisualDensity.compact);
    });

    testWidgets('a tinted card keeps the inherited icon button style', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(
          IconButtonTheme(
            data: IconButtonThemeData(
              style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: KMediaCard(
                title: 'T',
                selected: true,
                trailing: IconButton(
                  onPressed: () {},
                  icon: const Icon(KIcons.moreVert),
                ),
              ),
            ),
          ),
        ),
      );
      final theme = IconButtonTheme.of(
        tester.element(find.byIcon(KIcons.moreVert)),
      );
      expect(theme.style?.visualDensity, VisualDensity.compact);
      expect(theme.style?.foregroundColor, isNotNull);
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

    testWidgets('mobile auto is flat and transparent when idle', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(_card()));
      expect(radius(tester), 0);
      expect(fill(tester), Colors.transparent);
    });

    testWidgets('mobile auto tints the full width when current', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(_card(current: true)));
      expect(radius(tester), 0);
      expect(fill(tester), isNot(Colors.transparent));
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

        testWidgets(
          'height holds with prefix, play and accessory ($style, $scale x)',
          (tester) async {
            useWindow(tester, const Size(700, 800));
            await tester.pumpWidget(
              host(
                _card(
                  style: style,
                  prefix: const Icon(KIcons.heart),
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
          },
        );
      }
    }
  });
}
