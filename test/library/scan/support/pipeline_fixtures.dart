import 'dart:async';
import 'dart:io';

import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/scan/native_tag_reader.dart';
import 'package:kanaru/src/library/data/scan/scan_pipeline.dart';
import 'package:kanaru/src/library/domain/scan/read_rules.dart';
import 'package:kanaru/src/library/domain/scan/scan_rules.dart';
import 'package:kanaru/src/library/domain/scan/tag_read.dart';
import 'package:kanaru/src/library/domain/scan_status.dart';
import 'package:kanaru/src/platform/domain/local_audio_catalog.dart';
import 'package:kanaru/src/platform/domain/media_permissions.dart';
import 'package:kanaru/src/storage/data/local_folder_source.dart';

import 'cover_fixtures.dart';
import 'scan_fixtures.dart';

/// A catalog that lists from a table of roots.
class MapCatalog implements LocalAudioCatalog {
  MapCatalog(this.listings);

  final Map<String, AudioListing> listings;
  final List<String> listed = [];
  final List<int> shortFilters = [];
  final List<bool> nomediaFlags = [];

  @override
  Future<AudioListing> listAudio({
    required String root,
    required Set<String> excludedKeys,
    int skipShorterThanMs = 0,
    bool respectNomedia = false,
  }) async {
    listed.add(root);
    shortFilters.add(skipShorterThanMs);
    nomediaFlags.add(respectNomedia);
    return listings[root] ?? const AudioListing.unreachable();
  }

  @override
  Future<AudioFoldersResult> audioFolders({int minDurationMs = 30000}) async =>
      const AudioFoldersListed([]);

  @override
  Future<MediaIndexRefresh> refreshMediaIndex({
    required List<String> volumeRoots,
    required List<String> folders,
  }) async => MediaIndexRefresh.done;
  @override
  Future<String?> suggestedMusicFolder() async => null;
  @override
  Future<String> canonicalize(String path) async => path;
  @override
  FolderChoice get folderChoice => FolderChoice.systemDialog;
  @override
  Future<String?> pickFolder({String? initialDirectory}) async => null;
}

AudioListing listingOf(String root, List<String> names) => AudioListing(
  audio: [
    for (final n in names)
      LocalAudioFile(path: '$root/$n', sizeBytes: 100, mtimeMs: 10),
  ],
);

class FixedPermissions implements MediaPermissions {
  FixedPermissions(this.state);

  MediaPermissionState state;

  @override
  Future<MediaPermissionState> status() async => state;
  @override
  Future<MediaPermissionState> requestAudio() async => state;
  @override
  Future<MediaPermissionState> requestImages() async => state;
  @override
  Future<bool> openSettings() async => false;
}

const grantedBoth = MediaPermissionState(
  audio: MediaPermissionStatus.granted,
  images: MediaPermissionStatus.granted,
);

/// A reader that never answers for paths under [hangUnder].
class SelectiveReader implements TagReader {
  SelectiveReader(this.inner);

  final FakeTagReader inner;
  final Set<String> hangUnder = {};
  final List<Completer<List<TagRead>>> hung = [];

  @override
  Future<List<TagRead>> read(List<String> paths) {
    if (paths.any((p) => hangUnder.any(p.startsWith))) {
      final c = Completer<List<TagRead>>();
      hung.add(c);
      return c.future;
    }
    return inner.read(paths);
  }
}

/// Collects the statuses a pass reports.
class StatusLog {
  final List<ScanRunning> seen = [];

  ScanHooks hooks({bool Function()? stop}) =>
      ScanHooks(onStatus: seen.add, shouldStop: stop ?? () => false);
}

ScanPipelineDeps pipelineDeps(
  AppDatabase db, {
  required MapCatalog catalog,
  required TagReader reader,
  required FakeCoverMaker maker,
  required Directory cache,
  MediaPermissionState permissions = grantedBoth,
  bool skipShort = true,
  ScanRules? scanRules,
  Duration tagTimeout = const Duration(seconds: 5),
  LibraryReadRules? readRules,
  Map<String, String> readRulesApplied = const {},
  Future<void> Function(String sourceUid, String fingerprint)?
  onReadRulesApplied,
}) => ScanPipelineDeps(
  db: db,
  source: LocalFolderSource(catalog, readMounts: () => {'/'}),
  permissions: FixedPermissions(permissions),
  reader: reader,
  maker: maker,
  cacheDir: cache.path,
  rules: scanRules ?? ScanRules(minDurationMs: skipShort ? 30000 : 0),
  now: () => scanNow,
  tagTimeout: tagTimeout,
  readRules: readRules,
  readRulesApplied: readRulesApplied,
  onReadRulesApplied: onReadRulesApplied,
);
