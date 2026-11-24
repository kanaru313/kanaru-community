import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../media/domain/track_id.dart';
import '../../../domain/lyrics.dart';
import '../../../domain/translation/translation_status.dart';
import '../../../state/lyrics_settings.dart';
import '../../../state/translation/translation_credit_provider.dart';
import '../../../state/translation/translation_layout_provider.dart';
import '../../../state/translation/translation_providers.dart';
import '../../lyrics_spinner.dart';
import '../line_translation.dart';
import '../translated_line_text.dart';
import '../translation_text_styles.dart';

/// The line of the preview with the layers that are on.
class TranslatePreviewLine extends ConsumerWidget {
  const TranslatePreviewLine({
    super.key,
    required this.trackId,
    required this.line,
    required this.layout,
  });

  final TrackId trackId;
  final LyricLine line;
  final TranslationLayout? layout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = Theme.of(context).textTheme.titleMedium!
        .copyWith(fontWeight: FontWeight.w700);
    final dim = ref.watch(lyricsDimProvider);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : KMotion.fast;
    Widget text(LineTranslation t) => TranslatedLineText(
      original: line.text,
      translation: t,
      translationStyle: lyricsTranslationStyle(
        context,
        line: base,
        current: true,
        dim: dim,
      ),
      originalStyle: lyricsReplacedOriginalStyle(
        context,
        line: base,
        current: true,
        dim: dim,
      ),
      textAlign: TextAlign.center,
      duration: duration,
    );
    final layout = this.layout;
    return DefaultTextStyle.merge(
      style: base,
      textAlign: TextAlign.center,
      child: layout == null
          ? text(const LineTranslation())
          : TranslatedLineScope(
              trackId: trackId,
              line: line,
              layout: layout,
              builder: (context, translation) => text(translation),
            ),
    );
  }
}

/// "Dịch bởi …" (+ ⟳), "Bản có sẵn của …", or "Đang dịch lại, bản cũ vẫn
/// hiện"; nothing while no translation is shown.
class TranslateCreditRow extends ConsumerWidget {
  const TranslateCreditRow({
    super.key,
    required this.trackId,
    required this.onRetranslate,
  });

  final TrackId trackId;
  final VoidCallback onRetranslate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: scheme.onSurfaceVariant);
    final status = ref.watch(
      trackTranslationProvider(trackId).select((v) => v.status),
    );
    final credit = ref.watch(translationCreditProvider(trackId));
    if (status is StatusLoading && status.background) {
      return Padding(
        padding: const EdgeInsets.only(top: KSpace.x2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LyricsSpinner(size: KIconSize.xs, color: scheme.primary),
            const KGap(KSpace.x2),
            Flexible(child: Text(l10n.lyricsTranslateRedoing, style: style)),
          ],
        ),
      );
    }
    if (credit == null) return const SizedBox.shrink();
    final by = [credit.plugin, credit.model, credit.style].nonNulls.join(' · ');
    final text = credit.other
        ? l10n.lyricsTranslationCreditOther(credit.plugin)
        : credit.partial
        ? l10n.lyricsTranslateByPartial(by, credit.linesDone, credit.linesTotal)
        : l10n.lyricsTranslateBy(by);
    final again = !credit.other && !credit.partial;
    return Padding(
      padding: const EdgeInsets.only(top: KSpace.x2),
      // One centred line, the ⟳ right after the text; it wraps only when the
      // text cannot fit the card.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(text, style: style, textAlign: TextAlign.center),
          ),
          if (again)
            KIconButton(
              icon: KIcons.refresh,
              size: KIconSize.xs,
              tooltip: l10n.lyricsTranslateRetranslate,
              onPressed: onRetranslate,
            ),
        ],
      ),
    );
  }
}
