import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../../foundation/result.dart';
import '../domain/file_manager.dart';

final _log = Logger('platform.file_manager');

/// One `org.freedesktop.FileManager1` call over a session-bus connection.
/// A seam so tests need no bus.
abstract interface class FileManagerBus {
  /// Calls `ShowItems` or `ShowFolders` with [uris] and an empty startup id.
  Future<void> call(String method, List<String> uris);

  /// Closes the connection; called once after every [call].
  Future<void> close();
}

/// The real bus: a fresh [DBusClient.session] per instance.
class DBusFileManagerBus implements FileManagerBus {
  /// [client] is for tests (a private bus); by default the session bus.
  DBusFileManagerBus({DBusClient? client, Duration? timeout})
    : _client = client ?? DBusClient.session(),
      _timeout = timeout ?? callTimeout;

  final DBusClient _client;
  final Duration _timeout;

  /// Longest wait for the reply before the caller falls back to xdg-open.
  static const Duration callTimeout = Duration(seconds: 5);

  @override
  Future<void> call(String method, List<String> uris) async {
    await _client
        .callMethod(
          destination: 'org.freedesktop.FileManager1',
          path: DBusObjectPath('/org/freedesktop/FileManager1'),
          interface: 'org.freedesktop.FileManager1',
          name: method,
          values: [DBusArray.string(uris), const DBusString('')],
          replySignature: DBusSignature(''),
        )
        // A bus-activated file manager that hangs must not hang the menu.
        .timeout(_timeout);
  }

  @override
  Future<void> close() => _client.close();
}

/// Starts a detached process; a seam for tests.
typedef DetachedStarter = Future<void> Function(
  String executable,
  List<String> arguments,
);

Future<void> _startDetached(String executable, List<String> arguments) async {
  await Process.start(executable, arguments, mode: ProcessStartMode.detached);
}

/// Linux: asks the desktop's file manager over D-Bus to select the file
/// (`ShowItems`) or open the folder (`ShowFolders`); without a bus or a
/// FileManager1 service it falls back to `xdg-open` on the parent folder
/// (a file) or the folder itself.
class LinuxFileManager implements FileManager {
  LinuxFileManager({FileManagerBus Function()? bus, DetachedStarter? start})
    : _bus = bus ?? DBusFileManagerBus.new,
      _start = start ?? _startDetached;

  final FileManagerBus Function() _bus;
  final DetachedStarter _start;

  @override
  bool get canReveal => true;

  /// A failure of the xdg-open fallback is not seen: it is started detached,
  /// so a non-zero exit of the opener still gives `Ok`.
  ///
  /// A path that is not absolute is `notFound` (it could pass as an option).
  @override
  Future<Result<void, FileManagerError>> reveal(String absolutePath) async {
    if (!p.isAbsolute(absolutePath)) {
      return const Err(FileManagerError.notFound);
    }
    final type = await FileSystemEntity.type(absolutePath);
    if (type == FileSystemEntityType.notFound) {
      return const Err(FileManagerError.notFound);
    }
    final isDirectory = type == FileSystemEntityType.directory;
    final uri = Uri.file(absolutePath).toString();
    // ShowItems on a directory would select it in its parent folder.
    final method = isDirectory ? 'ShowFolders' : 'ShowItems';
    FileManagerBus? bus;
    try {
      bus = _bus();
      await bus.call(method, [uri]);
      return const Ok(null);
    } catch (error) {
      // No session bus, no FileManager1 owner, or a refusing service.
      _log.info('$method failed (${error.runtimeType}); using xdg-open');
    } finally {
      try {
        await bus?.close();
      } catch (error) {
        _log.fine('closing the bus failed (${error.runtimeType})');
      }
    }
    return _openWithXdg(
      isDirectory ? absolutePath : File(absolutePath).parent.path,
    );
  }

  Future<Result<void, FileManagerError>> _openWithXdg(String directory) async {
    try {
      await _start('xdg-open', [directory]);
      return const Ok(null);
    } catch (error, stack) {
      _log.warning('xdg-open failed', error, stack);
      return const Err(FileManagerError.failed);
    }
  }
}
