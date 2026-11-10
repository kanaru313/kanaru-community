import 'dart:typed_data';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/data/local_files/audio_tree_walk.dart';
import 'package:kanaru/src/platform/data/local_files/linux_audio_catalog.dart';
import 'package:kanaru/src/platform/data/local_files/mount_points.dart';
import 'package:kanaru/src/platform/data/local_files/walk_isolate.dart';
import 'package:kanaru/src/platform/domain/local_audio_catalog.dart';

/// Walk entry that never returns, like a hung mount: only a kill ends it.
void _blockedWalk(WalkMessage message) {
  while (true) {
    sleep(const Duration(milliseconds: 20));
  }
}

void main() {
  late Directory tmp;
  late String root;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('kanaru-walk');
    root = tmp.resolveSymbolicLinksSync();
  });

  tearDown(() {
    // Restore modes a test removed, then delete.
    Process.runSync('chmod', ['-R', 'u+rwx', tmp.path]);
    tmp.deleteSync(recursive: true);
  });

  File touch(String rel, {String content = 'x'}) =>
      File('$root/$rel')
        ..createSync(recursive: true)
        ..writeAsStringSync(content);

  Set<String> names(Iterable<String> paths) =>
      paths.map((p) => p.substring(root.length + 1)).toSet();

  test('lists nested audio and sidecars with size and mtime', () {
    final song = touch('A/b/song.MP3', content: '12345');
    touch('A/b/song.lrc', content: 'ab');
    touch('notes.txt');
    final listing = walkAudioTree(WalkRequest(root: root));

    expect(listing.reachable, isTrue);
    expect(listing.audio, hasLength(1));
    expect(listing.audio.single.path, '$root/A/b/song.MP3');
    expect(listing.audio.single.sizeBytes, 5);
    expect(
      listing.audio.single.mtimeMs,
      song.statSync().modified.millisecondsSinceEpoch,
    );
    expect(listing.lyrics.single.path, '$root/A/b/song.lrc');
    expect(listing.lyrics.single.sizeBytes, 2);
  });

  test('a FIFO named like audio is not listed', () {
    final made = Process.runSync('mkfifo', ['$root/pipe.mp3']);
    if (made.exitCode != 0) {
      markTestSkipped('mkfifo not available');
      return;
    }
    touch('real.mp3');
    final listing = walkAudioTree(WalkRequest(root: root));
    expect(names(listing.audio.map((f) => f.path)), {'real.mp3'});
    expect(listing.unstattable, isEmpty);
  });

  test('a broken file link is unstattable and not listed', () {
    Link('$root/gone.mp3').createSync('$root/missing-target.mp3');
    final listing = walkAudioTree(WalkRequest(root: root));
    expect(listing.audio, isEmpty);
    expect(names(listing.unstattable), {'gone.mp3'});
  });

  test('a file link to a regular file is listed', () {
    touch('real/x.flac');
    Link('$root/alias.flac').createSync('$root/real/x.flac');
    final listing = walkAudioTree(WalkRequest(root: root));
    expect(names(listing.audio.map((f) => f.path)), {'real/x.flac', 'alias.flac'});
  });

  test('an empty sub-folder is just empty unless it is a mount point', () {
    Directory('$root/Empty').createSync();
    touch('Full/a.mp3');
    var listing = walkAudioTree(WalkRequest(root: root));
    expect(listing.emptyDirs, isEmpty);

    listing = walkAudioTree(
      WalkRequest(root: root, mountPoints: {'$root/Empty'}),
    );
    expect(names(listing.emptyDirs), {'Empty'});
  });

  test('mount points are parsed with octal escapes decoded', () {
    expect(
      parseMountPoints(
        '/dev/sda1 /media/u/My\\040Disk ext4 rw 0 0\nproc /proc proc rw 0 0\n',
      ),
      {'/media/u/My Disk', '/proc'},
    );
  });

  test('a folder link is not followed but counted', () {
    touch('Real/a.mp3');
    Link('$root/Loop').createSync(root);
    final listing = walkAudioTree(WalkRequest(root: root));
    expect(listing.skippedLinks, 1);
    expect(listing.audio, hasLength(1));
  });

  test('an unreadable folder is reported and the rest is listed', () {
    touch('Locked/a.mp3');
    touch('Open/b.mp3');
    Process.runSync('chmod', ['000', '$root/Locked']);
    var readable = true;
    try {
      Directory('$root/Locked').listSync();
    } on FileSystemException {
      readable = false;
    }
    if (readable) {
      markTestSkipped('running as a user that ignores modes');
      return;
    }
    final listing = walkAudioTree(WalkRequest(root: root));
    expect(names(listing.unreadableDirs), {'Locked'});
    expect(names(listing.audio.map((f) => f.path)), {'Open/b.mp3'});
  });

  test('a missing root is unreachable', () {
    final listing = walkAudioTree(WalkRequest(root: '$root/nope'));
    expect(listing.reachable, isFalse);
  });

  test('a non-UTF-8 name is counted and not listed', () {
    touch('Dir/ok.mp3');
    final bytes = [
      ...'$root/Dir/'.codeUnits,
      0xff, 0xfe, ...'.mp3'.codeUnits, //
    ];
    File.fromRawPath(Uint8List.fromList(bytes)).createSync();
    final listing = walkAudioTree(WalkRequest(root: root));
    expect(names(listing.audio.map((f) => f.path)), {'Dir/ok.mp3'});
    expect(listing.undecodableNames, 1);
    expect(listing.undecodableSampleDirs, ['$root/Dir']);
    expect(listing.unstattable, hasLength(1));
  });

  test('an excluded key skips its folder but not a longer sibling name', () {
    touch('A/x.mp3');
    touch('A B/x.mp3');
    touch('C/A/y.mp3');
    final listing = walkAudioTree(
      WalkRequest(root: root, excludedKeys: {'A'}),
    );
    expect(
      names(listing.audio.map((f) => f.path)),
      {'A B/x.mp3', 'C/A/y.mp3'},
    );
    expect(listing.excludedOut, 1);
  });

  test('a nested excluded key is matched on the relative path', () {
    touch('A/B/x.mp3');
    touch('A/C/y.mp3');
    final listing = walkAudioTree(
      WalkRequest(root: root, excludedKeys: {'A/B'}),
    );
    expect(names(listing.audio.map((f) => f.path)), {'A/C/y.mp3'});
  });

  test('dot-folders, junk folders and hidden files are skipped below the root',
      () {
    touch('.hidden/a.mp3');
    touch('@eaDir/b.mp3');
    touch('Ok/c.mp3');
    touch('Ok/._c.mp3');
    final listing = walkAudioTree(WalkRequest(root: root));
    expect(names(listing.audio.map((f) => f.path)), {'Ok/c.mp3'});
    expect(listing.skippedOut, 1);
  });

  test('the root itself may be a dot-folder', () {
    final hidden = Directory('$root/.music')..createSync();
    File('${hidden.path}/a.mp3').createSync();
    final listing = walkAudioTree(WalkRequest(root: hidden.path));
    expect(listing.audio, hasLength(1));
  });


  test('an empty root is reachable with nothing in it', () {
    final listing = walkAudioTree(WalkRequest(root: root));
    expect(listing.reachable, isTrue);
    expect(listing.audio, isEmpty);
    expect(listing.emptyDirs, isEmpty);
  });

  test('a root that is a file is unreachable', () {
    touch('plain.mp3');
    expect(walkAudioTree(WalkRequest(root: '$root/plain.mp3')).reachable, isFalse);
  });

  test('empty folders below a removable-media prefix are reported', () {
    Directory('$root/mnt/drive').createSync(recursive: true);
    final listing = walkAudioTree(
      WalkRequest(root: root, removableMediaPrefixes: ['$root/mnt']),
    );
    expect(names(listing.emptyDirs), {'mnt/drive'});
    final other = walkAudioTree(
      WalkRequest(root: root, removableMediaPrefixes: ['$root/other']),
    );
    expect(names(other.emptyDirs), isEmpty);
  });

  test('a non-UTF-8 folder name is counted, not queued or unreadable', () {
    touch('ok/a.mp3');
    final bytes = Uint8List.fromList([
      ...'$root/'.codeUnits, 0xff, 0xfe, //
    ]);
    Directory.fromRawPath(bytes).createSync();
    final bytes2 = Uint8List.fromList([
      ...'$root/'.codeUnits, 0xfe, 0xff, //
    ]);
    Directory.fromRawPath(bytes2).createSync(); // aliases to the same path
    final listing = walkAudioTree(WalkRequest(root: root));
    expect(listing.unreadableDirs, isEmpty);
    expect(listing.undecodableNames, 1);
    expect(listing.undecodableSampleDirs, [root]);
    expect(names(listing.audio.map((f) => f.path)), {'ok/a.mp3'});
  });

  test('hidden and junk folders do not count, hidden audio files do', () {
    Directory('$root/.stfolder').createSync();
    Directory('$root/lost+found').createSync();
    final plain = walkAudioTree(WalkRequest(root: root));
    expect(plain.skippedOut, 0);
    expect(plain.filteredOut, 0);
    touch('.hidden.lrc');
    expect(walkAudioTree(WalkRequest(root: root)).skippedOut, 1);
  });

  test('a folder link named like audio counts as a skipped link', () {
    touch('Real/a.mp3');
    Link('$root/x.mp3').createSync('$root/Real');
    final listing = walkAudioTree(WalkRequest(root: root));
    expect(listing.skippedLinks, 1);
    expect(listing.audio, hasLength(1));
  });

  group('walk isolate', () {
    test('runs the real walk off the calling isolate', () async {
      touch('a.mp3');
      final runner = WalkIsolateRunner();
      final listing = await runner.run(WalkRequest(root: root));
      expect(listing.audio, hasLength(1));
      expect(runner.spawned, 1);
    });

    test('a hung walk times out, is killed, and its root stays busy until exit',
        () async {
      final runner = WalkIsolateRunner(
        entry: _blockedWalk,
        timeout: const Duration(milliseconds: 200),
      );
      final first = await runner.run(WalkRequest(root: root));
      expect(first.reachable, isFalse);
      expect(first.unreachableReason, UnreachableReason.timedOut);
      expect(runner.isBusy(root), isTrue);

      final second = await runner.run(WalkRequest(root: root));
      expect(second.reachable, isFalse);
      expect(second.unreachableReason, UnreachableReason.busy);
      expect(runner.spawned, 1);

      for (var i = 0; i < 100 && runner.isBusy(root); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(runner.isBusy(root), isFalse);
    });

    test('the catalog lists through the runner', () async {
      touch('B/x.ogg');
      final catalog = LinuxAudioCatalog(mountPoints: () => const {});
      final listing = await catalog.listAudio(
        root: root,
        excludedKeys: const {},
      );
      expect(listing.audio, hasLength(1));
      expect(catalog.folderChoice, FolderChoice.systemDialog);
      expect(await catalog.audioFolders(), isEmpty);
      expect(await catalog.canonicalize('$root/B/'), '$root/B');
    });

    test('canonicalize resolves links before dot-dot segments', () async {
      Directory('$root/a/b').createSync(recursive: true);
      Link('$root/link').createSync('$root/a/b');
      final catalog = LinuxAudioCatalog(mountPoints: () => const {});
      expect(await catalog.canonicalize('$root/link/..'), '$root/a');
      expect(await catalog.canonicalize('$root/nope/../x/'), '$root/x');
    });
  });
}
