import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/scan/root_rules.dart' as lib;
import 'package:kanaru/src/storage/data/m3u/m3u_line_resolver.dart';
import 'package:kanaru/src/storage/domain/m3u/m3u_parse.dart';

M3uEntry e(String text, {int line = 1, bool tooLong = false}) =>
    M3uEntry(line: line, text: text, tooLong: tooLong);

Future<String> realCanon(String path) async {
  try {
    return await Directory(path).resolveSymbolicLinks();
  } on FileSystemException {
    return p.posix.normalize(path);
  }
}

void main() {
  late Directory tmp;
  late String root; // canonical temp dir

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('m3u_resolver');
    root = await tmp.resolveSymbolicLinks();
  });
  tearDown(() => tmp.delete(recursive: true));

  void touch(String rel) {
    final f = File('$root/$rel')..createSync(recursive: true);
    f.writeAsStringSync('x');
  }

  Future<List<M3uResolvedLine>> run(
    List<String> lines, {
    String? baseDir,
    List<String>? roots,
    Future<String> Function(String)? canonicalize,
    Future<FileSystemEntityType> Function(String)? stat,
    Duration timeout = const Duration(seconds: 5),
  }) => resolveM3uLines(
    [for (var i = 0; i < lines.length; i++) e(lines[i], line: i + 1)],
    baseDir: baseDir ?? root,
    liveRoots: roots ?? [root],
    canonicalize: canonicalize ?? realCanon,
    stat: stat ?? (path) => FileSystemEntity.type(path),
    statTimeout: timeout,
  );

  test('absolute and relative lines resolve; dot segments collapse', () async {
    touch('a/x.mp3');
    final r = await run(['$root/a/x.mp3', 'a/x.mp3', './a/./x.mp3']);
    expect(r.map((l) => l.path), everyElement('$root/a/x.mp3'));
    expect(r.map((l) => l.reason), everyElement(isNull));
  });

  test('upper-case extension and file: URI work', () async {
    touch('Up.MP3');
    touch('sp ace.flac');
    final r = await run(['Up.MP3', 'file://$root/sp%20ace.flac']);
    expect(r[0].path, '$root/Up.MP3');
    expect(r[1].path, '$root/sp ace.flac');
  });

  test('.. resolves physically through a symlinked folder', () async {
    touch('real/Albums/in.mp3');
    touch('a.mp3');
    Link('$root/Albums').createSync('$root/real/Albums');
    // Lexically Albums/../a.mp3 is root/a.mp3; physically root/real/a.mp3.
    touch('real/a.mp3');
    final r = await run(['Albums/../a.mp3']);
    expect(r.single.path, '$root/real/a.mp3');
  });

  test('symlinked file name is kept; broken link is notFound', () async {
    touch('t/target.mp3');
    Link('$root/alias.mp3').createSync('$root/t/target.mp3');
    Link('$root/broken.mp3').createSync('$root/nowhere.mp3');
    final r = await run(['alias.mp3', 'broken.mp3']);
    expect(r[0].path, '$root/alias.mp3');
    expect(r[1].reason, M3uUnresolvedReason.notFound);
  });

  test(
    'folder named x.mp3 is notFound; cover.jpg is notAudio, not statted',
    () async {
      Directory('$root/x.mp3').createSync();
      final statted = <String>[];
      final r = await run(
        ['x.mp3', 'cover.jpg', 'noext', 'dir/'],
        stat: (path) {
          statted.add(path);
          return FileSystemEntity.type(path);
        },
      );
      expect(r[0].reason, M3uUnresolvedReason.notFound);
      expect(
        r.skip(1).map((l) => l.reason),
        everyElement(M3uUnresolvedReason.notAudio),
      );
      expect(statted, [root, '$root/x.mp3']);
    },
  );

  test(
    'outside roots: existing is outsideFolders, missing is notFound',
    () async {
      touch('in/a.mp3');
      touch('out/b.mp3');
      final r = await run(
        ['in/a.mp3', 'out/b.mp3', 'out/missing.mp3', 'in/missing.mp3'],
        roots: ['$root/in/'],
      );
      expect(r[0].path, '$root/in/a.mp3');
      expect(r[1].reason, M3uUnresolvedReason.outsideFolders);
      expect(r[1].path, isNull);
      expect(r[2].reason, M3uUnresolvedReason.notFound);
      expect(r[2].candidatePath, isNull);
      expect(r[3].reason, M3uUnresolvedReason.notFound);
      expect(r[3].candidatePath, '$root/in/missing.mp3');
    },
  );

  test(
    'missing parent folder: candidate is lexical, throwing or not',
    () async {
      final plain = await run(['gone/../gone/a.mp3']);
      expect(plain.single.candidatePath, '$root/gone/a.mp3');
      final throwing = await run([
        'gone/../gone/a.mp3',
      ], canonicalize: (_) => throw const FileSystemException('x'));
      expect(throwing.single.reason, M3uUnresolvedReason.notFound);
      expect(throwing.single.candidatePath, '$root/gone/a.mp3');
    },
  );

  test('canonicalize runs once per folder', () async {
    touch('a/1.mp3');
    touch('a/2.mp3');
    touch('b/3.mp3');
    final calls = <String>[];
    final r = await run(
      ['a/1.mp3', 'a/2.mp3', 'a/1.mp3', 'b/3.mp3'],
      canonicalize: (p) {
        calls.add(p);
        return realCanon(p);
      },
    );
    expect(r.every((l) => l.path != null), isTrue);
    expect(calls.length, 2);
  });

  test('a hanging stat is notFound after the timeout', () async {
    touch('a.mp3');
    final r = await run(
      ['a.mp3'],
      stat: (_) => Completer<FileSystemEntityType>().future,
      timeout: const Duration(milliseconds: 30),
    );
    expect(r.single.reason, M3uUnresolvedReason.notFound);
    expect(r.single.candidatePath, '$root/a.mp3');
  });

  test('relative line without base folder', () async {
    final r = await resolveM3uLines(
      [e('a.mp3'), e('$root/none.mp3')],
      baseDir: null,
      liveRoots: [root],
      canonicalize: realCanon,
    );
    expect(r[0].reason, M3uUnresolvedReason.noBaseFolder);
    expect(r[1].reason, M3uUnresolvedReason.notFound);
  });

  test('backslash alt used only when the literal is absent', () async {
    touch('Rock/a.mp3');
    final alt = await run([r'Rock\a.mp3']);
    expect(alt.single.path, '$root/Rock/a.mp3');
    touch(r'Rock\a.mp3');
    final literal = await run([r'Rock\a.mp3']);
    expect(literal.single.path, '$root/Rock\\a.mp3');
    final none = await run([r'Pop\z.mp3']);
    expect(none.single.candidatePath, '$root/Pop/z.mp3');
  });

  test('rejected lines map to their reasons', () async {
    final r = await run([
      'http://x/a.mp3',
      'file://host/a.mp3',
      r'C:\a.mp3',
      'a\u0000.mp3',
    ]);
    expect(r.map((l) => l.reason), [
      M3uUnresolvedReason.uri,
      M3uUnresolvedReason.badFileUri,
      M3uUnresolvedReason.driveLetter,
      M3uUnresolvedReason.nul,
    ]);
    final long = await resolveM3uLines(
      [e('/a.mp3', tooLong: true)],
      baseDir: root,
      liveRoots: [root],
      canonicalize: realCanon,
    );
    expect(long.single.reason, M3uUnresolvedReason.tooLong);
  });

  test('order kept across batches with random stat delays', () async {
    final rnd = Random(7);
    final entries = [for (var i = 0; i < 100; i++) e('$root/f$i.mp3', line: i)];
    final r = await resolveM3uLines(
      entries,
      baseDir: root,
      liveRoots: [root],
      canonicalize: realCanon,
      stat: (_) async {
        await Future<void>.delayed(Duration(milliseconds: rnd.nextInt(8)));
        return FileSystemEntityType.file;
      },
    );
    expect(r.map((l) => l.entry.line), List.generate(100, (i) => i));
    expect(r.map((l) => l.path), [
      for (var i = 0; i < 100; i++) '$root/f$i.mp3',
    ]);
  });

  test('progress: (0,total) first, then per batch; empty input', () async {
    final seen = <(int, int)>[];
    await resolveM3uLines(
      [for (var i = 0; i < 70; i++) e('$root/f$i.mp3')],
      baseDir: root,
      liveRoots: [root],
      canonicalize: realCanon,
      stat: (_) async => FileSystemEntityType.notFound,
      onProgress: (d, t) => seen.add((d, t)),
    );
    expect(seen, [(0, 70), (32, 70), (64, 70), (70, 70)]);
    seen.clear();
    await resolveM3uLines(
      const [],
      baseDir: root,
      liveRoots: [root],
      canonicalize: realCanon,
      onProgress: (d, t) => seen.add((d, t)),
    );
    expect(seen, [(0, 0)]);
  });

  test('2000 real lines finish', () async {
    touch('a/x.mp3');
    final r = await run(List.filled(2000, 'a/x.mp3'));
    expect(r.every((l) => l.path == '$root/a/x.mp3'), isTrue);
  });

  test('50 000 lines finish with fake file system', () async {
    final r = await resolveM3uLines(
      [for (var i = 0; i < 50000; i++) e('/m/d${i % 50}/f$i.mp3')],
      baseDir: '/m',
      liveRoots: const ['/m'],
      canonicalize: (path) async => path,
      stat: (_) async => FileSystemEntityType.file,
    );
    expect(r.length, 50000);
    expect(r.every((l) => l.path != null), isTrue);
  });

  test('batch below 1 is an ArgumentError', () async {
    await expectLater(
      resolveM3uLines(
        [e('/a.mp3')],
        baseDir: root,
        liveRoots: [root],
        canonicalize: realCanon,
        batch: 0,
      ),
      throwsArgumentError,
    );
  });

  test('a canonicalize that never completes falls back to lexical', () async {
    touch('a/x.mp3');
    final r = await run(
      ['a/x.mp3'],
      canonicalize: (_) => Completer<String>().future,
      timeout: const Duration(milliseconds: 30),
    );
    expect(r.single.reason, M3uUnresolvedReason.notFound);
    expect(r.single.candidatePath, '$root/a/x.mp3');
  });

  test(
    'a folder that hangs is looked up once per batch, not per line',
    () async {
      var calls = 0;
      final sw = Stopwatch()..start();
      final r = await run(
        List.generate(100, (i) => 'd/f$i.mp3'),
        stat: (path) {
          if (path.endsWith('/d')) {
            return Future.value(FileSystemEntityType.directory);
          }
          calls++;
          return Completer<FileSystemEntityType>().future;
        },
        timeout: const Duration(milliseconds: 200),
      );
      expect(
        r.map((l) => l.reason),
        everyElement(M3uUnresolvedReason.notFound),
      );
      expect(r.map((l) => l.candidatePath), [
        for (var i = 0; i < 100; i++) '$root/d/f$i.mp3',
      ]);
      expect(calls, 32);
      expect(sw.elapsedMilliseconds, lessThan(2000));
    },
  );

  test('a missing folder behind a link maps into the canonical root', () async {
    Directory('$root/real').createSync();
    Link('$root/alias').createSync('$root/real');
    final r = await run(['alias/Old/a.mp3'], roots: ['$root/real']);
    expect(r.single.reason, M3uUnresolvedReason.notFound);
    expect(r.single.candidatePath, '$root/real/Old/a.mp3');
  });

  test('a stat that throws FileSystemException is notFound', () async {
    final r = await run([
      'a.mp3',
    ], stat: (_) => throw const FileSystemException('denied'));
    expect(r.single.reason, M3uUnresolvedReason.notFound);
  });

  test('a line over the length limit is tooLong', () async {
    final r = await run(['/${'a' * 5000}.mp3']);
    expect(r.single.reason, M3uUnresolvedReason.tooLong);
  });

  test('backslash alt outside the folders is outsideFolders', () async {
    touch('out/Rock/a.mp3');
    final r = await run(
      [r'Rock\a.mp3'],
      baseDir: '$root/out',
      roots: ['$root/in'],
    );
    expect(r.single.reason, M3uUnresolvedReason.outsideFolders);
  });

  test('a deep missing path stops the ancestor walk', () async {
    final deep = List.filled(100, 'd').join('/');
    var calls = 0;
    final r = await run(
      ['$deep/a.mp3'],
      stat: (path) {
        calls++;
        return FileSystemEntity.type(path);
      },
    );
    expect(r.single.reason, M3uUnresolvedReason.notFound);
    expect(r.single.candidatePath, '$root/$deep/a.mp3');
    expect(calls, lessThan(40));
  });

  test('a folder stat that times out is notFound with a candidate', () async {
    var fileStats = 0;
    final r = await run(
      ['d/a.mp3'],
      stat: (path) {
        if (path.endsWith('.mp3')) fileStats++;
        return Completer<FileSystemEntityType>().future;
      },
      timeout: const Duration(milliseconds: 30),
    );
    expect(r.single.reason, M3uUnresolvedReason.notFound);
    expect(r.single.candidatePath, '$root/d/a.mp3');
    expect(fileStats, 0);
  });

  test('canonicalize: an Exception falls back, an Error propagates', () async {
    touch('a/x.mp3');
    final r = await run(
      ['a/x.mp3'],
      canonicalize: (_) => throw const FormatException('odd'),
    );
    expect(r.single.path, '$root/a/x.mp3');
    await expectLater(
      run(['a/x.mp3'], canonicalize: (_) => throw StateError('bug')),
      throwsStateError,
    );
  });

  test('root prefix rule equals the library rule', () {
    const roots = ['/', '/m', '/m/Live', '/a b'];
    const paths = [
      '/',
      '/m',
      '/m/Live',
      '/m/Live Albums',
      '/m/Live/x',
      '/mm',
      '/a b/c',
      '/z',
    ];
    for (final inner in paths) {
      for (final outer in roots) {
        expect(
          isSameOrInsideRoot(inner, outer),
          lib.isSameOrInside(inner, outer),
          reason: '$inner in $outer',
        );
      }
    }
  });
}
