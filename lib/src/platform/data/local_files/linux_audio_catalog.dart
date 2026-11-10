import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../../domain/local_audio_catalog.dart';
import 'audio_tree_walk.dart';
import 'mount_points.dart';
import 'walk_isolate.dart';
import 'xdg_music_folder.dart';

/// [LocalAudioCatalog] for Linux: a `dart:io` walk on a killable isolate and
/// the system folder dialog.
class LinuxAudioCatalog implements LocalAudioCatalog {
  LinuxAudioCatalog({
    WalkIsolateRunner? runner,
    Map<String, String>? environment,
    Set<String> Function()? mountPoints,
  }) : _runner = runner ?? WalkIsolateRunner(),
       _env = environment ?? Platform.environment,
       _mountPoints = mountPoints ?? readMountPoints;

  static final _log = Logger('platform.files');

  final WalkIsolateRunner _runner;
  final Map<String, String> _env;
  final Set<String> Function() _mountPoints;

  @override
  FolderChoice get folderChoice => FolderChoice.systemDialog;

  @override
  Future<AudioListing> listAudio({
    required String root,
    required Set<String> excludedKeys,
    int skipShorterThanMs = 0,
  }) async {
    final listing = await _runner.run(
      WalkRequest(
        root: root,
        excludedKeys: excludedKeys,
        mountPoints: _mountPoints(),
      ),
    );
    if (listing.skippedLinks > 0) {
      _log.info('$root: ${listing.skippedLinks} folder links not followed');
    }
    if (listing.undecodableNames > 0) {
      _log.warning(
        '$root: ${listing.undecodableNames} names are not valid UTF-8 '
        '(e.g. in ${listing.undecodableSampleDirs.join(', ')})',
      );
    }
    return listing;
  }

  @override
  Future<List<AudioFolderSummary>> audioFolders() async => const [];

  @override
  Future<String?> suggestedMusicFolder() => readXdgMusicDirectory(_env);

  @override
  Future<String> canonicalize(String path) async {
    try {
      // Links first: `link/..` is the parent of the link's target.
      return _stripTrailingSlash(await Directory(path).resolveSymbolicLinks());
    } on FileSystemException catch (error) {
      final normalized = _stripTrailingSlash(p.normalize(path));
      _log.fine('Could not resolve $normalized: $error');
      return normalized;
    }
  }

  @override
  Future<String?> pickFolder({String? initialDirectory}) async {
    try {
      return await getDirectoryPath(initialDirectory: initialDirectory);
    } on Exception catch (error, stack) {
      _log.warning('Folder dialog failed', error, stack);
      return null;
    }
  }

  static String _stripTrailingSlash(String path) =>
      path.length > 1 && path.endsWith('/')
      ? path.substring(0, path.length - 1)
      : path;
}
