import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../media/domain/track_id.dart';
import '../domain/lyrics.dart';
import '../domain/lyrics_display_prefs.dart';
import '../state/translation/translation_layout_provider.dart';
import '../state/translation/translation_settings.dart';
import 'lyrics_text_styles.dart';
import 'translation/line_translation.dart';
import 'translation/shown_translation.dart';
import 'translation/translated_line_text.dart';
import 'translation/translation_credit.dart';
import 'translation/translation_text_styles.dart';

/// Unsynchronized lyrics: the whole text, smaller than synced lines, no
/// highlight, no auto-scroll, no seek. A note line says why. Lines are built
/// lazily, so a huge file never lays out as one block.
class PlainLyricsView extends ConsumerWidget {
  const PlainLyricsView({
    super.key,
    required this.lyrics,
    required this.lineSize,
    required this.sidePadding,
    required this.align,
    this.trackId,
  });

  final Lyrics lyrics;

  /// The synced line size with the user's font scale applied; the text is
  /// [KLyricsMetrics.plainScale] of it.
  final double lineSize;
  final double sidePadding;
  final LyricsAlign align;

  /// The track whose translation shows under each line; null shows none.
  final TrackId? trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final style = lyricsPlainStyle(
      context,
      size: lineSize * KLyricsMetrics.plainScale,
    );
    final textAlign = lyricsTextAlign(align);
    final lines = lyrics.lines;
    final id = trackId;
    final layout = id == null ? null : ref.watch(translationLayoutProvider(id));
    final trSize = ref.watch(translationSizeProvider);
    return TranslationPresence(
      trackId: id,
      active: layout != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              sidePadding,
              KSpace.x1,
              sidePadding,
              KSpace.x2,
            ),
            child: Row(
              spacing: KSpace.x2,
              children: [
                Icon(
                  KIcons.lyricsNote,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                Expanded(
                  child: Text(
                    l10n.lyricsPlainNote,
                    style: lyricsNoteStyle(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            // Desktop platforms add a scrollbar; lyrics scroll without one.
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context)
                  .copyWith(scrollbars: false),
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  sidePadding,
                  0,
                  sidePadding,
                  KSpace.x6 + MediaQuery.paddingOf(context).bottom,
                ),
                // With translation on, one more item: the credit line.
                itemCount: lines.length + (layout == null ? 0 : 1),
                itemBuilder: (context, i) {
                  if (i == lines.length) {
                    return TranslationCreditLine(
                      trackId: id!,
                      centered: align == LyricsAlign.center,
                    );
                  }
                  final text = lines[i].text;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: KSpace.x3),
                    // A blank line is the break between two stanzas.
                    child: text.isEmpty
                        ? SizedBox(height: style.fontSize! * 0.75)
                        : id == null || layout == null
                        ? Text(text, style: style, textAlign: textAlign)
                        : TranslatedLineScope(
                            trackId: id,
                            line: lines[i],
                            layout: layout,
                            builder: (context, translation) => DefaultTextStyle(
                              style: style,
                              textAlign: textAlign,
                              child: TranslatedLineText(
                                original: text,
                                translation: translation,
                                translationStyle: plainTranslationStyle(
                                  context,
                                  style,
                                  trSize,
                                ),
                                originalStyle: plainReplacedOriginalStyle(
                                  context,
                                  style,
                                  trSize,
                                ),
                                textAlign: textAlign,
                                duration: Duration.zero,
                              ),
                            ),
                          ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
