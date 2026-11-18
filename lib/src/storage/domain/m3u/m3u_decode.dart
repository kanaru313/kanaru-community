import 'dart:convert';
import 'dart:typed_data';

/// Windows-1252 for bytes 0x80-0x9F (the rest equals Latin-1). The five
/// bytes it leaves undefined keep their code point.
const _cp1252High = <int>[
  0x20AC, 0x0081, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021, //
  0x02C6, 0x2030, 0x0160, 0x2039, 0x0152, 0x008D, 0x017D, 0x008F, //
  0x0090, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014, //
  0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0x009D, 0x017E, 0x0178, //
];

bool _hasBom(Uint8List b) =>
    b.length >= 3 && b[0] == 0xEF && b[1] == 0xBB && b[2] == 0xBF;

/// The lines of [bytes] as raw byte views, after a UTF-8 BOM: ends are `\r\n`,
/// `\n` or a lone `\r`. A final line end does not add an empty line. Lazy, so
/// a reader can stop early on a huge file.
Iterable<Uint8List> iterateM3uLines(Uint8List bytes) sync* {
  var lineStart = _hasBom(bytes) ? 3 : 0;
  var i = lineStart;
  while (i < bytes.length) {
    final b = bytes[i];
    if (b == 0x0A || b == 0x0D) {
      yield Uint8List.sublistView(bytes, lineStart, i);
      if (b == 0x0D && i + 1 < bytes.length && bytes[i + 1] == 0x0A) i++;
      lineStart = i + 1;
    }
    i++;
  }
  if (lineStart < bytes.length) {
    yield Uint8List.sublistView(bytes, lineStart, bytes.length);
  }
}

/// [iterateM3uLines] as a list.
List<Uint8List> splitM3uLines(Uint8List bytes) =>
    iterateM3uLines(bytes).toList();

/// One line as text: strict UTF-8, or Windows-1252 when this line is not
/// valid UTF-8. Decided per line so one ANSI `#EXTINF` does not garble the
/// UTF-8 paths around it. A NUL stays for the classifier to reject.
String decodeM3uLine(Uint8List line) {
  try {
    return utf8.decode(line);
  } on FormatException {
    return String.fromCharCodes([
      for (final b in line)
        if (b >= 0x80 && b <= 0x9F) _cp1252High[b - 0x80] else b,
    ]);
  }
}
