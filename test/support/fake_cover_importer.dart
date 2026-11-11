import 'dart:io';

import 'package:kanaru/src/library/data/scan/native_cover_import.dart';
import 'package:kanaru/src/library/domain/scan/native_failure.dart';
import 'package:kanaru/src/media/domain/cover_files.dart';

/// Stands in for the Rust import: writes the same files, no native call.
class FakeCoverImporter implements CoverImporter {
  FakeCoverImporter({this.fail = false});

  /// When true, every import reports a permanent failure.
  final bool fail;
  int _n = 0;

  @override
  Future<CoverImportResult> import({
    required String path,
    required String outDir,
  }) async {
    if (fail) {
      return const CoverImportResult.failed(
        NativeFailure(kind: 'corrupt', transient: false),
      );
    }
    final bytes = File(path).readAsBytesSync();
    final key = 'ab/${(++_n).toRadixString(16).padLeft(32, '0')}';
    for (final size in CoverSize.values) {
      File('$outDir/${coverRelativePath(key, size)}')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes);
    }
    return CoverImportResult.done(key: key); // colors null, like a near-gray image
  }
}
