import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/package/image_header.dart';

import '../fixtures/image_bytes.dart';

void main() {
  group('PNG', () {
    test('reads the size from IHDR', () {
      final h = readImageHeader('t.png', pngBytes(96, 32));
      expect(h.problem, isNull);
      expect((h.width, h.height), (96, 32));
    });

    test('2048 is the largest side, 2049 is refused', () {
      expect(imageHeaderProblem('t.png', pngBytes(2048, 2048)), isNull);
      expect(imageHeaderProblem('t.png', pngBytes(2049, 8)), ImageProblem.size);
      expect(imageHeaderProblem('t.png', pngBytes(8, 2049)), ImageProblem.size);
      expect(imageHeaderProblem('t.png', pngBytes(0, 8)), ImageProblem.size);
    });

    test('an acTL chunk before IDAT is an animated PNG', () {
      expect(
        imageHeaderProblem('t.png', pngBytes(8, 8, animated: true)),
        ImageProblem.animated,
      );
    });

    test('a signature without IHDR first, or cut short, is refused', () {
      final bytes = pngBytes(8, 8);
      bytes[12] = 0x58; // IHDR -> XHDR
      expect(imageHeaderProblem('t.png', bytes), ImageProblem.format);
      expect(
        imageHeaderProblem(
          't.png',
          Uint8List.sublistView(pngBytes(8, 8), 0, 20),
        ),
        ImageProblem.format,
      );
    });

    test('a chunk length that runs past the end does not loop or throw', () {
      final bytes = pngBytes(8, 8);
      // IHDR length -> 0xffffffff: the walk ends at the end of the data.
      bytes.setAll(8, const [0xff, 0xff, 0xff, 0xff]);
      expect(imageHeaderProblem('t.png', bytes), isNull);
    });
  });

  group('WebP', () {
    test('lossy VP8 frame dimensions', () {
      final h = readImageHeader('t.webp', webpLossy(120, 40));
      expect((h.problem, h.width, h.height), (null, 120, 40));
    });

    test('lossless VP8L 14-bit dimensions', () {
      final h = readImageHeader('t.webp', webpLossless(2048, 16));
      expect((h.problem, h.width, h.height), (null, 2048, 16));
    });

    test('extended VP8X canvas dimensions', () {
      final h = readImageHeader('t.webp', webpExtended(300, 200));
      expect((h.problem, h.width, h.height), (null, 300, 200));
    });

    test('the animation flag of VP8X is refused', () {
      expect(
        imageHeaderProblem('t.webp', webpExtended(8, 8, animated: true)),
        ImageProblem.animated,
      );
    });

    test('an unknown first chunk is refused', () {
      expect(
        imageHeaderProblem('t.webp', webpChunk('ANIM')),
        ImageProblem.format,
      );
    });

    test('over 2048 is refused for each chunk type', () {
      expect(
        imageHeaderProblem('t.webp', webpLossy(2049, 8)),
        ImageProblem.size,
      );
      expect(
        imageHeaderProblem('t.webp', webpExtended(8, 2049)),
        ImageProblem.size,
      );
    });

    test('a bad VP8 start code or VP8L signature is refused', () {
      final lossy = webpLossy(8, 8)..[23] = 0;
      expect(imageHeaderProblem('t.webp', lossy), ImageProblem.format);
      final lossless = webpLossless(8, 8)..[20] = 0;
      expect(imageHeaderProblem('t.webp', lossless), ImageProblem.format);
    });

    test('truncated files are refused, never thrown on', () {
      for (final full in [
        webpLossy(8, 8),
        webpLossless(8, 8),
        webpExtended(8, 8),
      ]) {
        for (var n = 0; n < full.length; n++) {
          final cut = Uint8List.sublistView(full, 0, n);
          // Any cut either parses as before or is refused with a reason.
          expect(() => imageHeaderProblem('t.webp', cut), returnsNormally);
        }
      }
      expect(
        imageHeaderProblem(
          't.webp',
          Uint8List.sublistView(webpLossy(8, 8), 0, 24),
        ),
        ImageProblem.format,
      );
    });
  });

  group('type and extension', () {
    test('a PNG named .webp and a WebP named .png are refused', () {
      expect(
        imageHeaderProblem('t.webp', pngBytes(8, 8)),
        ImageProblem.extension,
      );
      expect(
        imageHeaderProblem('t.png', webpLossy(8, 8)),
        ImageProblem.extension,
      );
    });

    test('anything else is not an image', () {
      expect(imageHeaderProblem('t.png', Uint8List(0)), ImageProblem.format);
      expect(
        imageHeaderProblem('t.png', Uint8List.fromList('GIF89a....'.codeUnits)),
        ImageProblem.format,
      );
      expect(
        imageHeaderProblem(
          't.png',
          Uint8List.fromList('RIFF....WAVE'.codeUnits),
        ),
        ImageProblem.format,
      );
    });
  });
}
