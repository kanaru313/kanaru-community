import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../domain/lyrics.dart';
import '../domain/lyrics_display_prefs.dart';
import 'lyrics_text_styles.dart';

/// Unsynchronized lyrics: the whole text, smaller than synced lines, no
/// highlight, no auto-scroll, no seek. A note line says why. Lines are built
/// lazily, so a huge file never lays out as one block.
class PlainLyricsView extends StatelessWidget {
  const PlainLyricsView({
    super.key,
    required this.lyrics,
    required this.lineSize,
    required this.sidePadding,
    required this.align,
  });

  final Lyrics lyrics;

  /// The synced line size with the user's font scale applied; the text is
  /// [KLyricsMetrics.plainScale] of it.
  final double lineSize;
  final double sidePadding;
  final LyricsAlign align;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final style = lyricsPlainStyle(
      context,
      size: lineSize * KLyricsMetrics.plainScale,
    );
    final textAlign = lyricsTextAlign(align);
    final lines = lyrics.lines;
    return Column(
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
              Icon(KIcons.lyricsNote, size: 18, color: scheme.onSurfaceVariant),
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
              itemCount: lines.length,
              itemBuilder: (context, i) {
                final text = lines[i].text;
                return Padding(
                  padding: const EdgeInsets.only(bottom: KSpace.x3),
                  // A blank line is the break between two stanzas.
                  child: text.isEmpty
                      ? SizedBox(height: style.fontSize! * 0.75)
                      : Text(text, style: style, textAlign: textAlign),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
