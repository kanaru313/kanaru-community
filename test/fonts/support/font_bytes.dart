import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// One record of a crafted `name` table.
typedef NameRecord = ({int platform, int id, String text});

/// A `name` table (format 0) holding [records]; platform 1 is stored as
/// Latin-1, the others as UTF-16BE.
Uint8List nameTable(List<NameRecord> records) {
  final strings = BytesBuilder();
  final headers = BytesBuilder();
  for (final r in records) {
    final raw = r.platform == 1
        ? latin1.encode(r.text)
        : Uint8List.fromList([
            for (final u in r.text.codeUnits) ...[u >> 8, u & 0xFF],
          ]);
    final h = ByteData(12)
      ..setUint16(0, r.platform)
      ..setUint16(2, 0)
      ..setUint16(4, 0)
      ..setUint16(6, r.id)
      ..setUint16(8, raw.length)
      ..setUint16(10, strings.length);
    headers.add(h.buffer.asUint8List());
    strings.add(raw);
  }
  final head = ByteData(6)
    ..setUint16(0, 0)
    ..setUint16(2, records.length)
    ..setUint16(4, 6 + records.length * 12);
  return (BytesBuilder()
        ..add(head.buffer.asUint8List())
        ..add(headers.takeBytes())
        ..add(strings.takeBytes()))
      .takeBytes();
}

/// A small sfnt file: [magic] then a table directory and the [tables].
Uint8List sfnt(int magic, Map<String, Uint8List> tables) {
  final dir = 12 + tables.length * 16;
  final header = ByteData(dir)
    ..setUint32(0, magic)
    ..setUint16(4, tables.length);
  final body = BytesBuilder();
  var i = 0;
  for (final e in tables.entries) {
    final entry = 12 + i * 16;
    for (var c = 0; c < 4; c++) {
      header.setUint8(entry + c, e.key.codeUnitAt(c));
    }
    header
      ..setUint32(entry + 8, dir + body.length)
      ..setUint32(entry + 12, e.value.length);
    body.add(e.value);
    i++;
  }
  return (BytesBuilder()
        ..add(header.buffer.asUint8List())
        ..add(body.takeBytes()))
      .takeBytes();
}

final _filler = Uint8List(8);

/// A TrueType-flavoured file with every required table.
Uint8List ttf(
  List<NameRecord> names, {
  int magic = 0x00010000,
  Map<String, Uint8List> extra = const {},
}) => sfnt(magic, {
  'cmap': _filler,
  'glyf': _filler,
  'loca': _filler,
  'name': nameTable(names),
  ...extra,
});

/// An OpenType-CFF file with every required table.
Uint8List otf(List<NameRecord> names) => sfnt(0x4F54544F, {
  'CFF ': _filler,
  'cmap': _filler,
  'name': nameTable(names),
});

/// The Nunito Regular shipped with the app: a real TrueType file.
Uint8List nunitoBytes() =>
    File('assets/fonts/Nunito-Regular.ttf').readAsBytesSync();
