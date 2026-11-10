import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/permissions/android_media_permissions.dart';
import '../data/permissions/no_media_permissions.dart';
import '../domain/media_permissions.dart';
import 'local_audio_catalog_provider.dart';

/// Media permissions of the running platform. Tests override it.
final mediaPermissionsProvider = Provider<MediaPermissions>((ref) {
  if (Platform.isAndroid) {
    final client = ref.watch(mediaStoreChannelClientProvider);
    return AndroidMediaPermissions(sdkInt: client.sdkInt);
  }
  if (Platform.isLinux) return const NoMediaPermissions();
  throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
});

/// What the first-run screen shows about permissions. Loads once, then
/// changes only through [request], [refresh] or a read after returning from
/// the system settings.
class MediaPermissionStateNotifier extends AsyncNotifier<MediaPermissionState> {
  @override
  Future<MediaPermissionState> build() =>
      ref.watch(mediaPermissionsProvider).status();

  /// Reads the current status (for example when the app comes back from the
  /// system settings). A failed read keeps the last value.
  Future<MediaPermissionState?> refresh() async {
    final port = ref.read(mediaPermissionsProvider);
    final MediaPermissionState next;
    try {
      next = await port.status();
    } on Object {
      return state.value;
    }
    if (ref.mounted) state = AsyncData(next);
    return next;
  }

  /// Asks for what is missing, audio first and images only once audio is
  /// granted (Android shows the second dialog right after the first). Returns
  /// the state after the last dialog.
  Future<MediaPermissionState> request() async {
    final port = ref.read(mediaPermissionsProvider);
    var current = state.value ?? await port.status();
    if (current.audio != MediaPermissionStatus.granted &&
        current.audio != MediaPermissionStatus.notApplicable) {
      current = await port.requestAudio();
      if (ref.mounted) state = AsyncData(current);
    }
    if (current.audio == MediaPermissionStatus.granted &&
        current.images != MediaPermissionStatus.granted) {
      current = await port.requestImages();
      if (ref.mounted) state = AsyncData(current);
    }
    return current;
  }

  /// Opens the system settings page of the app.
  Future<bool> openSettings() =>
      ref.read(mediaPermissionsProvider).openSettings();
}

final mediaPermissionStateProvider =
    AsyncNotifierProvider<MediaPermissionStateNotifier, MediaPermissionState>(
      MediaPermissionStateNotifier.new,
    );
