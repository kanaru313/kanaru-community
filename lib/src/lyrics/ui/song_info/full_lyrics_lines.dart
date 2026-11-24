import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/lyrics.dart';
import '../lyrics_gap_mark.dart';
import '../lyrics_line.dart' show lyricsClock;
import '../lyrics_text_styles.dart';

/// Width of the `m:ss` column.
const double lyricsStampWidth = 44;

/// All lines of [lyrics], built lazily: the lyrics area's plain style, with
/// an `m:ss` column and the music-note mark at instrumental gaps when
/// [stamps] is on (synced lyrics only). Without stamps a gap is the break
/// between two stanzas. Desktop lets the text be selected.
class FullLyricsLines extends StatelessWidget {
  const FullLyricsLines({
    super.key,
    required this.lyrics,
    required this.stamps,
    required this.selectable,
  });

  final Lyrics lyrics;
  final bool stamps;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final style = lyricsPlainStyle(context, size: 15);
    final stampStyle = style.copyWith(
      fontSize: 12,
      color: scheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final lines = lyrics.lines;
    final list = ListView.builder(
      padding: EdgeInsets.fromLTRB(
        KSpace.x6,
        KSpace.x3,
        KSpace.x6,
        KSpace.x6 + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: lines.length,
      itemBuilder: (context, i) {
        final line = lines[i];
        final text = line.isGap
            ? (stamps
                  ? Semantics(
                      label: l10n.lyricsGapLabel,
                      excludeSemantics: true,
                      child: LyricsGapMark(active: false, color: style.color!),
                    )
                  : SizedBox(height: style.fontSize! * 0.75))
            : Text(line.text, style: style);
        return Padding(
          padding: const EdgeInsets.only(bottom: KSpace.x2),
          child: stamps
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: lyricsStampWidth,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(lyricsClock(line.time), style: stampStyle),
                      ),
                    ),
                    Expanded(child: text),
                  ],
                )
              : text,
        );
      },
    );
    return selectable ? SelectionArea(child: list) : list;
  }
}
