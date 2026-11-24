import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/lyrics.dart';
import '../../../domain/lyrics_status.dart';
import '../../../state/playing_lyrics_providers.dart';
import '../../../state/track_lyrics_providers.dart';
import '../../../state/translation/translation_commands.dart';
import '../../../state/translation/translation_layout_provider.dart';
import '../../../state/translation/translation_settings.dart';
import 'translate_frame.dart';
import 'translate_preview_parts.dart';

/// "Xem trước": the line being sung with the layers that are on, the
/// [Dưới dòng | Thay dòng] choice, and who made the translation (with ⟳ to
/// translate again).
class TranslatePreview extends ConsumerWidget {
  const TranslatePreview({
    super.key,
    required this.control,
    required this.canChoose,
    required this.onRetranslate,
  });

  final TranslateModalControl control;

  /// A service is installed, so a layout can be chosen.
  final bool canChoose;
  final VoidCallback onRetranslate;

  /// The line to preview: the sung one when this track plays, else the first
  /// that has text. Null without lyrics.
  static LyricLine? lineOf(Lyrics lyrics, int sung) {
    if (sung >= 0 && sung < lyrics.lines.length && !lyrics.lines[sung].isGap) {
      return lyrics.lines[sung];
    }
    return lyrics.lines.where((l) => !l.isGap).firstOrNull;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final id = control.trackId;
    final on = ref.watch(translationOnProvider);
    final display = ref.watch(translationDisplayProvider);
    final shown = ref.watch(trackLyricsProvider(id));
    final playsThis =
        ref.watch(playingLyricsProvider.select((p) => p.trackId)) == id;
    final sung = playsThis ? ref.watch(playingLyricsLineProvider) : -1;
    final line = shown is LyricsShown ? lineOf(shown.lyrics, sung) : null;
    final layout = ref.watch(translationLayoutProvider(id));
    final choose = on && canChoose;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KSpace.x2,
        KSpace.x1,
        KSpace.x2,
        KSpace.x2,
      ),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: scheme.surfaceContainerHighest,
          shape: KShape.of(KRadius.lg),
        ),
        child: Padding(
          // With the choice shown, its 48 dp tap area supplies the top 12.
          padding: EdgeInsets.fromLTRB(
            KSpace.x4,
            choose ? 0 : KSpace.x3,
            KSpace.x4,
            KSpace.x3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: KSpace.x2,
                children: [
                  Flexible(
                    child: Text(
                      l10n.lyricsTranslatePreview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (on && canChoose)
                    // Gives way when the row is narrower (large text scale).
                    Flexible(
                      flex: 3,
                      child: KSegmentedOutlined<TranslationDisplay>(
                        semanticLabel: l10n.lyricsTranslateDisplay,
                        value: display,
                        segments: [
                          KSegment(
                            value: TranslationDisplay.under,
                            label: l10n.lyricsTranslateDisplayUnder,
                          ),
                          KSegment(
                            value: TranslationDisplay.replace,
                            label: l10n.lyricsTranslateDisplayReplace,
                          ),
                        ],
                        onChanged: (v) =>
                            ref.read(translationCommandsProvider).setDisplay(v),
                      ),
                    ),
                ],
              ),
              // The 48 dp tap area of the segmented already spaces the row.
              KGap(choose ? 0 : KSpace.x1 + 2),
              if (line != null)
                TranslatePreviewLine(trackId: id, line: line, layout: layout),
              if (on)
                TranslateCreditRow(trackId: id, onRetranslate: onRetranslate),
            ],
          ),
        ),
      ),
    );
  }
}
