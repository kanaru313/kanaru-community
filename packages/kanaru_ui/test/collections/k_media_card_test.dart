import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'package:kanaru_ui/src/widgets/collections/k_media_card_right_column.dart';

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
  double prefixWidth = KMediaCard.defaultPrefixWidth,
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
      prefixWidth: prefixWidth,
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

    testWidgets('prefixWidth sets the prefix box, default 40', (tester) async {
      useWindow(tester, const Size(400, 800));
      Future<double> coverLeft(double width) async {
        await tester.pumpWidget(
          host(
            _card(prefix: const Icon(KIcons.dragHandle), prefixWidth: width),
          ),
        );
        return tester.getRect(find.byKey(const Key('cover'))).left;
      }

      final wide = await coverLeft(KMediaCard.defaultPrefixWidth);
      final narrow = await coverLeft(12);
      expect(wide - narrow, closeTo(KMediaCard.defaultPrefixWidth - 12, 0.5));
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
        lessThanOrEqualTo(tester.getRect(find.byIcon(KIcons.moreVert)).left),
      );
      // 24 dp icons: right edge to left edge is the 4 dp gap.
      expect(
        tester.getRect(find.byIcon(KIcons.moreVert)).left -
            tester.getRect(find.byKey(const Key('acc'))).right,
        4,
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
              ).copyWith(iconColor: const WidgetStatePropertyAll(Colors.red)),
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
      expect(theme.style?.iconColor?.resolve({}), isNot(Colors.red));
      expect(
        theme.style?.iconColor?.resolve({}),
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

  group('right column', () {
    // Song-row shape: duration over a 20 dp heart in a default IconButton,
    // then the 48 dp more button.

    Widget song({required VoidCallback onHeart, VoidCallback? onAction}) =>
        Align(
          alignment: Alignment.topCenter,
          child: KMediaCard(
            title: 'T',
            line2: 'a',
            line3: 'b',
            leading: const ColoredBox(color: Color(0xFF888888)),
            top: const Text('5:53', key: Key('dur')),
            bottom: IconButton(
              key: const Key('heart'),
              iconSize: 20,
              onPressed: onHeart,
              icon: const Icon(KIcons.heart),
            ),
            onAction: onAction,
            trailing: IconButton(
              key: const Key('more'),
              onPressed: () {},
              icon: const Icon(KIcons.moreVert),
            ),
          ),
        );

    testWidgets('duration and heart share a centre and sit tight', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(song(onHeart: () {})));
      final text = tester.getRect(find.byKey(const Key('dur')));
      final icon = tester.getRect(find.byIcon(KIcons.heart));
      expect((text.center.dx - icon.center.dx).abs(), lessThan(1));
      expect(icon.top - text.bottom, lessThanOrEqualTo(4));
      expect(icon.top - text.bottom, greaterThanOrEqualTo(0));
    });

    testWidgets('the heart keeps a 48 dp hit area, edges included', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      var taps = 0;
      await tester.pumpWidget(host(song(onHeart: () => taps++)));
      final box = tester.getRect(find.byKey(const Key('heart')));
      expect(box.width, greaterThanOrEqualTo(48));
      expect(box.height, greaterThanOrEqualTo(48));
      for (final p in [
        box.topLeft + const Offset(1, 1),
        box.bottomRight - const Offset(1, 1),
        box.center,
      ]) {
        await tester.tapAt(p);
      }
      expect(taps, 3);
    });

    testWidgets('heart to more is 48 dp apart and boxes keep the icons free', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(song(onHeart: () {})));
      final heart = tester.getRect(find.byKey(const Key('heart')));
      final more = tester.getRect(find.byKey(const Key('more')));
      final gap =
          tester.getCenter(find.byKey(const Key('more'))).dx -
          tester.getCenter(find.byKey(const Key('heart'))).dx;
      expect(gap, 48);
      expect(heart.right, lessThanOrEqualTo(more.left));
    });

    testWidgets('with play, play is 48 dp from more and the heart is left', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(song(onHeart: () {}, onAction: () {})));
      final more = tester.getCenter(find.byKey(const Key('more'))).dx;
      final play = tester.getRect(find.byIcon(KIcons.play));
      final heartX = tester.getCenter(find.byKey(const Key('heart'))).dx;
      expect(more - play.center.dx, 48);
      // Play centre to heart centre, pinned to the laid-out value.
      expect(play.center.dx - heartX, 56);
      final heart = tester.getCenter(find.byKey(const Key('heart'))).dx;
      // Play and the heart (no play) each sit exactly 48 dp from more.
      expect(more - heart, greaterThan(48));
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('height equals extentOf at $scale x', (tester) async {
        useWindow(tester, const Size(400, 800));
        await tester.pumpWidget(host(song(onHeart: () {}), textScale: scale));
        expect(
          tester.getSize(find.byType(KMediaCard)).height,
          KMediaCard.extentOf(TextScaler.linear(scale)),
        );
        final text = tester.getRect(find.byKey(const Key('dur')));
        final icon = tester.getRect(find.byIcon(KIcons.heart));
        expect((text.center.dx - icon.center.dx).abs(), lessThan(1));
        expect(icon.top - text.bottom, lessThanOrEqualTo(4));
      });
    }

    testWidgets('play stays hidden until hover on desktop', (tester) async {
      useWindow(tester, const Size(1300, 800));
      await tester.pumpWidget(host(song(onHeart: () {}, onAction: () {})));
      expect(actionOpacity(tester), 0);
    });

    Future<void> onPlatform(
      WidgetTester tester,
      TargetPlatform platform,
      Future<void> Function() body,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      try {
        await body();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    }

    for (final platform in [TargetPlatform.android, TargetPlatform.linux]) {
      for (final scale in [0.85, 1.0, 2.0]) {
        testWidgets('pair sits 2 dp apart on $platform at $scale x', (
          tester,
        ) async {
          await onPlatform(tester, platform, () async {
            useWindow(tester, const Size(1300, 800));
            await tester.pumpWidget(
              host(song(onHeart: () {}), textScale: scale),
            );
            final text = tester.getRect(find.byKey(const Key('dur')));
            final icon = tester.getRect(find.byIcon(KIcons.heart));
            expect((text.center.dx - icon.center.dx).abs(), lessThan(1));
            expect(icon.top - text.bottom, closeTo(2, 0.5));
            final heart = tester.getRect(find.byKey(const Key('heart')));
            expect(
              heart.height,
              platform == TargetPlatform.linux ? 40 : greaterThanOrEqualTo(48),
            );
          });
        });
      }
    }

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
              bottom: IconButton(
                onPressed: () {},
                icon: const Icon(KIcons.heart),
              ),
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
                bottom: IconButton(
                  key: const Key('heart'),
                  iconSize: 20,
                  onPressed: () {},
                  icon: const Icon(KIcons.heart),
                ),
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
                bottom: only == 'bottom'
                    ? IconButton(
                        onPressed: () {},
                        icon: const Icon(KIcons.heart),
                      )
                    : null,
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

    testWidgets('a tap on the duration reaches the heart', (tester) async {
      useWindow(tester, const Size(400, 800));
      var taps = 0;
      await tester.pumpWidget(host(song(onHeart: () => taps++)));
      await tester.tapAt(tester.getCenter(find.byKey(const Key('dur'))));
      expect(taps, 1);
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
                bottom: IconButton(
                  onPressed: () {},
                  icon: const Icon(KIcons.heart),
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
}
