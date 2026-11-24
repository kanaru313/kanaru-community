import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import 'translate_page_parts.dart';

/// Where a service or a tuning applies.
enum TranslateScope { song, queue, all }

/// "Áp dụng cho" [Bài này | Hàng đợi | Mọi bài]. The free app has one service
/// and one tuning for every song, so it is always on "Mọi bài": a tap on the
/// other two does nothing, and the caption says they are Pro. No Pro logic
/// lives here; the Pro build replaces this widget's job through the same
/// place.
///
/// Gap: `KSegmented` cannot dim or disable one segment, so the two Pro
/// segments look enabled; they are inert only.
class TranslateScopeSegmented extends StatelessWidget {
  const TranslateScopeSegmented({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TranslateSectionTitle(l10n.lyricsTranslateScopeTitle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: KSpace.x6),
          child: KSegmented<TranslateScope>(
            semanticLabel: l10n.lyricsTranslateScopeTitle,
            value: TranslateScope.all,
            segments: [
              KSegment(
                value: TranslateScope.song,
                label: l10n.lyricsTranslateScopeSong,
              ),
              KSegment(
                value: TranslateScope.queue,
                label: l10n.lyricsTranslateScopeQueue,
              ),
              KSegment(
                value: TranslateScope.all,
                label: l10n.lyricsTranslateScopeAll,
              ),
            ],
            // Locked in the free app: every choice stays on "Mọi bài".
            onChanged: (_) {},
          ),
        ),
        const KGap(KSpace.x1),
        TranslateCaption(
          l10n.lyricsTranslateScopePro,
          trailing: const ProBadge(),
        ),
      ],
    );
  }
}
