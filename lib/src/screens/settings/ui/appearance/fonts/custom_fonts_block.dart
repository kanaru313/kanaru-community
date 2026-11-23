import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../../l10n/gen/app_localizations.dart';
import '../../../../../fonts/domain/custom_font.dart';
import '../../../../../fonts/state/custom_fonts.dart';
import '../../../../../fonts/state/font_providers.dart';
import '../../../../../fonts/state/font_selector.dart';
import 'builtin_fonts_block.dart' show fontSampleText;
import 'font_choice_row.dart';
import 'font_import_flow.dart';
import 'font_select_action.dart';

final _log = Logger('custom_fonts_block');

/// "Custom" block: the fonts the user imported, then the import row. Every
/// imported font is loaded into the engine when the page opens (and when one
/// is added) so its row is drawn in its own face; a font that fails to load
/// keeps the app font in its row.
class CustomFontsBlock extends ConsumerStatefulWidget {
  const CustomFontsBlock({super.key});

  @override
  ConsumerState<CustomFontsBlock> createState() => _CustomFontsBlockState();
}

class _CustomFontsBlockState extends ConsumerState<CustomFontsBlock> {
  @override
  void initState() {
    super.initState();
    _load(ref.read(customFontsProvider));
  }

  /// Starts loading every font in parallel; the registrar shares loads and
  /// skips loaded families.
  void _load(List<CustomFont> fonts) {
    final registrar = ref.read(fontLoaderProvider);
    final storage = ref.read(fontStorageProvider);
    for (final font in fonts) {
      if (registrar.isFamilyLoaded(font.id)) continue;
      registrar.ensureLoaded(font.asAppFont, storage).then((_) {
        if (mounted) setState(() {});
      }, onError: (Object e) => _log.warning('cannot load "${font.id}"', e));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(customFontsProvider, (_, fonts) => _load(fonts));
    final l10n = AppLocalizations.of(context);
    final fonts = ref.watch(customFontsProvider);
    final activeId = ref.watch(activeFontProvider).id;
    final registrar = ref.watch(fontLoaderProvider);
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    return SetupSection(
      title: Text(l10n.fontsCustomTitle),
      hint: l10n.fontsCustomHint,
      hintTooltip: l10n.settingsSectionHintTooltip(l10n.fontsCustomTitle),
      hintTitle: l10n.fontsCustomTitle,
      children: [
        for (final font in fonts)
          FontChoiceRow(
            title: font.label,
            sample: fontSampleText,
            family: registrar.isFamilyLoaded(font.id) ? font.id : null,
            selected: font.id == activeId,
            trailing: KIconButton(
              icon: KIcons.delete,
              tooltip: l10n.fontsDeleteTooltip(font.label),
              onPressed: () => deleteCustomFont(context, ref, font),
            ),
            onTap: font.id == activeId
                ? null
                : () => selectFont(context, ref, font.asAppFont),
          ),
        SetupAddRow(
          icon: KIcons.add,
          label: Text(
            desktop ? l10n.fontsImportRowDialog : l10n.fontsImportRow,
          ),
          onTap: () => importCustomFont(context, ref),
        ),
      ],
    );
  }
}
