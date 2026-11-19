import '../../domain/playlists/playlist_import.dart';

/// Why a line of an M3U file did not become a playlist entry. The report
/// groups lines by kind: [unresolved] and [outsideFolders] share one group,
/// [notScanned] and [noBaseFolder] each have their own.
enum M3uProblemKind { unresolved, outsideFolders, notScanned, noBaseFolder }

/// One unusable path line.
class M3uProblemLine {
  const M3uProblemLine({
    required this.line,
    required this.text,
    required this.kind,
  });

  /// Line number in the file, counting from 1.
  final int line;
  final String text;
  final M3uProblemKind kind;
}

/// The lines of a file mapped to library tracks and placeholders.
class M3uMatch {
  const M3uMatch({
    required this.entries,
    required this.problems,
    required this.outsideFolders,
    required this.notScanned,
    required this.notPresent,
    required this.totalLines,
    required this.truncated,
  });

  /// Usable lines in file order, repeats kept.
  final List<ImportedEntry> entries;

  /// Every unusable line in file order.
  final List<M3uProblemLine> problems;
  final int outsideFolders;
  final int notScanned;

  /// Distinct existing tracks whose file is not present now.
  final int notPresent;
  final int totalLines;
  final bool truncated;
}

/// Why an import produced no playlist.
enum M3uImportError {
  /// The picked file is not a regular `.m3u` / `.m3u8` file.
  notAFile,
  tooLarge,
  unreadable,

  /// No line became an entry.
  nothingFound,

  /// Every unusable line lay outside the music folders and none was usable.
  allOutsideFolders,
}

/// Reading and matching progress. [total] is null while the file is read.
class M3uImportProgress {
  const M3uImportProgress({
    required this.fileName,
    required this.done,
    this.total,
  });

  final String fileName;
  final int done;
  final int? total;
}

/// A created playlist and what the report needs.
class M3uImportResult {
  const M3uImportResult({
    required this.playlistUid,
    required this.name,
    required this.fileName,
    required this.added,
    required this.songsAdded,
    required this.totalLines,
    required this.notInLibrary,
    required this.outsideFolders,
    required this.notScanned,
    required this.problems,
    required this.truncated,
  });

  final String playlistUid;
  final String name;
  final String fileName;

  /// Entries created (one per usable line, repeats included).
  final int added;

  /// Distinct songs among them: what "N songs" shows.
  final int songsAdded;
  final int totalLines;

  /// Distinct songs that are placeholders or whose track is not present.
  final int notInLibrary;
  final int outsideFolders;
  final int notScanned;
  final List<M3uProblemLine> problems;
  final bool truncated;

  /// Nothing to report: the UI shows a short confirmation only.
  bool get clean =>
      problems.isEmpty && outsideFolders == 0 && notScanned == 0 && !truncated;
}

enum M3uExportError { playlistGone, folderUnknown, writeFailed }

/// [written] and [skipped] count distinct songs (repeats once).
class M3uExportResult {
  const M3uExportResult({required this.written, required this.skipped});

  final int written;
  final int skipped;
}
