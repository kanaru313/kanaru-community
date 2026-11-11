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
  bool hoverTrailing = false,
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
      leading: leading ? const ColoredBox(color: Color(0xFF888888)) : null,
      circleLeading: circle,
      top: full ? const Text('3:45') : null,
      bottom: full ? const Icon(KIcons.heart) : null,
      trailing: const Icon(KIcons.moreVert),
      onAction: onAction,
      revealTrailingOnHover: hoverTrailing,
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
    await tester.pumpWidget(host(_card()));
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

  testWidgets('desktop shows the play action and trailing on hover only', (
    tester,
  ) async {
    useWindow(tester, const Size(1300, 800));
    await tester.pumpWidget(host(_card(onAction: () {}, hoverTrailing: true)));
    expect(actionOpacity(tester), 0);

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
}
