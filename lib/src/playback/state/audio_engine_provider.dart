import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/media_kit_engine.dart';
import '../data/silent_audio_engine.dart';
import '../domain/audio_engine.dart';

/// Makes the engine. The controller calls it lazily, on the first load, so a
/// screen that never plays never loads libmpv. Under `flutter test` the default
/// is [SilentAudioEngine]: no sound, no native library. A test that needs
/// control overrides this provider.
final audioEngineFactoryProvider = Provider<AudioEngine Function()>(
  (ref) =>
      () => Platform.environment['FLUTTER_TEST'] == 'true'
      ? SilentAudioEngine()
      : MediaKitEngine(),
);
