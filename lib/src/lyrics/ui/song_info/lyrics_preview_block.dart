import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/lyrics.dart';
import '../lyrics_text_styles.dart';
import 'lyrics_kind_pill.dart';
import '../online/online_labels.dart';
import 'song_info_lyrics_labels.dart';

/// How many lines the block shows.
const int lyricsPreviewLines = 5;

/// The preview of saved lyrics in the song info page: the kind pill, the line
/// count, the first five lines without timestamps fading out, and "Xem cả
/// lời ›". The whole block is one button ([onOpen]); hover tints it 8 %, a
/// keyboard focus draws a `primary` border.
class LyricsPreviewBlock extends StatefulWidget {
  const LyricsPreviewBlock({
    super.key,
    required this.lyrics,
    required this.onOpen,
  });

  final Lyrics lyrics;
  final VoidCallback onOpen;

  @override
  State<LyricsPreviewBlock> createState() => _LyricsPreviewBlockState();
}

class _LyricsPreviewBlockState extends State<LyricsPreviewBlock> {
  bool _focused = false;
  bool _keyboard =
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_onHighlightMode);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
    super.dispose();
  }

  // Touch to keyboard (and back) while the block keeps focus redraws the ring.
  void _onHighlightMode(FocusHighlightMode mode) {
    final keyboard = mode == FocusHighlightMode.traditional;
    if (keyboard != _keyboard) setState(() => _keyboard = keyboard);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final count = lyricsTextLineCount(widget.lyrics);
    final shown = [
      for (final line in widget.lyrics.lines)
        if (!line.isGap) line.text,
    ].take(lyricsPreviewLines).toList();
    final ring = _focused && _keyboard;
    final style = lyricsPlainStyle(context, size: 14);
    return Semantics(
      button: true,
      container: true,
      label:
          '${onlineKindLabel(l10n, synced: widget.lyrics.synced)}, '
          '${l10n.lyricsInfoLines(count)}, ${l10n.lyricsInfoSeeAll}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onOpen,
          onFocusChange: (v) => setState(() => _focused = v),
          hoverColor: scheme.onSurface.withValues(alpha: 0.08),
          child: ExcludeSemantics(
            child: Container(
              constraints: const BoxConstraints(minHeight: KLayout.minTarget),
              decoration: BoxDecoration(
                border: Border.all(
                  width: 2,
                  color: ring ? scheme.primary : Colors.transparent,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: KSpace.x4,
                vertical: KSpace.x3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    spacing: KSpace.x2,
                    children: [
                      LyricsKindPill(synced: widget.lyrics.synced),
                      Text(
                        l10n.lyricsInfoLines(count),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: KSpace.x2),
                  ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF000000), Color(0x00000000)],
                      stops: [0.45, 1],
                    ).createShader(rect),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final text in shown)
                          Padding(
                            padding: const EdgeInsets.only(bottom: KSpace.x1),
                            child: Text(text, style: style),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: KSpace.x1),
                  Text(
                    '${l10n.lyricsInfoSeeAll} ›',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
