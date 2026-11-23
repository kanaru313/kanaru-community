import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/platform/data/document_picker_android.dart';
import 'package:kanaru/src/platform/domain/document_picker.dart';

const _ext = 'com.android.externalstorage.documents';
const _dl = 'com.android.providers.downloads.documents';
const _root = '/storage/emulated/0';
const _filter = DocumentFilter(label: 'M3U', extensions: ['m3u', 'm3u8']);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('documentPathOf', () {
    final cases = <(String, String, String?)>[
      (_ext, 'primary:Music/x.m3u8', '$_root/Music/x.m3u8'),
      (_ext, 'primary:', _root),
      (_ext, 'primary:/Music/x.m3u', '$_root/Music/x.m3u'),
      (_ext, 'ABCD-1234:x.m3u', '/storage/ABCD-1234/x.m3u'),
      (_ext, 'primary:Music/a:b.m3u', '$_root/Music/a:b.m3u'),
      (_ext, 'home:Doc/x.m3u', null),
      (_ext, 'primary:../etc/x', null),
      (_dl, 'raw:/storage/emulated/0/Download/x.m3u', '$_root/Download/x.m3u'),
      (_dl, 'msf:1234', null),
      (_dl, 'raw:relative/x', null),
      ('com.android.providers.media.documents', 'audio:55', null),
      ('com.example.cloud', 'primary:x', null),
      (_ext, 'nocolon', null),
    ];
    for (final (authority, id, expected) in cases) {
      test('$authority $id', () {
        expect(documentPathOf(authority, id, _root), expected);
      });
    }
  });

  group('channel', () {
    late MethodChannel channel;
    late AndroidDocumentPicker picker;
    late Future<Object?> Function(MethodCall) handler;

    setUp(() {
      channel = const MethodChannel('kanaru/documents');
      picker = AndroidDocumentPicker(
        channel: channel,
        primaryRoot: () async => _root,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (c) => handler(c));
    });
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('cancel returns null', () async {
      handler = (_) async => null;
      expect(await picker.openDocument(_filter), isNull);
      expect(await picker.createDocument(suggestedName: 'a.m3u8'), isNull);
    });

    test('open maps name and path', () async {
      handler = (c) async => {
        'uri': 'content://x/1',
        'name': 'Mix.M3U8',
        'authority': _ext,
        'documentId': 'primary:Music/Mix.M3U8',
      };
      final doc = await picker.openDocument(_filter);
      expect(doc!.name, 'Mix.M3U8');
      expect(doc.handle, 'content://x/1');
      expect(doc.localPath, '$_root/Music/Mix.M3U8');
    });

    test('unknown provider gives no path', () async {
      handler = (c) async => {
        'uri': 'content://x/1',
        'name': 'a.m3u',
        'authority': _dl,
        'documentId': 'msf:9',
      };
      expect((await picker.openDocument(_filter))!.localPath, isNull);
    });

    test('open does not enforce the filter, the caller does', () async {
      handler = (c) async => {
        'uri': 'content://x/2',
        'name': 'notes.txt',
        'authority': _ext,
        'documentId': 'primary:notes.txt',
      };
      final doc = await picker.openDocument(_filter);
      expect(doc!.name, 'notes.txt');
      expect(_filter.matchesName(doc.name), isFalse);
    });

    group('MIME types sent to the dialog', () {
      late List<String> sent;
      setUp(() {
        handler = (c) async {
          sent = List<String>.from((c.arguments as Map)['mimeTypes'] as List);
          return null;
        };
      });

      test('a playlist filter also gets playlist and text types', () async {
        await picker.openDocument(_filter);
        expect(sent, containsAll(['audio/x-mpegurl', 'text/plain']));
        expect(sent, contains('application/octet-stream'));
      });

      test(
        'another filter gets only its own types and the generic one',
        () async {
          await picker.openDocument(
            const DocumentFilter(
              label: 'Font',
              extensions: ['ttf', 'otf'],
              mimeTypes: ['font/ttf'],
            ),
          );
          expect(sent, ['font/ttf', 'application/octet-stream']);
          expect(sent, isNot(contains('text/plain')));
          expect(sent, isNot(contains('audio/x-mpegurl')));
        },
      );
    });

    test('create returns the provider name', () async {
      handler = (c) async => {
        'uri': 'content://x/3',
        'displayName': 'Mix (1).m3u8',
        'authority': _ext,
        'documentId': 'primary:Mix (1).m3u8',
      };
      final target = await picker.createDocument(suggestedName: 'Mix.m3u8');
      expect(target!.name, 'Mix (1).m3u8');
      expect(target.exists, isFalse);
    });

    test('dialog failures become DocumentPickerException', () async {
      Future<void> expectFailure(
        Object error,
        DocumentPickerFailure failure,
      ) async {
        handler = (_) async => throw error;
        await expectLater(
          picker.openDocument(_filter),
          throwsA(
            isA<DocumentPickerException>().having(
              (e) => e.failure,
              'failure',
              failure,
            ),
          ),
        );
        await expectLater(
          picker.createDocument(suggestedName: 'a.m3u8'),
          throwsA(isA<DocumentPickerException>()),
        );
      }

      await expectFailure(
        PlatformException(code: 'busy'),
        DocumentPickerFailure.busy,
      );
      await expectFailure(
        PlatformException(code: 'unavailable'),
        DocumentPickerFailure.unavailable,
      );
      await expectFailure(
        PlatformException(code: 'io'),
        DocumentPickerFailure.failed,
      );
      await expectFailure(
        MissingPluginException(),
        DocumentPickerFailure.unavailable,
      );
      // A later call works once the native side answers again.
      handler = (_) async => null;
      expect(await picker.openDocument(_filter), isNull);
    });

    test('read returns bytes, tooLarge and error mapping', () async {
      const doc = PickedDocument(name: 'a.m3u', handle: 'content://x/4');
      handler = (_) async => Uint8List.fromList([1, 2, 3]);
      expect(((await picker.read(doc, maxBytes: 3)) as Ok).value, hasLength(3));
      expect(
        ((await picker.read(doc, maxBytes: 2)) as Err).error,
        DocumentError.tooLarge,
      );
      handler = (_) async => throw PlatformException(code: 'too_large');
      expect(
        ((await picker.read(doc, maxBytes: 2)) as Err).error,
        DocumentError.tooLarge,
      );
      handler = (_) async => throw PlatformException(code: 'permission');
      expect(
        ((await picker.read(doc, maxBytes: 2)) as Err).error,
        DocumentError.unreadable,
      );
    });

    test('write maps platform errors, discard swallows them', () async {
      const target = SaveTarget(name: 'a.m3u8', handle: 'content://x/5');
      final calls = <String>[];
      handler = (c) async {
        calls.add(c.method);
        return null;
      };
      expect(await picker.write(target, Uint8List(1)), isA<Ok>());
      handler = (_) async => throw PlatformException(code: 'io');
      expect(
        ((await picker.write(target, Uint8List(1))) as Err).error,
        DocumentError.unwritable,
      );
      await picker.discard(target);
      expect(calls, ['write']);
    });
  });
}
