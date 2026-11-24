import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../media/domain/track_id.dart';
import '../../../domain/translation/translation_language.dart';
import '../../../state/translation/translation_providers.dart';

/// Languages whose lyrics get "Phiên âm" once it is built.
const Set<String> _phoneticLanguages = {'ja', 'zh', 'ko'};

/// "Phiên âm": the dim "Sắp có" row, only for lyrics the plugin saw as
/// Japanese, Chinese or Korean. Not pressable until the engine exists.
class TranslatePhoneticRow extends ConsumerWidget {
  const TranslatePhoneticRow({super.key, required this.trackId});

  final TrackId trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detected = ref.watch(
      trackTranslationProvider(trackId).select((v) => v.sourceLang),
    );
    if (detected == null ||
        !_phoneticLanguages.contains(baseLanguage(detected))) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KSpace.x6,
            KSpace.x3,
            KSpace.x6,
            KSpace.x1,
          ),
          child: Semantics(
            header: true,
            child: Text(
              l10n.lyricsTranslatePhoneticSection,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        KListRow(
          enabled: false,
          leading: const Icon(KIcons.languages),
          title: Text(l10n.lyricsTranslatePhoneticTitle),
          subtitle: Text(l10n.lyricsTranslatePhoneticDesc),
          trailing: Text(
            l10n.lyricsTranslateSoonTag,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
