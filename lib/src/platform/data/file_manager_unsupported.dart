import '../../foundation/result.dart';
import '../domain/file_manager.dart';

/// Platforms without a file-manager integration (Android for now).
class UnsupportedFileManager implements FileManager {
  const UnsupportedFileManager();

  @override
  bool get canReveal => false;

  @override
  Future<Result<void, FileManagerError>> reveal(String absolutePath) async =>
      const Err(FileManagerError.unsupported);
}
