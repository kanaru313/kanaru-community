import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../ai/ui/ai_settings_link.dart';
import '../../../plugins/domain/package/plugin_kind.dart';
import '../../../lyrics/state/online/lyrics_sources_provider.dart';
import '../../../lyrics/state/translation/translation_commands.dart';
import '../../../lyrics/state/translation/translation_settings.dart';
import '../../../lyrics/ui/lyrics_settings_link.dart';
import '../../../playback/state/seek_plugin_use_provider.dart';
import '../../../plugins/state/plugin_page_provider.dart';
import '../../settings/settings_routes.dart';
import '../../settings/ui/settings_scaffold.dart';
import '../common/plugin_icon.dart';

/// The head card: icon, name, "author (tự khai báo) · bản N", and under a
/// divider the row that says how the kind is used. The lyrics row shows the
/// plugin's place in the lyrics sources and opens Settings › Lời bài; the
/// translate row says whether the plugin is the default translation service
/// and sets it; the AI chat row says where the service is chosen and opens
/// Settings › AI chat.
class PluginHeadCard extends ConsumerWidget {
  const PluginHeadCard({super.key, required this.data, required this.nameKey});

  final PluginPageData data;

  /// On the name: the page watches it to tell when it has scrolled out.
  final GlobalKey nameKey;

  static const double _icon = KIconSize.hero;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      PluginKind.lyrics => _LyricsUseRow(installId: row.installId),
      PluginKind.translate ||
      PluginKind.aiTranslate => _TranslateUseRow(installId: row.installId),
      PluginKind.aiChat => const _AiChatUseRow(),
      PluginKind.seekbar => _SeekbarUseRow(installId: row.installId),
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

/// "Tự tìm lời": whether the lyrics module asks this plugin by itself and
/// where it stands in the user's order. No switch: the order and the
/// switches live in Settings › Lời bài, which the row opens.
class _LyricsUseRow extends ConsumerWidget {
  const _LyricsUseRow({required this.installId});

  final String installId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final sources = ref.watch(lyricsSourcesProvider);
    final at = sources.indexWhere((s) => s.id == installId);
    // Until the sources are read the plugin is not in the list: no state yet.
    final String? state = at < 0
        ? null
        : sources[at].enabled
        ? l10n.pluginsPageUseLyricsOn(at + 1, sources.length)
        : l10n.pluginsPageUseLyricsOff;
    return SetupRowFrame(
      leading: const Icon(KIcons.lyrics),
      title: Text(l10n.pluginsPageUseLyrics),
      subtitle: state == null ? null : Text(state),
      trailing: Icon(KIcons.openInNew, color: scheme.onSurfaceVariant),
      onTap: () => context.push(lyricsSourcesSettingsLocation),
    );
  }
}

/// "Dịch vụ dịch mặc định": "✓ Mặc định" when this plugin is the chosen
/// service, else the button that chooses it. The choice is the same setting
/// as Settings › Lyrics › Translation and the translate modal.
class _TranslateUseRow extends ConsumerWidget {
  const _TranslateUseRow({required this.installId});

  final String installId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDefault = ref.watch(translationServiceProvider) == installId;
    return SetupRowFrame(
      leading: const Icon(KIcons.language),
      title: Text(l10n.pluginsPageUseTranslate),
      subtitle: Text(
        isDefault
            ? l10n.pluginsPageUseTranslateAt
            : l10n.pluginsPageUseTranslateHint,
      ),
      trailing: isDefault
          ? Row(
              mainAxisSize: MainAxisSize.min,
              spacing: KSpace.x1,
              children: [
                Icon(KIcons.check, size: KIconSize.xs, color: scheme.primary),
                Text(
                  l10n.pluginsPageUseTranslateIs,
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            )
          : FilledButton.tonal(
              onPressed: () =>
                  ref.read(translationCommandsProvider).setService(installId),
              child: Text(l10n.pluginsPageUseTranslateSet),
            ),
    );
  }
}

/// "Dùng trong Trò chuyện AI": the service is picked in the chat composer; the
/// row only points to Settings › AI chat, like the lyrics row.
class _AiChatUseRow extends StatelessWidget {
  const _AiChatUseRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SetupRowFrame(
      leading: const Icon(KIcons.ai),
      title: Text(l10n.aiSetPluginUse),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(l10n.aiSetPluginUseDesc), Text(l10n.aiSetPluginUseAt)],
      ),
      trailing: Icon(KIcons.openInNew, color: scheme.onSurfaceVariant),
      onTap: () => context.push(aiSettingsLocation),
    );
  }
}

/// "Dùng ở Cài đặt › Thanh tua": says whether the style is the chosen one
/// and / or holds the ★ and opens Settings › Seek bar, where it is chosen.
/// No switch: the choice lives on that page only.
class _SeekbarUseRow extends ConsumerWidget {
  const _SeekbarUseRow({required this.installId});

  final String installId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final use = ref.watch(seekPluginUseProvider(installId));
    return SetupRowFrame(
      leading: const Icon(KIcons.seekBar),
      title: Text(l10n.pluginsSkUseTitle),
      subtitle: Text(
        use.chosen && use.fallback
            ? l10n.pluginsSkUseBoth
            : use.chosen
            ? l10n.pluginsSkUseChosen
            : use.fallback
            ? l10n.pluginsSkUseFallback
            : l10n.pluginsSkUseNone,
      ),
      trailing: Icon(KIcons.openInNew, color: scheme.onSurfaceVariant),
      onTap: () => context.push(SettingsPaths.seekBar),
    );
  }
}
