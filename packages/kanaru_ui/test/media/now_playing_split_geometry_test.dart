import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

const _title = TextStyle(fontSize: 26, fontWeight: FontWeight.bold);
const _line = TextStyle(fontSize: 16);

double _reserve(TextScaler s, {double seek = 48}) =>
    splitReserve(s, titleStyle: _title, lineStyle: _line, seekHeight: seek);

void main() {
  group('column width', () {
    test('is 42 % of the body', () {
      expect(splitColumnWidth(1000), closeTo(420, 1e-9));
    });

    test('is clamped to 300..600', () {
      expect(splitColumnWidth(500), 300);
      expect(splitColumnWidth(1100), closeTo(462, 1e-9));
      expect(splitColumnWidth(2000), 600);
      expect(splitColumnWidth(1500), 600);
    });
  });

  group('cover side', () {
    final reserve = _reserve(TextScaler.noScaling);

    test('never above 500, whatever the room', () {
      expect(
        splitCoverSide(innerWidth: 900, bodyHeight: 3000, reserve: reserve),
        500,
      );
    });

    test('never above the column width', () {
      expect(
        splitCoverSide(innerWidth: 300, bodyHeight: 3000, reserve: reserve),
        300,
      );
    });

    test('is what the height leaves after the fixed reserve and padding', () {
      final side = splitCoverSide(
        innerWidth: 400,
        bodyHeight: 700,
        reserve: reserve,
      );
      expect(side, 700 - reserve - splitColumnPadding.vertical);
    });

    test('never below 96', () {
      expect(
        splitCoverSide(innerWidth: 400, bodyHeight: 100, reserve: reserve),
        96,
      );
      expect(
        splitCoverSide(innerWidth: 40, bodyHeight: 700, reserve: reserve),
        96,
      );
    });
  });

  group('reserve', () {
    test('adds the gaps, two title lines, two lines, seek and transport', () {
      final text = splitTextReserve(
        TextScaler.noScaling,
        titleStyle: _title,
        lineStyle: _line,
      );
      // 2 x ceil(26 * 1.2) + 8 + 20 + 8 + 20.
      expect(text, 2 * 32 + 8 + 20 + 8 + 20);
      expect(_reserve(TextScaler.noScaling), 24 + text + 16 + 48 + 8 + 52);
    });

    test('follows the text scale', () {
      final normal = _reserve(TextScaler.noScaling);
      final big = _reserve(const TextScaler.linear(1.5));
      expect(big, greaterThan(normal));
      // Only the text part grows.
      final text = splitTextReserve(
        const TextScaler.linear(1.5),
        titleStyle: _title,
        lineStyle: _line,
      );
      expect(
        big - normal,
        text -
            splitTextReserve(
              TextScaler.noScaling,
              titleStyle: _title,
              lineStyle: _line,
            ),
      );
    });

    test('does not depend on how many lines the title really has', () {
      // The reserve counts two title lines; a one-line title changes nothing
      // because nothing here reads the title.
      expect(_reserve(TextScaler.noScaling), _reserve(TextScaler.noScaling));
    });

    test('a taller seek slot shrinks the cover by the same amount', () {
      final a = splitCoverSide(
        innerWidth: 500,
        bodyHeight: 700,
        reserve: _reserve(TextScaler.noScaling, seek: 24),
      );
      final b = splitCoverSide(
        innerWidth: 500,
        bodyHeight: 700,
        reserve: _reserve(TextScaler.noScaling, seek: 48),
      );
      expect(a - b, 24);
    });
  });
}
