/// A music folder as the scan sees it: a live local source and its root.
class ScanFolder {
  const ScanFolder({
    required this.sourceId,
    required this.sourceUid,
    required this.root,
  });

  final int sourceId;
  final String sourceUid;

  /// Absolute path of the folder.
  final String root;

  /// Absolute path of the file at [locator].
  String pathOf(String locator) =>
      root.endsWith('/') ? '$root$locator' : '$root/$locator';

  @override
  String toString() => 'ScanFolder($sourceId, $root)';
}
