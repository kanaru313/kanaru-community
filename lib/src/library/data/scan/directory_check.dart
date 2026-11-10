import 'dart:io';

/// Whether [path] is an existing folder (a file-system call; Linux folder
/// dialogs only, MediaStore paths are never checked).
Future<bool> directoryExists(String path) => Directory(path).exists();
