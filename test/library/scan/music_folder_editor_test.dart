import 'package:drift/drift.dart'
    show ApplyInterceptor, QueryExecutor, QueryInterceptor;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/folder_exclusion_repository.dart';
import 'package:kanaru/src/library/data/scan/scan_folders.dart';
import 'package:kanaru/src/library/domain/music_folder.dart';
import 'package:kanaru/src/library/domain/scan_status.dart';
import 'package:kanaru/src/library/state/scan/music_folder_editor.dart';
import 'package:kanaru/src/library/state/scan/music_folder_editor_defaults.dart';
import 'package:kanaru/src/library/state/scan/music_folder_editor_lists.dart';
import 'package:kanaru/src/platform/domain/local_audio_catalog.dart';
import 'package:kanaru/src/platform/domain/media_permissions.dart';
import 'package:kanaru/src/platform/domain/storage_volumes.dart';

import '../../database/support/test_db.dart';
import 'support/pipeline_fixtures.dart';

class _Catalog implements LocalAudioCatalog {
  _Catalog({this.android = false});

  final bool android;
  String? suggestion;
  List<AudioFolderSummary> folders = [];

  /// Path prefix to replace, like a symlinked `/home`.
  final Map<String, String> links = {};
  final List<String> canonicalized = [];

  @override
  Future<String> canonicalize(String path) async {
    canonicalized.add(path);
    for (final e in links.entries) {
      if (path == e.key || path.startsWith('${e.key}/')) {
        return e.value + path.substring(e.key.length);
      }
    }
    return path;
  }

  @override
  Future<AudioListing> listAudio({
    required String root,
    required Set<String> excludedKeys,
    int skipShorterThanMs = 0,
  }) async => const AudioListing();
  @override
  Future<List<AudioFolderSummary>> audioFolders() async => folders;
  @override
  Future<String?> suggestedMusicFolder() async => suggestion;
  @override
  FolderChoice get folderChoice =>
      android ? FolderChoice.mediaStoreSheet : FolderChoice.systemDialog;
  @override
  Future<String?> pickFolder({String? initialDirectory}) async => null;
}

class _Volumes implements StorageVolumes {
  @override
  Future<List<StorageVolume>> list() async => const [];
  @override
  StorageVolume volumeOf(String path) => path.startsWith('/storage/emulated/0')
      ? const StorageVolume(
          root: '/storage/emulated/0',
          kind: StorageVolumeKind.internal,
        )
      : otherVolume;
}

class _Scanner implements LibraryScanCommands {
  int rescans = 0;
  @override
  Future<void> rescan({bool full = false}) async => rescans++;
}

AudioFolderSummary _f(String path, int n) =>
    AudioFolderSummary(path: path, audioCount: n);

void main() {
  late AppDatabase db;
  late _Catalog catalog;
  late FixedPermissions permissions;
  late MusicFolderEditor editor;
  late bool applied;
  late int changes;
  late Set<String> directories;

  void build({bool android = false}) {
    catalog = _Catalog(android: android);
    permissions = FixedPermissions(
      android ? grantedBoth : const MediaPermissionState.notApplicable(),
    );
    applied = false;
    changes = 0;
    directories = {'/music', '/home/u/Music', '/var/home/u/Music'};
    editor = MusicFolderEditor(
      db: db,
      catalog: catalog,
      permissions: permissions,
      volumes: _Volumes(),
      exclusions: FolderExclusionRepository(db, _Scanner()),
      defaultsApplied: () => applied,
      markDefaultsApplied: () async => applied = true,
      onChanged: () => changes++,
      now: () => 1000,
      isDirectory: (p) async => directories.contains(p),
    );
  }

  setUp(() {
    db = openTestDb();
    addTearDown(db.close);
    build();
  });

  Future<List<String>> roots() async => [
    for (final f in await liveScanFolders(db)) f.root,
  ];

  Future<MusicFolder> chosen(String root) async {
    final f = (await liveScanFolders(db)).firstWhere((f) => f.root == root);
    return MusicFolder(
      sourceId: f.sourceId,
      sourceUid: f.sourceUid,
      root: f.root,
      volume: otherVolume,
      name: 'm',
    );
  }

  group('addFolder', () {
    test('adds a folder and tells the listeners', () async {
      final r = await editor.addFolder('/music/');
      expect(r, isA<FolderAdded>());
      expect(await roots(), ['/music']);
      expect(changes, 1);
    });

    test('root is too broad', () async {
      expect(await editor.addFolder('/'), isA<FolderTooBroad>());
      expect(await editor.addFolder(''), isA<FolderTooBroad>());
      expect(await roots(), isEmpty);
    });

    test('the same root twice is already chosen, one row', () async {
      await editor.addFolder('/music');
      expect(await editor.addFolder('/music/'), isA<FolderAlreadyChosen>());
      expect(await roots(), ['/music']);
    });

    test('nested both ways is refused with the root named', () async {
      directories.addAll(['/music/rock', '/']);
      await editor.addFolder('/music');
      final inside = await editor.addFolder('/music/rock');
      expect(inside, isA<FolderInsideExisting>());
      expect((inside as FolderInsideExisting).root, '/music');

      directories.add('/music2');
      expect(await editor.addFolder('/music2'), isA<FolderAdded>());
      directories.addAll(['/a', '/a/b']);
      await editor.addFolder('/a/b');
      final outer = await editor.addFolder('/a');
      expect(outer, isA<FolderContainsExisting>());
      expect((outer as FolderContainsExisting).root, '/a/b');
    });

    test('a symlinked path is canonicalised before the check', () async {
      catalog.links['/home'] = '/var/home';
      await editor.addFolder('/var/home/u/Music');
      final r = await editor.addFolder('/home/u/Music');
      expect(r, isA<FolderAlreadyChosen>());
      expect(await roots(), ['/var/home/u/Music']);
    });

    test('a path that is not a folder is refused', () async {
      expect(await editor.addFolder('/nope'), isA<FolderNotADirectory>());
    });

    test('a catalog path is only normalised', () async {
      await editor.addFolder('/storage/emulated/0/Music/', fromCatalog: true);
      expect(catalog.canonicalized, isEmpty);
      expect(await roots(), ['/storage/emulated/0/Music']);
    });

    test('a failed write is a value, not an exception', () async {
      final broken = AppDatabase(
        NativeDatabase.memory(setup: configureConnection)
            .interceptWith(_RefusingInserts()),
      );
      addTearDown(broken.close);
      build();
      editor = MusicFolderEditor(
        db: broken,
        catalog: catalog,
        permissions: permissions,
        volumes: _Volumes(),
        exclusions: FolderExclusionRepository(broken, _Scanner()),
        defaultsApplied: () => false,
        markDefaultsApplied: () async {},
        onChanged: () => changes++,
        isDirectory: (_) async => true,
      );
      expect(await editor.addFolder('/music'), isA<FolderWriteFailed>());
      expect(changes, 0);
    });

    test('a removed folder comes back as revived', () async {
      await editor.addFolder('/music');
      expect(await editor.removeFolder(await chosen('/music')), isTrue);
      expect(await roots(), isEmpty);
      final r = await editor.addFolder('/music');
      expect(r, isA<FolderAdded>());
      expect((r as FolderAdded).revived, isTrue);
    });
  });

  group('excludeFolder', () {
    test('excludes a sub-folder by relative key and stores the path', () async {
      await editor.addFolder('/music');
      final f = await chosen('/music');
      final r = await editor.excludeFolder(f, '/music/Ringtones/');
      expect(r, ExcludeFolderResult.excluded);
      expect(await excludedFolderKeys(db, f.sourceId), ['Ringtones']);
      final row = await db
          .customSelect('SELECT display_path FROM excluded_folders')
          .getSingle();
      expect(row.read<String>('display_path'), '/music/Ringtones');
    });

    test('outside the folder, or the folder itself, is refused', () async {
      await editor.addFolder('/music');
      final f = await chosen('/music');
      expect(
        await editor.excludeFolder(f, '/elsewhere/x'),
        ExcludeFolderResult.outsideFolder,
      );
      expect(
        await editor.excludeFolder(f, '/music'),
        ExcludeFolderResult.outsideFolder,
      );
      expect(
        await editor.excludeFolder(f, '/musical/x'),
        ExcludeFolderResult.outsideFolder,
      );
    });

    test('inside an excluded folder is already excluded', () async {
      await editor.addFolder('/music');
      final f = await chosen('/music');
      await editor.excludeFolder(f, '/music/a');
      expect(
        await editor.excludeFolder(f, '/music/a/b'),
        ExcludeFolderResult.alreadyExcluded,
      );
    });

    test('a path picked through a symlinked parent is accepted', () async {
      catalog.links['/home'] = '/var/home';
      await editor.addFolder('/var/home/u/Music');
      final f = await chosen('/var/home/u/Music');
      final r = await editor.excludeFolder(f, '/home/u/Music/Podcasts');
      expect(r, ExcludeFolderResult.excluded);
      expect(await excludedFolderKeys(db, f.sourceId), ['Podcasts']);
      // The leaf is not resolved, only its parent.
      expect(catalog.canonicalized.last, '/home/u/Music');
    });

    test('removing a folder removes its exclusions', () async {
      await editor.addFolder('/music');
      final f = await chosen('/music');
      await editor.excludeFolder(f, '/music/a');
      await editor.removeFolder(f);
      expect(await excludedFolderKeys(db, f.sourceId), isEmpty);
    });

    test('include undoes it', () async {
      await editor.addFolder('/music');
      final f = await chosen('/music');
      await editor.excludeFolder(f, '/music/a');
      expect(await editor.includeFolder(f, 'a'), isTrue);
      expect(await excludedFolderKeys(db, f.sourceId), isEmpty);
    });
  });

  group('first-run defaults', () {
    test('Linux adds the system music folder once', () async {
      catalog.suggestion = '/music';
      await editor.applyFirstRunDefaults();
      expect(await roots(), ['/music']);
      expect(applied, isTrue);

      await editor.removeFolder(await chosen('/music'));
      await editor.applyFirstRunDefaults();
      expect(await roots(), isEmpty);
    });

    test('nothing is added when a folder is already chosen', () async {
      await editor.addFolder('/music');
      catalog.suggestion = '/home/u/Music';
      await editor.applyFirstRunDefaults();
      expect(await roots(), ['/music']);
      expect(applied, isTrue);
    });

    test('no suggestion adds nothing', () async {
      await editor.applyFirstRunDefaults();
      expect(await roots(), isEmpty);
    });

    test('Android waits for the audio permission', () async {
      build(android: true);
      catalog.suggestion = '/storage/emulated/0/Music';
      permissions.state = const MediaPermissionState(
        audio: MediaPermissionStatus.denied,
        images: MediaPermissionStatus.denied,
      );
      await editor.applyFirstRunDefaults();
      expect(await roots(), isEmpty);
      expect(applied, isFalse);

      permissions.state = grantedBoth;
      await editor.applyFirstRunDefaults();
      expect(await roots(), ['/storage/emulated/0/Music']);
    });

    test('Android excludes ringtone folders that have audio', () async {
      build(android: true);
      const music = '/storage/emulated/0/Music';
      catalog
        ..suggestion = music
        ..folders = [
          _f(music, 10),
          _f('$music/Ringtones', 3),
          _f('$music/notifications', 2),
          _f('$music/Rock', 4),
          _f('$music/Rock/Alarms', 1),
          _f('/storage/emulated/0/Alarms', 5),
        ];
      await editor.applyFirstRunDefaults();
      final f = await chosen(music);
      expect((await excludedFolderKeys(db, f.sourceId)).toSet(), {
        'Ringtones',
        'notifications',
      });
    });

    test('the flag is set before anything is written', () async {
      catalog.suggestion = '/music';
      var flagAtFirstWrite = false;
      editor = MusicFolderEditor(
        db: db,
        catalog: catalog,
        permissions: permissions,
        volumes: _Volumes(),
        exclusions: FolderExclusionRepository(db, _Scanner()),
        defaultsApplied: () => applied,
        markDefaultsApplied: () async => applied = true,
        onChanged: () => flagAtFirstWrite = applied,
        isDirectory: (_) async => true,
      );
      await editor.applyFirstRunDefaults();
      expect(flagAtFirstWrite, isTrue);
    });
  });

  group('android candidates and estimate', () {
    setUp(() {
      build(android: true);
      catalog.folders = [
        _f('/storage/emulated/0/Music', 10),
        _f('/storage/emulated/0/Music/Rock', 4),
        _f('/storage/emulated/0/Music/Ringtones', 3),
        _f('/storage/emulated/0/Podcasts', 7),
        _f('/storage/emulated/0/Podcasts/Tech', 2),
        _f('/storage/emulated/0', 1),
      ];
    });

    test(
      'candidates leave out chosen, nested and containing folders',
      () async {
        await editor.addFolder('/storage/emulated/0/Music', fromCatalog: true);
        final paths = [for (final c in await editor.folderCandidates()) c.path];
        expect(paths, [
          '/storage/emulated/0/Podcasts',
          '/storage/emulated/0/Podcasts/Tech',
        ]);
      },
    );

    test('exclusion candidates are strictly inside a chosen folder, not '
        'excluded', () async {
      await editor.addFolder('/storage/emulated/0/Music', fromCatalog: true);
      final f = await chosen('/storage/emulated/0/Music');
      await editor.excludeFolder(
        f,
        '/storage/emulated/0/Music/Ringtones',
        fromCatalog: true,
      );
      final paths = [
        for (final c in await editor.exclusionCandidates()) c.path,
      ];
      expect(paths, ['/storage/emulated/0/Music/Rock']);
    });

    test('a folder whose music is only in sub-folders is offered, with the '
        'subtree count', () async {
      catalog.folders = [
        _f('/storage/emulated/0/Music/A', 1),
        _f('/storage/emulated/0/Music/B/Live', 1),
      ];
      final offered = {
        for (final c in await editor.folderCandidates()) c.path: c.audioCount,
      };
      expect(offered, {
        '/storage/emulated/0/Music': 2,
        '/storage/emulated/0/Music/A': 1,
        '/storage/emulated/0/Music/B': 1,
        '/storage/emulated/0/Music/B/Live': 1,
      });
      // The volume itself is never offered.
      expect(offered.containsKey('/storage/emulated/0'), isFalse);
    });

    test('exclusion candidates include parents of listed folders, inside a '
        'chosen folder only', () async {
      catalog.folders = [
        _f('/storage/emulated/0/Music/Artist/Album1', 3),
        _f('/storage/emulated/0/Music/Artist/Album2', 2),
        _f('/storage/emulated/0/Download', 5),
      ];
      await editor.addFolder('/storage/emulated/0/Music', fromCatalog: true);
      final offered = {
        for (final c in await editor.exclusionCandidates())
          c.path: c.audioCount,
      };
      expect(offered['/storage/emulated/0/Music/Artist'], 5);
      expect(
        offered.keys.every((p) => p.startsWith('/storage/emulated/0/Music/')),
        isTrue,
      );
    });

    test('ancestors of 5000 folders are counted in one pass', () {
      final raw = [
        for (var a = 0; a < 250; a++)
          for (var b = 0; b < 20; b++)
            _f('/storage/emulated/0/Music/Artist$a/Album$b', 2),
      ];
      final watch = Stopwatch()..start();
      final out = withAncestors(raw, _Volumes());
      watch.stop();
      final byPath = {for (final f in out) f.path: f.audioCount};
      expect(out, hasLength(5000 + 250 + 1));
      expect(byPath['/storage/emulated/0/Music'], 10000);
      expect(byPath['/storage/emulated/0/Music/Artist7'], 40);
      // Generous: the old pairwise version took seconds.
      expect(watch.elapsedMilliseconds, lessThan(500));
    });

    test('the estimate subtracts excluded subtrees', () async {
      expect(await editor.estimatedTrackCount(), 0);
      await editor.addFolder('/storage/emulated/0/Music', fromCatalog: true);
      expect(await editor.estimatedTrackCount(), 17);
      final f = await chosen('/storage/emulated/0/Music');
      await editor.excludeFolder(
        f,
        '/storage/emulated/0/Music/Ringtones',
        fromCatalog: true,
      );
      expect(await editor.estimatedTrackCount(), 14);
    });

    test('the estimate is unknown on Linux', () async {
      build();
      expect(await editor.estimatedTrackCount(), isNull);
    });
  });
}

/// Refuses every insert, like a full disk.
class _RefusingInserts extends QueryInterceptor {
  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => throw StateError('disk full');
}
