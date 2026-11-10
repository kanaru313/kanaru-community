import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Int64List;

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/data/scan/native_cover_import.dart';
import 'package:kanaru/src/rust/api/covers.dart';
import 'package:kanaru/src/rust/api/error.dart';

void main() {
  const key = 'ab/0123456789abcdef0123456789abcdef';

  test('a done import carries the key and the colours', () {
    final r = coverImportOf(
      CoverImportDto(
        key: key,
        colors: CoverColorsDto(
          seed: 0xFFAA0000,
          palette: Int64List.fromList([0xFFAA0000, 0xFF0000AA]),
        ),
      ),
    );
    expect(r.isDone, isTrue);
    expect(r.key, key);
    expect(r.colors?.seed, 0xFFAA0000);
    expect(r.colors?.palette, [0xFFAA0000, 0xFF0000AA]);
    expect(r.failure, isNull);
  });

  test('a near-gray image has a key and no colours', () {
    final r = coverImportOf(const CoverImportDto(key: key));
    expect(r.isDone, isTrue);
    expect(r.colors, isNull);
  });

  test('errors keep their kind and transient flag', () {
    for (final (kind, transient) in [
      (NativeErrorKind.io, true),
      (NativeErrorKind.corrupt, false),
      (NativeErrorKind.unsupported, false),
      (NativeErrorKind.tooLarge, false),
    ]) {
      final r = coverImportOf(
        CoverImportDto(
          error: NativeError(kind: kind, detail: 'x', transient: transient),
        ),
      );
      expect(r.isDone, isFalse);
      expect(r.failure?.kind, kind.name);
      expect(r.failure?.transient, transient);
    }
  });

  test('a result with neither key nor error is a permanent failure', () {
    final r = coverImportOf(const CoverImportDto());
    expect(r.failure?.transient, isFalse);
  });
}
