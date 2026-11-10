import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/media_permissions.dart';
import 'permission_mapping.dart';

/// Media permissions on Android through permission_handler.
///
/// Remembers the last `request()` result of each row, so a permanent denial
/// is not shown as a plain denial by a later status read; the memory is
/// dropped once a read shows anything but `denied`. Requests are serialized
/// (the plugin refuses a second one while a dialog is up) and a repeated
/// request for the same row shares the one in flight. No call throws.
class AndroidMediaPermissions implements MediaPermissions {
  AndroidMediaPermissions({
    required this.sdkInt,
    this.readStatus = _pluginStatus,
    this.requestPermission = _pluginRequest,
    this.statusWait = const Duration(seconds: 30),
  });

  static final _log = Logger('platform.permissions');

  /// Android SDK level, read lazily (from the MediaStore channel).
  final Future<int> Function() sdkInt;

  /// Longest a status read waits for requests in flight (a dialog that never
  /// closes must not hang every read).
  final Duration statusWait;

  /// Plugin seams, replaced in tests.
  final Future<PermissionStatus> Function(Permission) readStatus;
  final Future<PermissionStatus> Function(Permission) requestPermission;

  static Future<PermissionStatus> _pluginStatus(Permission p) => p.status;
  static Future<PermissionStatus> _pluginRequest(Permission p) => p.request();

  MediaPermissionStatus? _lastAudio, _lastImages;
  Future<MediaPermissionState>? _audioInFlight, _imagesInFlight;
  Future<void> _queue = Future.value();

  static const _failed = MediaPermissionState(
    audio: MediaPermissionStatus.denied,
    images: MediaPermissionStatus.denied,
  );

  Future<MediaPermissionStatus> _read(
    Permission permission,
    MediaPermissionStatus? last,
  ) async => mergeStatus(last, mapStatus(await readStatus(permission)));

  Future<MediaPermissionState> _state() async {
    final permissions = permissionsForSdk(await sdkInt());
    final seenAudio = _lastAudio, seenImages = _lastImages;
    final audio = await _read(permissions.audio, seenAudio);
    final images = await _read(permissions.images, seenImages);
    // A remembered permanent denial only lives while reads keep saying denied;
    // a request that finished during this read keeps its newer value.
    if (audio != MediaPermissionStatus.permanentlyDenied &&
        _lastAudio == seenAudio) {
      _lastAudio = null;
    }
    if (images != MediaPermissionStatus.permanentlyDenied &&
        _lastImages == seenImages) {
      _lastImages = null;
    }
    return MediaPermissionState(audio: audio, images: images);
  }

  /// Runs [body]; reports "denied" and logs when anything fails.
  Future<MediaPermissionState> _safe(
    Future<MediaPermissionState> Function() body,
  ) async {
    try {
      return await body();
    } on Exception catch (error, stack) {
      _log.warning('Permission call failed', error, stack);
      return _failed;
    }
  }

  /// Runs [body] after every earlier request has finished.
  Future<MediaPermissionState> _serial(
    Future<MediaPermissionState> Function() body,
  ) {
    final run = _queue.then((_) => _safe(body));
    _queue = run.then((_) {});
    return run;
  }

  @override
  Future<MediaPermissionState> status() => _safe(() async {
    // A read that overlaps a request would see the dialog's old state.
    await _queue.timeout(statusWait, onTimeout: () {});
    return _state();
  });

  @override
  Future<MediaPermissionState> requestAudio() {
    final running = _audioInFlight;
    if (running != null) return running;
    final run = _serial(() async {
      final permissions = permissionsForSdk(await sdkInt());
      _lastAudio = mapStatus(await requestPermission(permissions.audio));
      return _state();
    });
    _audioInFlight = run;
    return run.whenComplete(() => _audioInFlight = null);
  }

  @override
  Future<MediaPermissionState> requestImages() {
    final running = _imagesInFlight;
    if (running != null) return running;
    final run = _serial(() async {
      final permissions = permissionsForSdk(await sdkInt());
      _lastImages = mapStatus(await requestPermission(permissions.images));
      return _state();
    });
    _imagesInFlight = run;
    return run.whenComplete(() => _imagesInFlight = null);
  }

  @override
  Future<bool> openSettings() async {
    try {
      return await openAppSettings();
    } on Exception catch (error, stack) {
      _log.warning('Could not open the app settings', error, stack);
      return false;
    }
  }
}
