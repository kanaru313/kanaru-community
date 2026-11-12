import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:kanaru_ui/src/widgets/k_cover.dart' show coverSeedHash;
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

/// 1x1 transparent PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

class _BadImage extends ImageProvider<_BadImage> {
  @override
  Future<_BadImage> obtainKey(ImageConfiguration c) => Future.value(this);
  @override
  ImageStreamCompleter loadImage(_BadImage key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(Future.error(const FormatException('bad')));
}

Color _fill(WidgetTester tester) =>
    (tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byType(KCover),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration)
        .color!;

/// Uncompressed 24-bit BMP of a solid colour (the codec decodes it natively).
Uint8List _bmp(int w, int h) {
  final rowSize = (w * 3 + 3) & ~3;
  final size = 54 + rowSize * h;
  final data = ByteData(size);
  data.setUint8(0, 0x42);
  data.setUint8(1, 0x4d);
  data.setUint32(2, size, Endian.little);
  data.setUint32(10, 54, Endian.little);
  data.setUint32(14, 40, Endian.little);
  data.setInt32(18, w, Endian.little);
  data.setInt32(22, h, Endian.little);
  data.setUint16(26, 1, Endian.little);
  data.setUint16(28, 24, Endian.little);
  data.setUint32(34, rowSize * h, Endian.little);
  return data.buffer.asUint8List();
}

void main() {
  test('seed hash is deterministic and spreads seeds', () {
    expect(coverSeedHash('Album A'), coverSeedHash('Album A'));
    expect(coverSeedHash('Album A'), isNot(coverSeedHash('Album B')));
    // FNV-1a reference value for the empty and "a" inputs.
    expect(coverSeedHash(''), 0x811c9dc5);
    expect(coverSeedHash('a'), 0xe40c292c);
  });

  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('null image shows a stable placeholder ($name)', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const KCover(image: null, size: 64, placeholderSeed: 'seed'),
          brightness: brightness,
          textScale: scale,
        ),
      );
      final first = _fill(tester);
      await tester.pumpWidget(
        host(
          const KCover(image: null, size: 64, placeholderSeed: 'seed'),
          brightness: brightness,
          textScale: scale,
        ),
      );
      expect(_fill(tester), first);
      expect(find.byIcon(KIcons.songs), findsOneWidget);
    });
  }

  testWidgets('different seeds give different placeholder colours', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const KCover(image: null, size: 64, placeholderSeed: 'a')),
    );
    final a = _fill(tester);
    await tester.pumpWidget(
      host(const KCover(image: null, size: 64, placeholderSeed: 'zebra')),
    );
    expect(_fill(tester), isNot(a));
  });

  testWidgets('decodes at size x devicePixelRatio', (tester) async {
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      host(
        Center(
          child: KCover(
            image: MemoryImage(_png),
            size: 50,
            placeholderSeed: 's',
          ),
        ),
      ),
    );
    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image as ResizeImage;
    expect(provider.width, 150);
    expect(provider.height, 150);
  });

  testWidgets('load error shows errorFallback when given', (tester) async {
    await tester.pumpWidget(
      host(
        Center(
          child: KCover(
            image: _BadImage(),
            size: 50,
            placeholderSeed: 's',
            errorFallback: const Text('source cover'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('source cover'), findsOneWidget);
  });

  testWidgets('load error falls back to the placeholder', (tester) async {
    await tester.pumpWidget(
      host(
        Center(
          child: KCover(image: _BadImage(), size: 50, placeholderSeed: 's'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byIcon(KIcons.songs), findsOneWidget);
  });

  testWidgets('circle clips with an oval', (tester) async {
    await tester.pumpWidget(
      host(
        const KCover(image: null, size: 40, placeholderSeed: 's', circle: true),
      ),
    );
    expect(find.byType(ClipOval), findsOneWidget);
  });

  testWidgets('non-square art keeps its aspect when downscaled', (
    tester,
  ) async {
    final src = _bmp(100, 60);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      host(
        Center(
          child: KCover(
            image: MemoryImage(src),
            size: 50,
            placeholderSeed: 's',
          ),
        ),
      ),
    );
    final provider =
        tester.widget<Image>(find.byType(Image)).image as ResizeImage;
    expect(provider.policy, ResizeImagePolicy.fit);
    // Resolve a separate provider with the same resize settings, inside
    // runAsync so decoding runs on the real event loop.
    final decoded = await tester.runAsync(() {
      final done = Completer<ui.Image>();
      ResizeImage(
            MemoryImage(_bmp(100, 60)),
            width: provider.width,
            height: provider.height,
            policy: provider.policy,
          )
          .resolve(ImageConfiguration.empty)
          .addListener(
            ImageStreamListener(
              (i, _) => done.complete(i.image),
              onError: (e, _) => done.completeError(e),
            ),
          );
      return done.future.timeout(const Duration(seconds: 5));
    });
    // 100x60 fitted into 50x50 -> 50x30, not squashed to 50x50.
    expect(decoded!.width / decoded.height, closeTo(100 / 60, 0.1));
  });

  test('placeholder colours are stable per seed and differ by brightness', () {
    final a = KCoverPlaceholderColors.of('Album A', Brightness.light);
    expect(
      KCoverPlaceholderColors.of('Album A', Brightness.light).fill,
      a.fill,
    );
    expect(
      KCoverPlaceholderColors.of('Album B', Brightness.light).fill,
      isNot(a.fill),
    );
    final dark = KCoverPlaceholderColors.of('Album A', Brightness.dark);
    expect(dark.fill, isNot(a.fill));
    expect(
      HSLColor.fromColor(dark.fill).hue.round(),
      HSLColor.fromColor(a.fill).hue.round(),
    );
  });

  group('KCover.loading', () {
    testWidgets('grey surfaceContainerHigh box, no icon, right size', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const Center(child: KCover.loading(size: 56))),
      );
      expect(tester.getSize(find.byType(KCover)), const Size(56, 56));
      expect(
        find.descendant(of: find.byType(KCover), matching: find.byType(Icon)),
        findsNothing,
      );
      expect(
        _fill(tester),
        buildKanaruTheme(brightness: Brightness.light)
            .colorScheme
            .surfaceContainerHigh,
      );
    });

    testWidgets('circle is clipped round', (tester) async {
      await tester.pumpWidget(
        host(const Center(child: KCover.loading(size: 56, circle: true))),
      );
      expect(find.byType(ClipOval), findsOneWidget);
      expect(find.byType(ClipRRect), findsNothing);
    });

    testWidgets('radius is respected', (tester) async {
      final r = BorderRadius.circular(10);
      await tester.pumpWidget(
        host(Center(child: KCover.loading(size: 56, radius: r))),
      );
      expect(tester.widget<ClipRRect>(find.byType(ClipRRect)).borderRadius, r);
    });
  });
}
