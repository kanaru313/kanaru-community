import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../plugins/domain/package/translate_spec.dart'
    show translationLanguageCodes;
import '../../../domain/translation/translation_language.dart';
import '../../../state/translation/translation_commands.dart';
import '../../../state/translation/translation_engine_providers.dart'
    show translationAppLanguageProvider;
import '../../../state/translation/translation_providers.dart';
import '../translation_language_name.dart';
import 'translate_frame.dart';
import 'translate_page_parts.dart';

/// "Dịch sang": the languages as text rows, the chosen one marked. The row of
/// the app language says "Theo ngôn ngữ ứng dụng". Choosing writes the song's
/// own language and closes the page.
class TranslateTargetPage extends ConsumerStatefulWidget {
  const TranslateTargetPage({super.key, required this.control});

  final TranslateModalControl control;

  @override
  ConsumerState<TranslateTargetPage> createState() =>
      _TranslateTargetPageState();
}

class _TranslateTargetPageState extends ConsumerState<TranslateTargetPage> {
  bool _failed = false;

  Future<void> _pick(String code) async {
    final navigator = Navigator.of(context);
    final saved = await ref
        .read(translationCommandsProvider)
        .setTarget(widget.control.trackId, code);
    if (!mounted) return;
    if (saved) {
      navigator.pop();
    } else {
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final target = ref.watch(
      effectiveTranslationTargetProvider(widget.control.trackId),
    );
    final appDefault = appTarget(ref.watch(translationAppLanguageProvider));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TranslatePageHeader(
          title: l10n.lyricsTranslateTargetTitle,
          onClose: () => Navigator.of(context).pop(),
        ),
        if (_failed)
          TranslateCaption(l10n.lyricsTranslateTargetFailed, error: true),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final code in translationLanguageCodes)
                  SelectionRow(
                    title: Text(translationLanguageName(l10n, code)),
                    subtitle: code == appDefault
                        ? Text(l10n.lyricsTranslateTargetApp)
                        : null,
                    selected: code == target,
                    onTap: () => _pick(code),
                  ),
                const KGap(KSpace.x2),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
