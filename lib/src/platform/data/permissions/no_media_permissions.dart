import '../../domain/media_permissions.dart';

/// Platforms without media permissions (Linux): everything is allowed.
class NoMediaPermissions implements MediaPermissions {
  const NoMediaPermissions();

  static const _state = MediaPermissionState.notApplicable();

  @override
  Future<MediaPermissionState> status() async => _state;

  @override
  Future<MediaPermissionState> requestAudio() async => _state;

  @override
  Future<MediaPermissionState> requestImages() async => _state;

  @override
  Future<bool> openSettings() async => false;
}
