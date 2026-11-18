import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/platform/data/document_picker_linux.dart';
import 'package:kanaru/src/platform/domain/document_picker.dart';

DocumentError _err(Result<Object?, DocumentError> r) => (r as Err).error;

void main() {
  late Directory dir;
  late LinuxDocumentPicker picker;
  String? chosen;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('doc_picker');
    chosen = null;
    picker = LinuxDocumentPicker(
      open: (_) async => chosen,
      save: (_, _) async => chosen,
    );
  });
  tearDown(() {
    // Restore write permission so cleanup works.
    Process.runSync('chmod', ['-R', 'u+rwx', dir.path]);
    dir.deleteSync(recursive: true);
  });

  PickedDocument doc(String path) =>
      PickedDocument(name: 'x', handle: path, localPath: path);

  group('dialogs', () {
    test('cancel returns null', () async {
      expect(
        await picker.openDocument(
          const DocumentFilter(label: 'M3U', extensions: ['m3u']),
        ),
        isNull,
      );
      expect(await picker.createDocument(suggestedName: 'a.m3u8'), isNull);
    });

    test('open and create map name and exists', () async {
      final file = File('${dir.path}/Mix.m3u8')..writeAsStringSync('x');
      chosen = file.path;
      final opened = await picker.openDocument(
        const DocumentFilter(label: 'M3U', extensions: ['m3u8']),
      );
      expect(opened!.name, 'Mix.m3u8');
      expect(opened.localPath, file.path);
      final target = await picker.createDocument(suggestedName: 'Mix.m3u8');
      expect(target!.exists, isTrue);
      chosen = '${dir.path}/new.m3u8';
      expect(
        (await picker.createDocument(suggestedName: 'n'))!.exists,
        isFalse,
      );
    });

    test('appends the first extension and checks the final path', () async {
      const filter = DocumentFilter(label: 'M3U', extensions: ['m3u8', 'm3u']);
      File('${dir.path}/Mix.m3u8').writeAsStringSync('x');
      chosen = '${dir.path}/Mix';
      var target = await picker.createDocument(
        suggestedName: 'Mix',
        filter: filter,
      );
      expect(target!.name, 'Mix.m3u8');
      expect(target.handle, '${dir.path}/Mix.m3u8');
      expect(target.localPath, target.handle);
      expect(target.exists, isTrue);
      chosen = '${dir.path}/Other.M3U';
      target = await picker.createDocument(suggestedName: 'x', filter: filter);
      expect(target!.name, 'Other.M3U');
      expect(target.exists, isFalse);
      chosen = '${dir.path}/Dotted.';
      target = await picker.createDocument(suggestedName: 'x', filter: filter);
      expect(target!.name, 'Dotted.m3u8');
      chosen = '${dir.path}/Plain';
      target = await picker.createDocument(suggestedName: 'x');
      expect(target!.name, 'Plain');
    });

    test('dialog platform errors become DocumentPickerException', () async {
      final failing = LinuxDocumentPicker(
        open: (_) async => throw PlatformException(code: 'x'),
        save: (_, _) async => throw MissingPluginException(),
      );
      await expectLater(
        failing.openDocument(
          const DocumentFilter(label: 'M3U', extensions: ['m3u']),
        ),
        throwsA(isA<DocumentPickerException>()),
      );
      await expectLater(
        failing.createDocument(suggestedName: 'a'),
        throwsA(isA<DocumentPickerException>()),
      );
    });

    test('a dangling symlink counts as existing', () async {
      final link = Link('${dir.path}/dangling')..createSync('${dir.path}/none');
      chosen = link.path;
      expect((await picker.createDocument(suggestedName: 'n'))!.exists, isTrue);
    });
  });

  group('read', () {
    test('exact cap ok, cap+1 tooLarge, empty ok', () async {
      final f = File('${dir.path}/a.m3u')
        ..writeAsBytesSync(Uint8List(2 * 1024 * 1024 + 5));
      final cap = 2 * 1024 * 1024 + 5;
      expect(
        ((await picker.read(doc(f.path), maxBytes: cap)) as Ok).value,
        hasLength(cap),
      );
      expect(
        _err(await picker.read(doc(f.path), maxBytes: cap - 1)),
        DocumentError.tooLarge,
      );
      final empty = File('${dir.path}/e.m3u')..writeAsBytesSync([]);
      expect(
        ((await picker.read(doc(empty.path), maxBytes: 5)) as Ok).value,
        isEmpty,
      );
    });

    test('folder and missing are notAFile', () async {
      expect(
        _err(await picker.read(doc(dir.path), maxBytes: 5)),
        DocumentError.notAFile,
      );
      expect(
        _err(await picker.read(doc('${dir.path}/none'), maxBytes: 5)),
        DocumentError.notAFile,
      );
    });

    test('a FIFO is never opened', () async {
      final fifo = '${dir.path}/pipe';
      final r = Process.runSync('mkfifo', [fifo]);
      expect(r.exitCode, 0);
      final result = await picker
          .read(doc(fifo), maxBytes: 5)
          .timeout(const Duration(seconds: 5));
      expect(_err(result), DocumentError.notAFile);
    });

    test('unreadable file maps to unreadable', () async {
      final f = File('${dir.path}/p.m3u')..writeAsStringSync('x');
      Process.runSync('chmod', ['000', f.path]);
      if (Process.runSync('id', ['-u']).stdout.toString().trim() == '0') return;
      expect(
        _err(await picker.read(doc(f.path), maxBytes: 5)),
        DocumentError.unreadable,
      );
    });
  });

  group('write', () {
    SaveTarget target(String path) =>
        SaveTarget(name: 'x', handle: path, localPath: path);

    test('replaces content and leaves no temp file', () async {
      final f = File('${dir.path}/a.m3u8')..writeAsStringSync('old old old');
      final result = await picker.write(
        target(f.path),
        Uint8List.fromList([65, 66]),
      );
      expect(result, isA<Ok>());
      expect(f.readAsStringSync(), 'AB');
      expect(dir.listSync().map((e) => e.path), [f.path]);
    });

    test('creates a missing target', () async {
      final path = '${dir.path}/new.m3u8';
      await picker.write(target(path), Uint8List.fromList([65]));
      expect(File(path).readAsStringSync(), 'A');
    });

    test('through a symlink keeps the link', () async {
      final real = File('${dir.path}/real.m3u8')..writeAsStringSync('old');
      final link = Link('${dir.path}/link.m3u8')..createSync(real.path);
      await picker.write(target(link.path), Uint8List.fromList([65]));
      expect(FileSystemEntity.isLinkSync(link.path), isTrue);
      expect(real.readAsStringSync(), 'A');
    });

    test('an existing <target>.tmp user file survives', () async {
      final f = File('${dir.path}/a.m3u8')..writeAsStringSync('old');
      final user = File('${f.path}.tmp')..writeAsStringSync('mine');
      await picker.write(target(f.path), Uint8List.fromList([65]));
      expect(user.readAsStringSync(), 'mine');
      expect(f.readAsStringSync(), 'A');
    });

    test('a planted <target>.<pid>.tmp file survives, write retries', () async {
      final f = File('${dir.path}/a.m3u8')..writeAsStringSync('old');
      final planted = File('${f.path}.$pid.tmp')..writeAsStringSync('mine');
      await picker.write(target(f.path), Uint8List.fromList([65]));
      expect(planted.readAsStringSync(), 'mine');
      expect(f.readAsStringSync(), 'A');
      expect(dir.listSync(), hasLength(2));
    });

    test('a planted <target>.<pid>.tmp symlink is not followed', () async {
      final f = File('${dir.path}/a.m3u8')..writeAsStringSync('old');
      final victim = File('${dir.path}/victim')..writeAsStringSync('keep');
      final link = Link('${f.path}.$pid.tmp')..createSync(victim.path);
      await picker.write(target(f.path), Uint8List.fromList([65]));
      expect(victim.readAsStringSync(), 'keep');
      expect(FileSystemEntity.isLinkSync(link.path), isTrue);
      expect(f.readAsStringSync(), 'A');
    });

    test('a .tmp symlink is not followed', () async {
      final f = File('${dir.path}/a.m3u8')..writeAsStringSync('old');
      final victim = File('${dir.path}/victim')..writeAsStringSync('keep');
      Link('${f.path}.tmp').createSync(victim.path);
      await picker.write(target(f.path), Uint8List.fromList([65]));
      expect(victim.readAsStringSync(), 'keep');
      expect(f.readAsStringSync(), 'A');
    });

    test('a read-only folder fails without a temp file', () async {
      if (Process.runSync('id', ['-u']).stdout.toString().trim() == '0') return;
      final sub = Directory('${dir.path}/ro')..createSync();
      final f = File('${sub.path}/a.m3u8')..writeAsStringSync('old');
      Process.runSync('chmod', ['555', sub.path]);
      final result = await picker.write(
        target(f.path),
        Uint8List.fromList([65]),
      );
      expect(_err(result), DocumentError.unwritable);
      expect(f.readAsStringSync(), 'old');
      expect(sub.listSync(), hasLength(1));
    });

    test('discard is a no-op', () async {
      await picker.discard(target('${dir.path}/none'));
    });
  });
}
