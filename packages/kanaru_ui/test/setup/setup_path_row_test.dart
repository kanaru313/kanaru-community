import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('renders a long path without overflow ($name)', (tester) async {
      useWindow(tester, const Size(360, 800));
      await tester.pumpWidget(
        host(
          SetupPathRow(
            icon: KIcons.folders,
            title: const Text('WhatsApp Audio'),
            path: const Text(
              'Internal storage › Android › media › com.whatsapp › WhatsApp › Media › WhatsApp Audio',
            ),
            count: const Text('63 songs'),
            badge: const Text('Suggested'),
            onRemove: () {},
            removeTooltip: 'Remove',
          ),
          brightness: brightness,
          textScale: scale,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('shows count and badge, and removes on the cross', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    var removed = 0;
    await tester.pumpWidget(
      host(
        SetupPathRow(
          icon: KIcons.folderOff,
          title: const Text('Ringtones'),
          path: const Text('Internal storage › Music › Ringtones'),
          count: const Text('14 songs'),
          badge: const Text('Suggested'),
          onRemove: () => removed++,
          removeTooltip: 'Remove Ringtones',
        ),
      ),
    );
    expect(find.text('14 songs'), findsOneWidget);
    expect(find.text('Suggested'), findsOneWidget);
    expect(find.byIcon(KIcons.folderOff), findsOneWidget);
    await tester.tap(find.byIcon(KIcons.close));
    expect(removed, 1);
    expect(
      tester.getSize(find.byType(IconButton)).shortestSide,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('without onRemove there is no cross', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        const SetupPathRow(
          icon: KIcons.folders,
          title: Text('Music'),
          path: Text('~/Music'),
        ),
      ),
    );
    expect(find.byIcon(KIcons.close), findsNothing);
  });

  testWidgets('the remove button is labelled for screen readers', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        SetupPathRow(
          icon: KIcons.folders,
          title: const Text('Music'),
          path: const Text('~/Music'),
          onRemove: () {},
          removeTooltip: 'Remove Music',
        ),
      ),
    );
    expect(find.byTooltip('Remove Music'), findsOneWidget);
    handle.dispose();
  });
}
