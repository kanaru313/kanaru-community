/// Lower-case extensions the library scans.
const Set<String> audioExtensions = {
  'mp3', 'flac', 'm4a', 'aac', 'alac', 'ogg', 'oga', 'opus', //
  'wav', 'aif', 'aiff', 'ape', 'wv', 'dsf', 'dff',
};

String _baseName(String path) => path.substring(path.lastIndexOf('/') + 1);

String _extension(String path) {
  final name = _baseName(path);
  final dot = name.lastIndexOf('.');
  return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
}

/// Whether [path] ends in one of [audioExtensions] (any case).
bool isAudioPath(String path) => audioExtensions.contains(_extension(path));

/// Whether [path] is a `.lrc` lyrics sidecar (any case).
bool isLyricsSidecarPath(String path) => _extension(path) == 'lrc';

const Set<String> _junkFolderNames = {
  'lost+found',
  '@eaDir',
  '.Trashes',
  '.snapshot',
  '.snapshots',
  '.zfs',
  '.stversions',
  '#recycle',
  '@Recycle',
  '#snapshot',
  '.@__thumb',
  '.AppleDouble',
};

/// Whether a scan never enters a folder with this [name] below a root: trash
/// bins, snapshot and old-version folders, NAS thumbnail and recycle folders,
/// and every dot-folder (which also covers the home trash under `.local`).
/// A root that is itself a dot-folder is still scanned: only names below it
/// are tested.
bool isSkippedFolderName(String name) =>
    name.startsWith('.') ||
    _junkFolderNames.contains(name) ||
    name.toUpperCase() == r'$RECYCLE.BIN';

/// An audio file found by a listing.
class LocalAudioFile {
  const LocalAudioFile({
    required this.path,
    required this.sizeBytes,
    required this.mtimeMs,
    this.durationMs,
  });

  final String path;
  final int sizeBytes;
  final int mtimeMs;

  /// Known only where the platform index has it (Android MediaStore).
  final int? durationMs;
}

/// A `.lrc` sidecar found by a listing.
class LocalSidecarFile {
  const LocalSidecarFile({
    required this.path,
    required this.sizeBytes,
    required this.mtimeMs,
  });

  final String path;
  final int sizeBytes;
  final int mtimeMs;
}

/// Why a listing is [AudioListing.reachable] false.
enum UnreachableReason {
  /// The root is missing or cannot be listed.
  missing,

  /// The walk ran past its time limit and was killed.
  timedOut,

  /// An earlier walk of the same root has not exited yet.
  busy,

  /// The platform refused the read (missing media permission).
  permission,

  /// The platform query failed.
  failed,
}

/// Everything one listing of a root found, and what it could not see.
class AudioListing {
  const AudioListing({
    this.reachable = true,
    this.audio = const [],
    this.lyrics = const [],
    this.unreadableDirs = const [],
    this.emptyDirs = const [],
    this.unstattable = const [],
    this.excludedOut = 0,
    this.skippedOut = 0,
    this.shortOut = 0,
    this.unreachableReason = UnreachableReason.missing,
    this.skippedLinks = 0,
    this.undecodableNames = 0,
    this.undecodableSampleDirs = const [],
  });

  /// A listing of a root that could not be read: missing, unlistable, or a
  /// walk that timed out.
  const AudioListing.unreachable([
    UnreachableReason reason = UnreachableReason.missing,
  ]) : this(reachable: false, unreachableReason: reason);

  /// False: the root is missing, unlistable, or the walk timed out. Nothing
  /// may be concluded about stored rows under it.
  final bool reachable;
  final List<LocalAudioFile> audio;
  final List<LocalSidecarFile> lyrics;

  /// Absolute paths. Stored rows under these are kept: what lies below is
  /// unknown.
  final List<String> unreadableDirs, emptyDirs, unstattable;

  /// Items left out by the user's folder exclusions. An item is a file where
  /// the platform can count files (Android) and a whole folder where it
  /// cannot without entering it (Linux), so only `> 0` is meaningful across
  /// platforms; show it in the report without a unit.
  final int excludedOut;

  /// Hidden audio and `.lrc` files left out. Hidden and junk folders are not
  /// counted: they are everywhere (`.stfolder`, `lost+found`, `@eaDir`) and
  /// say nothing about what the user filtered.
  final int skippedOut;

  /// Files dropped by the `skipShorterThanMs` pre-filter (Android; Linux is
  /// always 0).
  final int shortOut;

  /// The scan's "filtered out" count is `excludedOut + shortOut`: what the
  /// user's own settings removed. Only that sum may switch off the empty-root
  /// guard; [skippedOut] is for the report.
  int get filteredOut => excludedOut + shortOut;

  /// Meaningful only when [reachable] is false.
  final UnreachableReason unreachableReason;

  /// Folder symlinks not followed (counted so the scan report can say so).
  final int skippedLinks;

  /// Entries whose name is not valid UTF-8 (not listed), with up to three
  /// folders holding them for the log.
  final int undecodableNames;
  final List<String> undecodableSampleDirs;
}

/// A folder holding audio, as the platform index reports it.
class AudioFolderSummary {
  const AudioFolderSummary({required this.path, required this.audioCount});

  final String path;

  /// After the short-file pre-filter when the platform knows durations.
  final int audioCount;
}

/// How the user picks a music folder on this platform.
enum FolderChoice { systemDialog, mediaStoreSheet }

/// Lists the audio of a folder and answers the platform questions around
/// choosing music folders. Linux walks the file system; Android asks
/// MediaStore.
abstract interface class LocalAudioCatalog {
  /// Lists [root]. [excludedKeys] are folder keys relative to [root] (the
  /// root's own empty key is never passed). [skipShorterThanMs] is the
  /// Android pre-filter (0 = off). Failures are reported in the result (`reachable` false with an
  /// [UnreachableReason]); this never throws for a platform failure.
  Future<AudioListing> listAudio({
    required String root,
    required Set<String> excludedKeys,
    int skipShorterThanMs = 0,
  });

  /// Android: MediaStore folders that hold audio. Linux: empty.
  Future<List<AudioFolderSummary>> audioFolders();

  /// Linux: `XDG_MUSIC_DIR`, else `~/Music`. Android: `<internal>/Music` when
  /// it holds audio. Null when there is no suggestion.
  Future<String?> suggestedMusicFolder();

  /// Resolves links, drops a trailing slash; falls back to the normalised
  /// path when resolving fails.
  Future<String> canonicalize(String path);

  FolderChoice get folderChoice;

  /// Linux: the system folder dialog. Android: throws [UnsupportedError].
  Future<String?> pickFolder({String? initialDirectory});
}
