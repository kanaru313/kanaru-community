/// Last segment of [path] (empty for `/`).
String folderBaseName(String path) => path.substring(path.lastIndexOf('/') + 1);

/// [path] without its last segment; `/` for a top-level path.
String folderParentPath(String path) {
  final i = path.lastIndexOf('/');
  return i <= 0 ? '/' : path.substring(0, i);
}
