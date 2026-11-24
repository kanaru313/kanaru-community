import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../media/domain/track_id.dart';
import '../domain/lyrics.dart';
import '../domain/translation/translation_status.dart';
import '../state/translation/translation_layout_provider.dart';
import '../state/translation/translation_providers.dart';
import 'lyrics_line.dart';
import 'translation/line_translation.dart';
import 'translation/translation_credit.dart';

/// Lines with a translation or a bar under them are taller: whenever what the
/// lines show changes, [reanchor] runs. The signal is the map itself (a new
/// translation, a re-translation or another language is a new map even when
/// it has as many lines), the loading bars, the plugin and its settings.
/// Call it from `build`.
void watchTranslationHeights(WidgetRef ref, TrackId id, VoidCallback reanchor) {
  ref.listen(
    trackTranslationProvider(id).select(
      (v) => (
        v.map,
        v.status is StatusLoading && !(v.status as StatusLoading).background,
        v.installId,
        v.settingsJson,
      ),
    ),
    (_, _) => reanchor(),
  );
}

/// One synced line: [make] builds it with the translation of [line] when
/// translation is on for [trackId] ([layout] not null), else without.
Widget translatedLine({
  required TrackId? trackId,
  required TranslationLayout? layout,
  required LyricLine line,
  required Widget Function(LineTranslation? translation) make,
}) {
  if (trackId == null || layout == null) return make(null);
  return TranslatedLineScope(
    trackId: trackId,
    line: line,
    layout: layout,
    builder: (context, translation) => make(translation),
  );
}

/// The credit line after the last lyric line.
Widget translationCreditItem(TrackId id, {required bool centered}) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: lyricsLineInset),
  child: TranslationCreditLine(trackId: id, centered: centered),
);
