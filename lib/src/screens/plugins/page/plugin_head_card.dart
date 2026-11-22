import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/domain/package/plugin_kind.dart';
import '../../../plugins/state/plugin_page_provider.dart';
import '../../settings/ui/settings_scaffold.dart';
import '../../settings/ui/soon_row.dart';
import '../common/plugin_icon.dart';

/// The head card: icon, name, "author (tự khai báo) · bản N", and under a
/// divider the row that says how the kind is used. Those rows belong to
/// features that are not built yet, so they are dimmed "Sắp có".
class PluginHeadCard extends StatelessWidget {
  const PluginHeadCard({super.key, required this.data, required this.nameKey});

  final PluginPageData data;

  /// On the name: the page watches it to tell when it has scrolled out.
  final GlobalKey nameKey;

  static const double _icon = KIconSize.hero;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final row = data.row;
    final kind = data.kind;
    final author = row.author ?? '';
    final byline = l10n.pluginsPageByline(
      author.isEmpty
          ? l10n.pluginsAuthorUnknown
          : l10n.pluginsPkgAuthorDeclared(author),
      row.version,
    );
    final use = switch (kind) {
      PluginKind.lyrics => SoonRow(
        icon: KIcons.lyrics,
        title: Text(l10n.pluginsPageUseLyrics),
      ),
      PluginKind.translate || PluginKind.aiTranslate => SoonRow(
        icon: KIcons.language,
        title: Text(l10n.pluginsPageUseTranslate),
      ),
      PluginKind.streaming || null => null,
    };
    return SettingsBlock(
      children: [
        Padding(
          padding: const EdgeInsets.all(KSpace.x4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: KSpace.x3,
            children: [
              PluginIcon(
                installId: row.installId,
                kind: kind,
                dimension: _icon,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      spacing: KSpace.x2,
                      children: [
                        Flexible(
                          child: Semantics(
                            header: true,
                            child: Text(
                              row.name,
                              key: nameKey,
                              style: text.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (kind == PluginKind.aiTranslate)
                          KChip.tag(label: Text(l10n.pluginsPageBadgeAi)),
                      ],
                    ),
                    Text(
                      byline,
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (use != null) ...[const Divider(height: 1), use],
      ],
    );
  }
}
