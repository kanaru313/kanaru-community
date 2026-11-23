import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../../l10n/gen/app_localizations.dart';
import '../../../../../fonts/domain/font_catalog.dart';
import '../../../../../fonts/state/font_downloads.dart';
import '../../../../../fonts/state/font_providers.dart';
import '../../../../../fonts/state/font_selector.dart';
import '../../../../../fonts/state/installed_catalog_fonts.dart';
import 'builtin_fonts_block.dart' show fontSampleText;
import 'catalog_font_actions.dart';
import 'font_choice_row.dart';
import 'font_select_action.dart';

final _log = Logger('catalog_fonts_block');

/// "Online fonts" block: downloaded fonts first, then the rest, each in
/// catalog order. A font that is not downloaded is drawn in the app font and
/// only its download button acts.
class CatalogFontsBlock extends ConsumerStatefulWidget {
  const CatalogFontsBlock({super.key});

  @override
  ConsumerState<CatalogFontsBlock> createState() => _CatalogFontsBlockState();
}

class _CatalogFontsBlockState extends ConsumerState<CatalogFontsBlock> {
  @override
  void initState() {
    super.initState();
    // Downloaded fonts must be in the engine to draw their own rows.
    final registrar = ref.read(fontLoaderProvider);
    final storage = ref.read(fontStorageProvider);
    for (final id in ref.read(installedCatalogFontsProvider)) {
      final font = catalogFontById(id)?.asAppFont;
      if (font == null) continue;
      registrar.ensureLoaded(font, storage).then((_) {
        if (mounted) setState(() {});
      }, onError: (Object e) => _log.warning('cannot load "$id"', e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final installed = ref.watch(installedCatalogFontsProvider);
    final downloading = ref.watch(fontDownloadsProvider);
    final activeId = ref.watch(activeFontProvider).id;
    final registrar = ref.watch(fontLoaderProvider);
    final ordered = [
      for (final f in catalogFonts)
        if (installed.contains(f.id)) f,
      for (final f in catalogFonts)
        if (!installed.contains(f.id)) f,
    ];
    return SetupSection(
      title: Text(l10n.fontsCatalogTitle),
      hint: l10n.fontsCatalogHint,
      hintTooltip: l10n.settingsSectionHintTooltip(l10n.fontsCatalogTitle),
      hintTitle: l10n.fontsCatalogTitle,
      children: [
        for (final font in ordered)
          _row(
            context,
            font,
            have: installed.contains(font.id),
            loaded: registrar.isFamilyLoaded(font.family),
            busy: downloading.contains(font.id),
            active: font.id == activeId,
          ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    CatalogFont font, {
    required bool have,
    required bool loaded,
    required bool busy,
    required bool active,
  }) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    Widget? trailing;
    if (busy) {
      trailing = Semantics(
        label: l10n.fontsDownloading(font.label),
        liveRegion: true,
        child: const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (!have) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            font.formattedSize,
            style: Theme.of(context).textTheme.bodySmall!
                .copyWith(color: scheme.onSurfaceVariant),
          ),
          KIconButton(
            icon: KIcons.download,
            tooltip: l10n.fontsDownloadTooltip(font.label),
            onPressed: () => downloadCatalogFont(context, ref, font),
          ),
        ],
      );
    } else if (!active) {
      trailing = KIconButton(
        icon: KIcons.delete,
        tooltip: l10n.fontsDeleteTooltip(font.label),
        onPressed: () => deleteCatalogFont(context, ref, font),
      );
    }
    return FontChoiceRow(
      title: font.label,
      sample: fontSampleText,
      family: have && loaded ? font.family : null,
      selected: active,
      trailing: trailing,
      onTap: have && !active
          ? () => selectFont(context, ref, font.asAppFont)
          : null,
    );
  }
}
