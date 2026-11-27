import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/domain/package/plugin_kind.dart';
import '../../../plugins/domain/package/seekbar_assets.dart'
    show referencedAssets;
import '../../../plugins/state/plugin_page_provider.dart';
import '../../../plugins/state/plugin_store_providers.dart';
import '../../../plugins/state/store_ops.dart';
import '../../../plugins/state/store_view_models.dart';
import '../../settings/ui/soon_row.dart';
import '../common/plugin_labels.dart';
import '../common/seekbar_facts.dart';
import '../install/source_card.dart' show formatPackageSize;
import 'details_info_row.dart';

/// "Chi tiết": label over a selectable value for where it came from, who it
/// sends data to, when it was installed, its description and its type; then,
/// after a divider, the rows of features that are not built yet.
class DetailsBlock extends ConsumerWidget {
  const DetailsBlock({super.key, required this.data});

  final PluginPageData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final repos = ref.watch(repoViewsProvider).value ?? const <RepoView>[];
    final manifest = data.manifest;
    final description = manifest?.description ?? '';
    final seekbar = data.kind == PluginKind.seekbar;
    return SetupSection(
      title: Text(l10n.pluginsPageDetails),
      children: [
        DetailsInfoRow(label: l10n.pluginsPageFrom, lines: _from(l10n, repos)),
        // A seek bar plugin has no code and sends nothing: no address row.
        if (!seekbar)
          DetailsInfoRow(
            label: l10n.pluginsPkgSendTo,
            lines: _sendTo(l10n),
            mono: true,
          ),
        DetailsInfoRow(
          label: l10n.pluginsPageInstalledAt,
          lines: [_installedAt(l10n)],
        ),
        if (description.isNotEmpty)
          DetailsInfoRow(
            label: l10n.pluginsPageDescription,
            lines: [DetailLine(description)],
          ),
        if (seekbar && manifest != null)
          DetailsInfoRow(
            label: l10n.pluginsSkFactLicense,
            lines: [DetailLine(manifest.license)],
          ),
        DetailsInfoRow(label: l10n.pluginsPageType, lines: [_type(l10n)]),
        if (seekbar && manifest?.seekbar != null)
          DetailsInfoRow(
            label: l10n.pluginsSkFactPackage,
            lines: [DetailLine(_package(l10n, ref))],
          ),
        if (!seekbar) ..._soonRows(l10n),
      ],
    );
  }

  /// "plugin.json + 1 ảnh PNG · 18 KB · không có mã"; the size is left out
  /// while it loads or when the folder cannot be read.
  String _package(AppLocalizations l10n, WidgetRef ref) {
    final files = seekbarFilesText(
      l10n,
      referencedAssets(data.manifest!.seekbar!),
    );
    final dir = data.row.packageDir;
    final bytes = dir == null
        ? null
        : ref
              .watch(
                pluginPackageBytesProvider((
                  installId: data.row.installId,
                  packageDir: dir,
                )),
              )
              .value;
    return l10n.pluginsSkPackageNoCode(
      bytes == null
          ? files
          : l10n.pluginsSkPackageSize(files, formatPackageSize(bytes)),
    );
  }

  /// The rows of features that are not built yet, after a divider.
  List<Widget> _soonRows(AppLocalizations l10n) {
    return [
      const Divider(height: 1),
      SoonRow(icon: KIcons.stats, title: Text(l10n.pluginsPkgFacts)),
      SoonRow(icon: KIcons.ai, title: Text(l10n.pluginsPkgAskAi)),
      SoonRow(icon: KIcons.openInNew, title: Text(l10n.pluginsPageSourceCode)),
    ];
  }

  List<DetailLine> _from(AppLocalizations l10n, List<RepoView> repos) {
    final label = data.originLabel ?? '';
    switch (data.origin) {
      case PluginOrigin.repo:
        final name = repos.where((r) => r.url == label).firstOrNull?.name;
        return [
          DetailLine(l10n.pluginsPageFromRepo(name ?? label)),
          DetailLine(label, mono: true, soft: true),
        ];
      case PluginOrigin.file:
        return [
          DetailLine(l10n.pluginsPageFromFile(label)),
          DetailLine(l10n.pluginsPageNoUpdatesFile, soft: true),
        ];
      case PluginOrigin.link:
        return [
          DetailLine(l10n.pluginsPageFromLink(label.split('/').last)),
          DetailLine(label, mono: true, soft: true),
          DetailLine(l10n.pluginsPageNoUpdatesLink, soft: true),
        ];
      case null:
        return const [];
    }
  }

  /// The consented hosts, one per line; a wildcard says what it covers. Then
  /// a line per address field the user fills in. The consent sentence of the
  /// install screen is not repeated here.
  List<DetailLine> _sendTo(AppLocalizations l10n) {
    final hosts = data.consentedHosts;
    final lines = [
      for (final host in hosts)
        host.startsWith('*.')
            ? DetailLine(
                l10n.pluginsPageWildcardLine(
                  l10n.pluginsPkgWildcardHost(host.substring(2)),
                  host,
                ),
              )
            : DetailLine(host, mono: true),
      for (final endpoint in data.endpoints)
        DetailLine(
          l10n.pluginsPageEndpointLine(
            endpoint.label,
            endpoint.hosts.isEmpty
                ? l10n.pluginsPageNotEntered
                : endpoint.hosts.join(', '),
          ),
        ),
    ];
    return lines.isEmpty ? [DetailLine(l10n.pluginsPkgNoHosts)] : lines;
  }

  DetailLine _installedAt(AppLocalizations l10n) {
    final installed = DateTime.fromMillisecondsSinceEpoch(data.row.installedAt);
    final updated = DateTime.fromMillisecondsSinceEpoch(data.row.updatedAt);
    final first = _dayText(l10n, installed);
    final last = _dayText(l10n, updated);
    // Written once when the plugin was never updated or both are one day.
    return DetailLine(
      first == last ? first : l10n.pluginsPageInstalledDates(first, last),
    );
  }

  String _dayText(AppLocalizations l10n, DateTime day) =>
      DateFormat('dd/MM/yyyy', l10n.localeName).format(day);

  DetailLine _type(AppLocalizations l10n) {
    final kind = kindPluginLabel(l10n, data.kind) ?? '';
    final api = data.row.apiVersion;
    final spec = data.manifest?.seekbar;
    if (data.kind == PluginKind.seekbar && spec != null) {
      return DetailLine(
        l10n.pluginsPageTypeValueSeekbar(
          kind,
          seekbarBaseTitle(l10n, spec),
          api,
        ),
      );
    }
    return DetailLine(
      data.kind == PluginKind.aiTranslate
          ? l10n.pluginsPageTypeValueAi(kind, api)
          : l10n.pluginsPageTypeValue(kind, api),
    );
  }
}
