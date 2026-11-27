import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

void main() {
  testWidgets('semanticLabel is the only spoken label; tooltip is visual', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        Center(
          child: Tooltip(
            message: 'Thêm 10 phút',
            excludeFromSemantics: true,
            child: KChip(
              dense: true,
              semanticLabel: 'Thêm 10 phút',
              label: const Text('+10 ph'),
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Thêm 10 phút'), findsOneWidget);
    expect(find.bySemanticsLabel('+10 ph'), findsNothing);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Thêm 10 phút')),
      isSemantics(isButton: true, isEnabled: true, hasTapAction: true),
    );
    semantics.dispose();
  });

  testWidgets('without semanticLabel the visible label is spoken', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        Center(
          child: KChip(label: const Text('15 ph'), onTap: () {}),
        ),
      ),
    );
    expect(find.bySemanticsLabel('15 ph'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('onRaised lifts only the unselected chip', (tester) async {
    Color fill(Finder chip) => tester
        .widget<Material>(
          find.descendant(of: chip, matching: find.byType(Material)).first,
        )
        .color!;
    await tester.pumpWidget(
      host(
        const Column(
          children: [
            KChip(label: Text('a'), onRaised: true, dense: true),
            KChip(label: Text('b'), onRaised: true, selected: true),
            KChip(label: Text('c')),
          ],
        ),
      ),
    );
    final scheme = Theme.of(tester.element(find.text('a'))).colorScheme;
    expect(
      fill(find.widgetWithText(KChip, 'a')),
      scheme.surfaceContainerHighest,
    );
    expect(fill(find.widgetWithText(KChip, 'b')), scheme.secondaryContainer);
    expect(fill(find.widgetWithText(KChip, 'c')), scheme.surfaceContainerHigh);
  });

  testWidgets('tag is a 20 dp label that is not a button', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        const Column(
          children: [
            KChip.tag(label: Text('Lời bài')),
            KChip.tag(label: Text('tác giả'), outlined: true),
          ],
        ),
      ),
    );
    // Tinted and outlined are exactly as tall.
    expect(tester.getSize(find.byType(KChip).first).height, 20);
    expect(tester.getSize(find.byType(KChip).last).height, 20);
    expect(
      tester.getSemantics(find.text('Lời bài')),
      isNot(matchesSemantics(isButton: true)),
    );
    semantics.dispose();
  });

  testWidgets('tag tone picks the fill', (tester) async {
    await tester.pumpWidget(
      host(
        const Column(
          children: [
            KChip.tag(label: Text('a')),
            KChip.tag(label: Text('b'), tone: KTagTone.highlight),
            KChip.tag(label: Text('c'), tone: KTagTone.muted),
            KChip.tag(label: Text('d'), tone: KTagTone.problem),
          ],
        ),
      ),
    );
    final scheme = Theme.of(tester.element(find.text('a'))).colorScheme;
    Color? fill(String label) =>
        (tester
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: find.widgetWithText(KChip, label),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as ShapeDecoration)
            .color;
    expect(fill('a'), scheme.secondaryContainer);
    expect(fill('b'), scheme.tertiaryContainer);
    expect(fill('c'), scheme.surfaceContainerHighest);
    expect(fill('d'), scheme.errorContainer);
  });

  testWidgets('tag labels sit at the same height in both looks', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            KChip.tag(label: Text('Lời bài')),
            KChip.tag(label: Text('Lời bài'), outlined: true),
          ],
        ),
      ),
    );
    final labels = find.text('Lời bài');
    final first = tester.getCenter(labels.first).dy;
    expect(tester.getCenter(labels.last).dy, first);
    // Centred in the 20 dp box.
    final box = tester.getRect(find.byType(KChip).first);
    expect((first - box.center.dy).abs(), lessThanOrEqualTo(0.5));
  });

  testWidgets('KTagRow keeps the kind and ellipsizes the author', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 140,
          child: KTagRow(
            fixed: [KChip.tag(label: Text('Lời bài'))],
            shrinking: [
              KChip.tag(
                label: Text('an author with a very long name indeed'),
                outlined: true,
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final kind = tester.getSize(find.byType(KChip).first);
    final author = tester.getSize(find.byType(KChip).last);
    // One line: both chips on the same row, 20 dp, within the 140 dp.
    expect(kind.height, 20);
    expect(author.height, 20);
    expect(
      tester.getTopLeft(find.byType(KChip).last).dy,
      tester.getTopLeft(find.byType(KChip).first).dy,
    );
    expect(tester.getSize(find.byType(KTagRow)).width, lessThanOrEqualTo(140));
    // The kind chip is as wide as it is alone.
    await tester.pumpWidget(
      host(const Center(child: KChip.tag(label: Text('Lời bài')))),
    );
    expect(tester.getSize(find.byType(KChip)).width, kind.width);
  });

  testWidgets('at 200 % text the tags grow and wrap', (tester) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 200,
          child: KTagRow(
            fixed: [KChip.tag(label: Text('Lời bài'))],
            shrinking: [KChip.tag(label: Text('kanaru313'), outlined: true)],
          ),
        ),
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
    final kind = find.byType(KChip).first;
    final author = find.byType(KChip).last;
    expect(tester.getSize(kind).height, greaterThan(20));
    expect(tester.getSize(kind).height, tester.getSize(author).height);
    // Too wide for one line: the author goes under the kind.
    expect(
      tester.getTopLeft(author).dy,
      greaterThan(tester.getTopLeft(kind).dy),
    );
  });

  for (final (name, width, target) in [
    ('touch', 400.0, 48.0),
    ('desktop', 1400.0, 28.0),
  ]) {
    testWidgets(
      'token chip is 28 tall, outlined, r8, mono; target $target on $name',
      (tester) async {
        var taps = 0;
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          host(
            Center(
              child: KChip.token(
                label: const Text('{title}'),
                onTap: () => taps++,
              ),
            ),
          ),
        );
        final chip = find.byType(KChip);
        expect(tester.getSize(chip).height, target);
        final material = tester.widget<Material>(
          find.descendant(of: chip, matching: find.byType(Material)),
        );
        final shape = material.shape! as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(8));
        expect(shape.side.width, 1);
        expect(material.type, MaterialType.transparency);
        expect(
          tester
              .getSize(
                find.descendant(of: chip, matching: find.byType(Material)),
              )
              .height,
          28,
        );
        final style = tester.widget<DefaultTextStyle>(
          find
              .ancestor(
                of: find.text('{title}'),
                matching: find.byType(DefaultTextStyle),
              )
              .first,
        );
        expect(style.style.fontSize, 12);
        expect(style.style.fontFamily, KFont.mono);
        // The padded area outside the visible pill still taps.
        await tester.tapAt(tester.getTopLeft(chip) + const Offset(20, 1));
        expect(taps, 1);
      },
    );
  }
}
