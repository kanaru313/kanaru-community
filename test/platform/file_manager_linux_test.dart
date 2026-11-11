import 'dart:async';
import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/platform/data/file_manager_linux.dart';
import 'package:kanaru/src/platform/domain/file_manager.dart';

class _FakeBus implements FileManagerBus {
  _FakeBus(this.log, {this.failure});

  final List<String> log;
  final Object? failure;

  @override
  Future<void> call(String method, List<String> uris) async {
    log.add('$method ${uris.join(',')}');
    if (failure != null) throw failure!;
  }

  @override
  Future<void> close() async => log.add('close');
}

FileManagerError? _error(Result<void, FileManagerError> r) =>
    r is Err<void, FileManagerError> ? r.error : null;

void main() {
  late Directory tmp;
  late File file;
  late List<String> bus;
  late List<List<String>> started;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('fm_test');
    file = File('${tmp.path}/a song #1.mp3')..writeAsStringSync('x');
    bus = [];
    started = [];
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  LinuxFileManager manager({Object? failure, Object? startFailure}) =>
      LinuxFileManager(
        bus: () => _FakeBus(bus, failure: failure),
        start: (exe, args) async {
          if (startFailure != null) throw startFailure;
          started.add([exe, ...args]);
        },
      );

  test('a file is selected with ShowItems and the client is closed', () async {
    final result = await manager().reveal(file.path);
    expect(result.isOk, isTrue);
    expect(bus, ['ShowItems ${Uri.file(file.path)}', 'close']);
    expect(bus.first, contains('%23'), reason: 'uri is percent-encoded');
    expect(started, isEmpty);
  });

  test('a directory is opened with ShowFolders', () async {
    final result = await manager().reveal(tmp.path);
    expect(result.isOk, isTrue);
    expect(bus.first, startsWith('ShowFolders '));
    expect(bus.last, 'close');
  });

  test('a bus error falls back to xdg-open on the parent of a file', () async {
    final result = await manager(failure: StateError('no bus'))
        .reveal(file.path);
    expect(result.isOk, isTrue);
    expect(bus.last, 'close', reason: 'closed even on error');
    expect(started, [
      ['xdg-open', tmp.path],
    ]);
  });

  test('a bus error falls back to xdg-open on the directory itself', () async {
    await manager(failure: StateError('no bus')).reveal(tmp.path);
    expect(started, [
      ['xdg-open', tmp.path],
    ]);
  });

  test('a bus that cannot even be created falls back', () async {
    final m = LinuxFileManager(
      bus: () => throw const SocketException('no session bus'),
      start: (exe, args) async => started.add([exe, ...args]),
    );
    expect((await m.reveal(file.path)).isOk, isTrue);
    expect(started, hasLength(1));
  });

  test('both routes failing gives failed', () async {
    final result = await manager(
      failure: StateError('no bus'),
      startFailure: const ProcessException('xdg-open', []),
    ).reveal(file.path);
    expect(_error(result), FileManagerError.failed);
  });

  test('a missing path is notFound and nothing is called', () async {
    final result = await manager().reveal('${tmp.path}/gone.mp3');
    expect(_error(result), FileManagerError.notFound);
    expect(bus, isEmpty);
    expect(started, isEmpty);
  });

  test('can reveal', () => expect(manager().canReveal, isTrue));

  test('a relative path is rejected before anything runs', () async {
    final result = await manager().reveal('-x');
    expect(_error(result), FileManagerError.notFound);
    expect(bus, isEmpty);
    expect(started, isEmpty);
  });

  group('DBusFileManagerBus on a private bus', () {
    late DBusServer server;
    late DBusClient service;
    late _FakeFileManager1 object;
    late DBusAddress address;

    setUp(() async {
      server = DBusServer();
      address = await server.listenAddress(
        DBusAddress.unix(dir: Directory.systemTemp),
      );
      service = DBusClient(address);
      object = _FakeFileManager1();
      await service.requestName('org.freedesktop.FileManager1');
      await service.registerObject(object);
    });
    tearDown(() async {
      await service.close();
      await server.close();
    });

    test('ShowItems sends the uri list and an empty startup id', () async {
      final path = '${tmp.path}/Bài hát é.mp3';
      File(path).writeAsStringSync('x');
      final m = LinuxFileManager(
        bus: () => DBusFileManagerBus(client: DBusClient(address)),
        start: (exe, args) async => started.add([exe, ...args]),
      );
      final result = await m.reveal(path);
      expect(result.isOk, isTrue);
      expect(started, isEmpty, reason: 'no fallback');
      expect(object.calls, hasLength(1));
      final call = object.calls.single;
      expect(call.interface, 'org.freedesktop.FileManager1');
      expect(call.name, 'ShowItems');
      expect(call.values[0].asStringArray().toList(), [
        Uri.file(path).toString(),
      ]);
      expect(Uri.file(path).toString(), contains('%20'));
      expect(call.values[1].asString(), '');
    });

    test('a service that never answers falls back to xdg-open', () async {
      object.hang = true;
      final m = LinuxFileManager(
        bus: () => DBusFileManagerBus(
          client: DBusClient(address),
          timeout: const Duration(milliseconds: 100),
        ),
        start: (exe, args) async => started.add([exe, ...args]),
      );
      final result = await m.reveal(file.path);
      expect(result.isOk, isTrue);
      expect(object.calls, hasLength(1));
      expect(started, [
        ['xdg-open', tmp.path],
      ]);
    });

    test('a directory uses ShowFolders', () async {
      final m = LinuxFileManager(
        bus: () => DBusFileManagerBus(client: DBusClient(address)),
        start: (exe, args) async => started.add([exe, ...args]),
      );
      expect((await m.reveal(tmp.path)).isOk, isTrue);
      expect(object.calls.single.name, 'ShowFolders');
    });
  });
}

class _FakeFileManager1 extends DBusObject {
  _FakeFileManager1() : super(DBusObjectPath('/org/freedesktop/FileManager1'));

  final List<DBusMethodCall> calls = [];
  bool hang = false;

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    calls.add(methodCall);
    if (hang) await Completer<void>().future;
    return DBusMethodSuccessResponse();
  }
}
