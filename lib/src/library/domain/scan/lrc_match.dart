import '../../../storage/domain/local_folder_listing.dart';

/// The `.lrc` sidecar matched to an audio file.
class LrcMatch {
  const LrcMatch({required this.locator, required this.revision});

  /// Locator of the `.lrc` file.
  final String locator;

  /// `'<mtimeMs>:<sizeBytes>'`, like a track revision.
  final String revision;

  @override
  bool operator ==(Object other) =>
      other is LrcMatch &&
      other.locator == locator &&
      other.revision == revision;

  @override
  int get hashCode => Object.hash(locator, revision);
}

String _stem(String locator) {
  final name = locator.substring(locator.lastIndexOf('/') + 1);
  final dot = name.lastIndexOf('.');
  return (dot <= 0 ? name : name.substring(0, dot)).toLowerCase();
}

/// The `<mtimeMs>:<sizeBytes>` revision string of a file.
String revisionOf(int mtimeMs, int sizeBytes) => '$mtimeMs:$sizeBytes';

/// Sidecars of a listing indexed by folder and lower-cased stem, built once
/// per scan.
class LyricsIndex {
  LyricsIndex(Map<String, List<ListedLyrics>> lyrics) {
    for (final entry in lyrics.entries) {
      final byStem = _byFolder[entry.key] = <String, ListedLyrics>{};
      // Sorted, so two sidecars with one stem ("a.lrc", "A.LRC") always give
      // the same winner.
      final sorted = [...entry.value]
        ..sort((a, b) => a.locator.compareTo(b.locator));
      for (final l in sorted) {
        byStem.putIfAbsent(_stem(l.locator), () => l);
      }
    }
  }

  final Map<String, Map<String, ListedLyrics>> _byFolder = {};

  /// The sidecar in the same folder with the same stem as [locator] (any
  /// case), or null.
  LrcMatch? match(String locator) {
    final l = _byFolder[folderKeyOf(locator)]?[_stem(locator)];
    if (l == null) return null;
    return LrcMatch(
      locator: l.locator,
      revision: revisionOf(l.mtimeMs, l.sizeBytes),
    );
  }
}

/// One-off form of [LyricsIndex.match].
LrcMatch? lrcFor(String locator, Map<String, List<ListedLyrics>> lyrics) =>
    LyricsIndex(lyrics).match(locator);
