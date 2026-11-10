import 'package:permission_handler/permission_handler.dart';

import '../../domain/media_permissions.dart';

/// Android SDK that introduced the granular media permissions.
const granularMediaPermissionsSdk = 33;

/// Maps a plugin status to the app's. `limited` (Android 14 partial photo
/// access) stays its own value; `restricted` can only be changed in settings,
/// so it counts as permanently denied; `provisional` allows access.
MediaPermissionStatus mapStatus(PermissionStatus status) => switch (status) {
  PermissionStatus.granted ||
  PermissionStatus.provisional => MediaPermissionStatus.granted,
  PermissionStatus.limited => MediaPermissionStatus.limited,
  PermissionStatus.permanentlyDenied ||
  PermissionStatus.restricted => MediaPermissionStatus.permanentlyDenied,
  PermissionStatus.denied => MediaPermissionStatus.denied,
};

/// The status to show after reading [fresh] when the last `request()` for the
/// same permission returned [lastRequest].
///
/// permission_handler reports a permanent denial as `denied` from a status
/// read, so a permanent denial seen at request time is kept until the user
/// grants (or limits) the permission in settings.
MediaPermissionStatus mergeStatus(
  MediaPermissionStatus? lastRequest,
  MediaPermissionStatus fresh,
) =>
    lastRequest == MediaPermissionStatus.permanentlyDenied &&
        fresh == MediaPermissionStatus.denied
    ? MediaPermissionStatus.permanentlyDenied
    : fresh;

/// The plugin permissions behind the audio and images rows for [sdkInt]:
/// the single storage permission up to SDK 32, the granular ones from 33.
({Permission audio, Permission images}) permissionsForSdk(int sdkInt) =>
    sdkInt < granularMediaPermissionsSdk
    ? (audio: Permission.storage, images: Permission.storage)
    : (audio: Permission.audio, images: Permission.photos);
