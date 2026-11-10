import '../../foundation/result.dart';

/// Why [FileManager.reveal] did not open anything.
enum FileManagerError {
  /// This platform has no file-manager integration.
  unsupported,

  /// The path does not exist (any more).
  notFound,

  /// The file manager could not be reached or started.
  failed,
}

/// Shows a file or folder in the system file manager.
abstract interface class FileManager {
  /// False when [reveal] can never work here; UI shows the row dimmed.
  bool get canReveal;

  /// Opens the file manager with the file at [absolutePath] selected; a
  /// directory path opens that directory itself.
  Future<Result<void, FileManagerError>> reveal(String absolutePath);
}
