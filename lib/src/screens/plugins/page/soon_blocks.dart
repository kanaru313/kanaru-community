import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/domain/package/plugin_kind.dart';
import '../../settings/ui/soon_row.dart';

/// "Kết nối": the two limits of requests, dimmed "Sắp có" until the plugin
/// runtime reads them.
class ConnectionBlock extends StatelessWidget {
  const ConnectionBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SetupSection(
      title: Text(l10n.pluginsPageConnection),
      children: [
        SoonRow(icon: KIcons.bolt, title: Text(l10n.pluginsPageConcurrent)),
        SoonRow(icon: KIcons.duration, title: Text(l10n.pluginsPageSpacing)),
      ],
    );
  }
}

/// "Dữ liệu": what the plugin keeps, dimmed "Sắp có" until there is data to
/// show and delete. The saved-lyrics row is for lyrics plugins, the track
/// cache for music sources.
class DataBlock extends StatelessWidget {
  const DataBlock({super.key, required this.kind});

  final PluginKind? kind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SetupSection(
      title: Text(l10n.pluginsPageData),
      children: [
        SoonRow(
          icon: KIcons.dataStorage,
          title: Text(l10n.pluginsPageOwnStorage),
        ),
        if (kind == PluginKind.lyrics)
          SoonRow(
            icon: KIcons.lyrics,
            title: Text(l10n.pluginsPageSavedLyrics),
          ),
        if (kind == PluginKind.streaming)
          SoonRow(
            icon: KIcons.musicFile,
            title: Text(l10n.pluginsPageTrackCache),
          ),
        SoonRow(icon: KIcons.pluginLogs, title: Text(l10n.pluginsPageLog)),
      ],
    );
  }
}
