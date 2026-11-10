enum MediaPermissionStatus {
  granted,
  denied,
  permanentlyDenied,

  /// Android 14 partial photo access: counts as not granted.
  limited,

  /// The platform has no such permission (Linux).
  notApplicable,
}

/// State of the two media permissions the library asks for.
class MediaPermissionState {
  const MediaPermissionState({required this.audio, required this.images});

  const MediaPermissionState.notApplicable()
    : audio = MediaPermissionStatus.notApplicable,
      images = MediaPermissionStatus.notApplicable;

  final MediaPermissionStatus audio, images;

  /// False where the platform has no media permissions.
  bool get applies => audio != MediaPermissionStatus.notApplicable;

  /// Both granted, or not applicable. [MediaPermissionStatus.limited] is not
  /// granted.
  bool get allGranted => _ok(audio) && _ok(images);

  bool get anyPermanentlyDenied =>
      audio == MediaPermissionStatus.permanentlyDenied ||
      images == MediaPermissionStatus.permanentlyDenied;

  static bool _ok(MediaPermissionStatus s) =>
      s == MediaPermissionStatus.granted ||
      s == MediaPermissionStatus.notApplicable;

  @override
  bool operator ==(Object other) =>
      other is MediaPermissionState &&
      other.audio == audio &&
      other.images == images;

  @override
  int get hashCode => Object.hash(audio, images);

  @override
  String toString() => 'MediaPermissionState(audio: ${audio.name}, '
      'images: ${images.name})';
}

abstract interface class MediaPermissions {
  Future<MediaPermissionState> status();

  /// Asks for audio first.
  Future<MediaPermissionState> requestAudio();

  /// Only called after audio is granted.
  Future<MediaPermissionState> requestImages();

  /// Opens the system settings page of the app. False when it could not.
  Future<bool> openSettings();
}
