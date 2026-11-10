import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/platform/data/file_manager_unsupported.dart';
import 'package:kanaru/src/platform/domain/file_manager.dart';

void main() {
  test('cannot reveal and reports unsupported', () async {
    const manager = UnsupportedFileManager();
    expect(manager.canReveal, isFalse);
    final result = await manager.reveal('/tmp/x');
    expect(result, isA<Err<void, FileManagerError>>());
    expect(
      (result as Err<void, FileManagerError>).error,
      FileManagerError.unsupported,
    );
  });
}
