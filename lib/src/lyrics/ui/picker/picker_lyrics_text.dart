import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/online/lyrics_candidate.dart';
import '../../domain/online/online_text.dart';
import 'picker_format.dart';

/// The whole text of a result's lyrics: a column of `m:ss` timestamps before
/// the lines when they are synced, "♪" for an instrumental gap, a short space
/// for a blank line of plain lyrics. Parsed once per [body]; lines are built
/// as they scroll into view. [compact] is the smaller desktop pane;
/// [plainNote] puts "Lời thường, không có mốc thời gian" above plain lyrics.
class PickerLyricsText extends StatefulWidget {
  const PickerLyricsText({
    super.key,
    required this.body,
    required this.compact,
    this.plainNote = false,
    this.padding = EdgeInsets.zero,
  });

  final LyricsBody body;
  final bool compact;
  final bool plainNote;
  final EdgeInsetsGeometry padding;

  @override
  State<PickerLyricsText> createState() => _PickerLyricsTextState();
}

class _PickerLyricsTextState extends State<PickerLyricsText> {
  late OnlineText? _text = _parse();

  OnlineText? _parse() =>
      parseOnlineText(synced: widget.body.syncedLrc, plain: widget.body.plain);

  @override
  void didUpdateWidget(PickerLyricsText old) {
    super.didUpdateWidget(old);
    if (!identical(old.body, widget.body)) _text = _parse();
  }

  @override
  Widget build(BuildContext context) {
    final text = _text;
    if (text == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context).textTheme;
    final line = (widget.compact ? theme.bodyMedium : theme.bodyLarge)
        ?.copyWith(
          height: 1.75,
          color: widget.compact ? scheme.onSurfaceVariant : scheme.onSurface,
        );
    final stamp = theme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final stampWidth = MediaQuery.textScalerOf(context).scale(44);
    final lines = text.lines;
    final note = widget.plainNote && !text.synced ? 1 : 0;
    return ListView.builder(
      padding: widget.padding,
      itemCount: lines.length + note,
      itemBuilder: (context, index) {
        if (index < note) {
          return Padding(
            padding: const EdgeInsets.only(bottom: KSpace.x2),
            child: KInlineNotice(
              icon: KIcons.lyricsNote,
              message: AppLocalizations.of(context).lyricsPickerPlainNote,
            ),
          );
        }
        final l = lines[index - note];
        if (l.text.isEmpty && !text.synced) {
          return const SizedBox(height: KSpace.x2);
        }
        final words = Text(
          l.isGap ? '♪' : l.text,
          style: l.isGap
              ? line?.copyWith(color: scheme.onSurfaceVariant)
              : line,
        );
        if (!text.synced) return words;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            SizedBox(
              width: stampWidth,
              child: Text(formatTrackLength(l.time), style: stamp),
            ),
            Expanded(child: words),
          ],
        );
      },
    );
  }
}
