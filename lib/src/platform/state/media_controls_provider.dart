import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../data/media_controls/android_audio_session_port.dart';
import '../data/media_controls/android_media_controls.dart';
import '../data/media_controls/android_media_handler.dart';
import '../data/media_controls/mpris/mpris_media_controls.dart';
import '../data/media_controls/noop_media_controls.dart';
import '../domain/media_controls.dart';

final _log = Logger('media_controls');

/// What `initAndroidMediaSession` produced; set once per process.
AndroidMediaControls? _android;
Future<void>? _androidInit;

/// Starts the Android media session: the `audio_service` handler (which must
/// exist from launch, once per process) and the audio session configured for
/// music. Android only; elsewhere it returns at once. A second call is a
/// no-op. Callers bound it with a timeout and catch what it throws.
Future<void> initAndroidMediaSession() {
  if (!Platform.isAndroid) return Future.value();
  return _androidInit ??= _initAndroid();
}

Future<void> _initAndroid() async {
  // `AudioService.init` cannot run twice in a process, so a failure is kept
  // and later calls see the same one.
  final handler = await AudioService.init(
    builder: AndroidMediaHandler.new,
    config: const AudioServiceConfig(
      androidNotificationIcon: 'drawable/ic_stat_kanaru',
      androidNotificationChannelId:
          'io.github.kanaru313.kanaru_community.playback',
      androidNotificationChannelName: 'Kanaru',
      androidStopForegroundOnPause: true,
    ),
  );
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());
  _android = AndroidMediaControls(handler, PluginAudioSessionPort(session));
}

/// The system media controls: MPRIS on Linux, `audio_service` on Android
/// (when its startup hook succeeded), nothing elsewhere or under
/// `flutter test`.
final mediaControlsProvider = Provider<MediaControls>((ref) {
  final MediaControls controls;
  if (Platform.environment['FLUTTER_TEST'] == 'true') {
    controls = const NoopMediaControls();
  } else if (Platform.isLinux) {
    controls = MprisMediaControls();
  } else if (Platform.isAndroid) {
    controls = _android ?? _androidMissing();
  } else {
    controls = const NoopMediaControls();
  }
  // The platform object outlives a provider rebuild only on Android (the
  // process-wide session); the others are made again.
  ref.onDispose(() {
    if (controls is! AndroidMediaControls) controls.dispose();
  });
  return controls;
});

MediaControls _androidMissing() {
  _log.warning('the media session did not start; no notification controls');
  return const NoopMediaControls();
}
