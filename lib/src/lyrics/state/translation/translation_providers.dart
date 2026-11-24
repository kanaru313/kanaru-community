import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../media/domain/track_id.dart';
import '../playing_lyrics_providers.dart';
import 'track_translation_notifier.dart';
import 'translation_view.dart';

export 'translation_engine_providers.dart' show translationJobsProvider;
export 'translation_target_provider.dart';

/// The translation of one track. Watching it is what asks for a translation;
/// the last watcher going away drops the song's unsent chunks (a chunk that
/// was sent still finishes into the cache).
final trackTranslationProvider =
    NotifierProvider.family<TrackTranslation, TranslationView, TrackId>(
      TrackTranslation.new,
      isAutoDispose: true,
    );

/// The translation of the playing track; idle when nothing plays.
final playingTranslationProvider = Provider<TranslationView>((ref) {
  final id = ref.watch(playingLyricsProvider.select((p) => p.trackId));
  if (id == null) return TranslationView.idle;
  return ref.watch(trackTranslationProvider(id));
}, isAutoDispose: true);
