import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/domain/install/held_package.dart';
import '../../../plugins/domain/package/plugin_kind.dart';
import '../../../plugins/domain/package/plugin_manifest.dart';
import '../../settings/ui/soon_row.dart';
import '../common/hosts_block.dart';
import 'package_controller.dart';
import 'package_band.dart';
import 'install_progress.dart';
import 'seekbar_facts_block.dart';
import 'source_card.dart';

/// The scrolling body of the install / update screen, by phase.
class PackageBody extends StatelessWidget {
  const PackageBody({super.key, required this.controller});

  final PackageController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = controller;
    final held = c.held;
    final notice = c.notice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KSpace.x4,
      children: [
        if (notice != null)
          KInlineNotice(
            icon: KIcons.info,
            message: notice == PackageNotice.stale
                ? l10n.pluginsPkgNoticeStale
                : l10n.pluginsPkgNoticeExpired,
          ),
        if (held != null)
          SourceCard(source: held.source, size: held.package.size),
        if (c.proBlocked)
          KInlineNotice(
            icon: KIcons.permission,
            tone: KInlineNoticeTone.errorFilled,
            title: l10n.pluginsPkgProTitle,
            message: l10n.pluginsFreeStreamingLimit,
          ),
        if (c.phase == PackagePhase.loading)
          InstallProgress(progress: c.progress, kind: c.subject.kind),
        if (c.phase == PackagePhase.failed)
          PackageErrorBand(
            prepareFailure: c.prepareFailure,
            writeFailure: c.writeFailure,
            onRetry: c.prepare,
          ),
        if (held != null && c.phase != PackagePhase.failed)
          ..._package(context, held),
      ],
    );
  }

  List<Widget> _package(BuildContext context, HeldPackage held) {
    final l10n = AppLocalizations.of(context);
    final manifest = held.package.manifest;
    final review = held.review;
    final update = review is UpdateReview;
    final newHosts = update ? review.diff.newHosts : const <String>[];
    final fixed = [
      for (final host in manifest.hosts)
        if (!newHosts.contains(host)) host,
    ];
    final seekbar = manifest.kind == PluginKind.seekbar;
    return [
      if (!update && manifest.description.isNotEmpty)
        Text(
          manifest.description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      HostsBlock(
        hosts: fixed,
        newHosts: newHosts,
        endpointFields: _endpointLabels(manifest),
        consent: update
            ? (newHosts.isEmpty ? HostsConsent.none : HostsConsent.update)
            : HostsConsent.install,
        // A seek bar package has no code and no addresses: say so.
        emptyLine: seekbar ? l10n.pluginsPkgNoData : null,
      ),
      if (seekbar)
        SeekbarFactsBlock(package: held.package)
      else
        _SoonRows(
          facts: update ? l10n.pluginsPkgFactsUpdate : l10n.pluginsPkgFacts,
          ask: update ? l10n.pluginsPkgAskAiUpdate : l10n.pluginsPkgAskAi,
        ),
    ];
  }

  static List<String> _endpointLabels(PluginManifest manifest) => [
    for (final field in manifest.userEndpointFields)
      field.title.isEmpty ? field.key : field.title,
  ];
}

/// The two parts that come later (static facts, ask the AI), shown dimmed.
class _SoonRows extends StatelessWidget {
  const _SoonRows({required this.facts, required this.ask});

  final String facts;
  final String ask;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SoonRow(icon: KIcons.stats, title: Text(facts)),
        SoonRow(icon: KIcons.ai, title: Text(ask)),
      ],
    );
  }
}
