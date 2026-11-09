import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/kanaru.dart';
import 'package:kanaru/kanaru_bootstrap.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';
import 'package:kanaru/src/platform/domain/settings_store.dart';

class _Paths implements AppPaths {
  @override
  Directory get dataDir => Directory.systemTemp;
  @override
  Directory get cacheDir => Directory.systemTemp;
  @override
  Directory get configDir => Directory.systemTemp;
}

class _Store implements SettingsStore {
  @override
  Object? read(String key) => null;
  @override
  Future<void> write(String key, Object? value) async {}
  @override
  Stream<String> get changes => const Stream.empty();
  @override
  Future<void> flush() async {}
}

Future<SettingsStore> _settings(AppPaths _) async => _Store();
Future<String> _deviceId(AppPaths _) async => 'ID';

class _Ext implements KanaruExtension {
  _Ext(this.log, {this.hook});
  final List<String> log;
  final StartupHook? hook;
  @override
  String get id => 'probe';
  @override
  void register(ExtensionRegistry registry) {
    log.add('register');
    if (hook != null) registry.addStartupHook(hook!);
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  test('runs native, paths, database, registry, hooks in order', () async {
    final log = <String>[];
    late AppDatabase db;
    var foreignKeys = -1;
    var hasSchemaTable = false;
    final result = await bootstrap(
      extensions: [
        _Ext(log, hook: (context) async {
          log.add('hook');
          final fk = await context.connection.executor.runSelect('PRAGMA foreign_keys', []);
          foreignKeys = fk.first['foreign_keys'] as int;
          final t = await context.connection.executor.runSelect(
              "SELECT name FROM sqlite_master WHERE name = 'extension_schema'", []);
          hasSchemaTable = t.isNotEmpty;
        }),
      ],
      loadNative: () async {
        log.add('native');
        return 'v';
      },
      createPaths: () async {
        log.add('paths');
        return _Paths();
      },
      openSettings: (_) async {
        log.add('settings');
        return _Store();
      },
      loadDeviceId: (_) async {
        log.add('deviceId');
        return 'ID';
      },
      openDatabase: (_) {
        log.add('db');
        return db = AppDatabase(NativeDatabase.memory());
      },
    );
    addTearDown(result.database.close);
    expect(log, ['native', 'paths', 'settings', 'deviceId', 'db', 'register', 'hook']);
    expect(foreignKeys, 1);
    expect(hasSchemaTable, isTrue);
    expect(result.database, same(db));
    expect(result.nativeVersions, 'v');
    expect(result.deviceId, 'ID');
    expect(result.settings, isA<_Store>());
  });

  test('a failing hook closes the database and rethrows', () async {
    final log = <String>[];
    var opened = false;
    await expectLater(
      bootstrap(
        extensions: [_Ext(log, hook: (_) async => throw StateError('boom'))],
        loadNative: () async => 'v',
        createPaths: () async => _Paths(),
        openSettings: _settings,
        loadDeviceId: _deviceId,
        openDatabase: (_) {
          opened = true;
          return AppDatabase(NativeDatabase.memory());
        },
      ),
      throwsStateError,
    );
    expect(opened, isTrue);
  });

  test('a failing native load stops before paths', () async {
    final log = <String>[];
    await expectLater(
      bootstrap(
        extensions: const [],
        loadNative: () async => throw StateError('no lib'),
        createPaths: () async {
          log.add('paths');
          return _Paths();
        },
        openSettings: _settings,
        loadDeviceId: _deviceId,
        openDatabase: (_) => AppDatabase(NativeDatabase.memory()),
      ),
      throwsStateError,
    );
    expect(log, isEmpty);
  });

  test('database file name is kanaru.db, never library.db', () {
    expect(databaseFileName, 'kanaru.db');
    expect(databaseFileName, isNot('library.db'));
  });

  for (final failing in ['settings', 'deviceId']) {
    test('a failing $failing step rethrows and never opens the database', () async {
      var opened = false;
      await expectLater(
        bootstrap(
          extensions: const [],
          loadNative: () async => 'v',
          createPaths: () async => _Paths(),
          openSettings: failing == 'settings' ? (_) async => throw StateError('x') : _settings,
          loadDeviceId: failing == 'deviceId' ? (_) async => throw StateError('x') : _deviceId,
          openDatabase: (_) {
            opened = true;
            return AppDatabase(NativeDatabase.memory());
          },
        ),
        throwsStateError,
      );
      expect(opened, isFalse);
    });
  }
}
