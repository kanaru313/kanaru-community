import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

/// A valid 1 x 1 PNG.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNgYGD4DwABBAEA'
  'gh6qSAAAAABJRU5ErkJggg==',
);

ColoredBox _face(WidgetTester tester) => tester.widget<ColoredBox>(
  find.descendant(
    of: find.byType(KSourceAvatar),
    matching: find.byType(ColoredBox),
  ),
);

void main() {
  testWidgets('without a picture it shows the first letter', (tester) async {
    useWindow(tester, const Size(200, 200));
    await tester.pumpWidget(
      host(const KSourceAvatar(label: 'lrclib', size: 24)),
    );
    expect(find.text('L'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(tester.getSize(find.byType(KSourceAvatar)), const Size(24, 24));
  });

  testWidgets('with a picture it shows the picture, not the letter', (
    tester,
  ) async {
    useWindow(tester, const Size(200, 200));
    await tester.pumpWidget(
      host(KSourceAvatar(label: 'NetEase', size: 22, imageBytes: _png)),
    );
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('N'), findsNothing);
  });

  testWidgets('removed: the letter on grey even when a picture is known', (
    tester,
  ) async {
    useWindow(tester, const Size(200, 200));
    await tester.pumpWidget(
      host(
        KSourceAvatar(label: 'zing', size: 24, imageBytes: _png, removed: true),
      ),
    );
    final scheme = Theme.of(tester.element(find.byType(KSourceAvatar)))
        .colorScheme;
    expect(find.byType(Image), findsNothing);
    expect(find.text('Z'), findsOneWidget);
    expect(_face(tester).color, scheme.outlineVariant);
  });

  testWidgets('a damaged picture falls back to the letter', (tester) async {
    useWindow(tester, const Size(200, 200));
    await tester.pumpWidget(
      host(
        KSourceAvatar(
          label: 'Musixmatch',
          size: 24,
          imageBytes: Uint8List.fromList([1, 2, 3]),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('M'), findsOneWidget);
  });

  test('initialOf handles empty, spaces and non-ASCII names', () {
    expect(KSourceAvatar.initialOf(''), '?');
    expect(KSourceAvatar.initialOf('  '), '?');
    expect(KSourceAvatar.initialOf(' đài'), 'Đ');
  });

  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('fits its square in $name', (tester) async {
      useWindow(tester, const Size(200, 200));
      await tester.pumpWidget(
        host(
          const KSourceAvatar(label: 'Zing', size: 16),
          brightness: brightness,
          textScale: scale,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(KSourceAvatar)), const Size(16, 16));
    });
  }
}
