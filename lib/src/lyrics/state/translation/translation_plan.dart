import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../media/domain/track_id.dart';
import '../../data/translation/translation_job_types.dart';
import '../../domain/lyrics_status.dart';
import '../../domain/translation/lyrics_content_hash.dart';
import '../../domain/translation/translate_input.dart';
import '../../domain/translation/translation_language.dart';
import '../../domain/translation/translation_lines.dart';
import '../track_lyrics_providers.dart';
import 'translation_engine_providers.dart';
import 'translation_settings.dart';
import 'translation_target_provider.dart';

/// What one track would translate now.
class TranslationPlan {
  const TranslationPlan({
    required this.hash,
    required this.lines,
    required this.target,
    required this.service,
    required this.song,
  });

  final String hash;

  /// The unique line texts to send.
  final List<String> lines;
  final String target;

  /// The chosen live service, null when none.
  final String? service;
  final SongContext song;

  JobKey keyFor(String installId) =>
      (hash: hash, installId: installId, target: target);

  JobRequest get request => JobRequest(lines: lines, song: song);
}

/// The inputs of [trackId], or null when nothing may run: translation off, no
/// shown lyrics, or an input still unknown (never a run on a guess).
///
/// The target is the song's own language, else the global one, else the app
/// language's default.
TranslationPlan? readTranslationPlan(Ref ref, TrackId trackId) {
  if (!ref.mounted || !ref.read(translationOnProvider)) return null;
  final shown = ref.read(trackLyricsProvider(trackId));
  if (shown is! LyricsShown) return null;
  final lines = uniqueLineTexts(shown.lyrics.lines);
  if (lines.isEmpty) return null;
  final service = ref.read(effectiveTranslationServiceProvider);
  if (!service.hasValue) return null;
  final pref = ref.read(trackTranslationTargetProvider(trackId));
  if (pref.isLoading && !pref.hasValue) return null;
  final facts = ref.read(lyricsFactsProvider(trackId)).value;
  return TranslationPlan(
    hash: lyricsContentHash(shown.lyrics.lines),
    lines: lines,
    target:
        pref.value ??
        ref.read(translationTargetProvider) ??
        appTarget(ref.read(translationAppLanguageProvider)),
    service: service.value,
    song: SongContext(title: facts?.title, artist: facts?.artist),
  );
}
