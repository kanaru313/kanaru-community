import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/m3u/m3u_import_service.dart';
import 'package:kanaru/src/library/data/m3u/m3u_scan_rules.dart';
import 'package:kanaru/src/library/data/playlists/playlist_repository.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_store.dart';
import 'package:kanaru/src/platform/domain/document_picker.dart';

import '../../../database/support/test_db.dart';
import 'm3u_fixtures.dart';

/// Resolves links of an existing folder, like the app's `canonicalize`.
Future<String> realPath(String path) async =>
    FileSystemEntity.isDirectorySync(path)
    ? Directory(path).resolveSymbolicLinksSync()
    : path;

/// A temp tree with a music folder (a live source), an in-memory database,
/// a fake picker and a real repository.
class M3uEnv {
  M3uEnv._(this.tmp, this.db, this.source);

  /// Canonical temp root; holds `music/` and `lists/`.
  final String tmp;
  final AppDatabase db;
  final int source;
  final picker = FakePicker();
  final scans = FakeScans();
  late final repo = PlaylistRepository(db);

  String get music => '$tmp/music';

  static Future<M3uEnv> open() async {
    final dir = Directory.systemTemp.createTempSync('m3u_env');
    addTearDown(() => dir.deleteSync(recursive: true));
    final tmp = dir.resolveSymbolicLinksSync();
    Directory('$tmp/music').createSync();
    Directory('$tmp/lists').createSync();
    final db = openTestDb();
    addTearDown(db.close);
    final source = await addSource(db, uid: 'src-music', root: '$tmp/music');
    await addMount(db, source, root: '$tmp/music');
    return M3uEnv._(tmp, db, source);
  }

  /// Creates an empty audio file at [rel] under the music folder.
  String file(String rel, {String? under}) {
    final f = File('${under ?? music}/$rel')..createSync(recursive: true);
    return f.path;
  }

  /// Puts [text] in the picker as a list file in `lists/`.
  PickedDocument list(String text, {String name = 'list.m3u'}) {
    final path = '$tmp/lists/$name';
    picker.put(path, text);
    return PickedDocument(name: name, handle: path, localPath: path);
  }

  M3uImportService service({
    PlaylistStore? store,
    ShortTrackRule short = const ShortTrackRule.off(),
    bool androidStorage = false,
  }) => M3uImportService(
    db,
    store ?? repo,
    picker,
    realPath,
    scans,
    short,
    androidStorage: androidStorage,
  );
}
