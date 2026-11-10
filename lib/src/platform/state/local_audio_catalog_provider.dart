import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_files/linux_audio_catalog.dart';
import '../data/media_store/media_store_audio_catalog.dart';
import '../data/media_store/media_store_channel_client.dart';
import '../domain/local_audio_catalog.dart';

/// The MediaStore channel client (Android only). Tests override it.
final mediaStoreChannelClientProvider = Provider<MediaStoreChannelClient>(
  (ref) => MediaStoreChannelClient(),
);

/// The audio catalog of the running platform. Tests override it.
final localAudioCatalogProvider = Provider<LocalAudioCatalog>((ref) {
  if (Platform.isAndroid) {
    return MediaStoreAudioCatalog(ref.watch(mediaStoreChannelClientProvider));
  }
  if (Platform.isLinux) return LinuxAudioCatalog();
  throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
});
