import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../platform/state/platform_providers.dart';
import '../data/waveform_cache.dart';
import '../data/waveform_native.dart';
import '../data/waveform_repository.dart';
import '../domain/playable.dart';
import '../domain/playback_views.dart';
import '../domain/repeat_mode.dart';
import '../domain/waveform.dart';
import 'playback_data_providers.dart';
import 'queue_view_provider.dart';
import 'waveform_loader.dart';

/// Waveform files live under `<cache>/waveforms/v1/`; a new layout gets a new
/// version folder and the old one is simply no longer read.
const waveformCacheFolder = 'waveforms/v1';

final waveformRepositoryProvider = Provider<WaveformRepository>(
  (ref) => WaveformRepository(
    cache: WaveformCache(
      Directory(
        p.joinAll([
          ref.watch(appPathsProvider).cacheDir.path,
          ...waveformCacheFolder.split('/'),
        ]),
      ),
    ),
    start: startNativeWaveform,
  ),
);

/// Lives as long as the app, so the memory LRU outlives one Now Playing view.
final waveformLoaderProvider = Provider<WaveformLoader>(
  (ref) => WaveformLoader(
    repository: ref.watch(waveformRepositoryProvider),
    pathOf: (id) async {
      final playable = (await ref.read(playableResolverProvider).resolve([
        id,
      ]))[id];
      return playable is LocalFile ? playable.path : null;
    },
  ),
);

/// Current and next entry of the queue in play order, for the loader.
WaveformWant waveformWantOf(QueueView view) {
  final current = view.current;
  if (current == null || current >= view.items.length) {
    return WaveformWant.none;
  }
  final now = view.items[current];
  final nextIndex = switch (view.repeat) {
    RepeatMode.one => null,
    _ when current + 1 < view.items.length => current + 1,
    RepeatMode.all when view.items.length > 1 => 0,
    _ => null,
  };
  final next = nextIndex == null ? null : view.items[nextIndex];
  return WaveformWant(
    currentEntry: now.entryId,
    currentTrack: now.trackId,
    nextEntry: next?.entryId,
    nextTrack: next?.trackId,
  );
}

/// The waveform of the playing entry. It decodes only while something
/// watches it (a seek bar is mounted); when the last watcher goes away the
/// running job is cancelled. Riverpod drops an unwatched provider a moment
/// later, so a same-frame remount keeps the job.
final waveformProvider = StreamProvider.autoDispose<WaveformView>((ref) {
  final wants = StreamController<WaveformWant>();
  ref.onDispose(wants.close);
  ref.listen(queueViewProvider, (_, next) {
    final view = next.value;
    if (view != null && !wants.isClosed) wants.add(waveformWantOf(view));
  }, fireImmediately: true);
  return ref.watch(waveformLoaderProvider).watch(wants.stream.distinct());
});
