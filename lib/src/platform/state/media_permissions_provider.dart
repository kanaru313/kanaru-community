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
