import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../../l10n/gen/app_localizations.dart';
import '../../../../../fonts/domain/builtin_fonts.dart';
import '../../../../../fonts/state/font_selector.dart';
import 'font_choice_row.dart';
import 'font_labels.dart';
import 'font_select_action.dart';

/// Sample line under every font name; the same in every language.
const fontSampleText = 'Aa Bb Cc Gg Qq Rr Yy 0123456789';

/// "Built in" block: the fonts that ship with the app.
class BuiltInFontsBlock extends ConsumerWidget {
  const BuiltInFontsBlock({super.key});

  static const _fonts = [nunitoFont, interFont, systemFont];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final active = ref.watch(activeFontProvider);
    return SetupSection(
      title: Text(l10n.fontsBuiltInTitle),
      hint: l10n.fontsBuiltInHint,
      hintTooltip: l10n.settingsSectionHintTooltip(l10n.fontsBuiltInTitle),
      hintTitle: l10n.fontsBuiltInTitle,
      children: [
        for (final font in _fonts)
          FontChoiceRow(
            title: fontLabel(l10n, font),
            sample: fontSampleText,
            family: font.family,
            defaultSuffix: font.id == defaultFontId
                ? l10n.fontsDefaultSuffix
                : null,
            selected: font.id == active.id,
            onTap: font.id == active.id
                ? null
                : () => selectFont(context, ref, font),
          ),
      ],
    );
  }
}
