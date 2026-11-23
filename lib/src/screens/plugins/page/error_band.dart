import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/state/alerts_provider.dart';
import '../../../plugins/state/install_ops.dart';
import '../../../plugins/state/plugin_page_provider.dart';
import '../plugin_paths.dart';
import 'repair_flow.dart';

/// The one red band under the update band, with one button. What it says,
/// first match wins: a second music source on Free ("Cần Kanaru Pro"), the
/// package folder missing or unreadable ([Cài lại], or the sentence alone for
/// a file install), a required setting with no value ([Mở cấu hình]).
class PluginErrorBand extends ConsumerStatefulWidget {
  const PluginErrorBand({
    super.key,
    required this.data,
    required this.onOpenConfig,
  });

  final PluginPageData data;

  /// Whether [data] has anything to put in the band.
  static bool applies(PluginPageData data) =>
      data.alerts.contains(PluginAlert.proRequired) ||
      data.alerts.contains(PluginAlert.packageMissing) ||
      data.alerts.contains(PluginAlert.broken) ||
      data.alerts.contains(PluginAlert.reinstallFromFile) ||
      data.alerts.contains(PluginAlert.missingRequiredConfig);

  /// [Mở cấu hình]: scrolls to the settings of the plugin.
  final VoidCallback onOpenConfig;

  @override
  ConsumerState<PluginErrorBand> createState() => _PluginErrorBandState();
}

class _PluginErrorBandState extends ConsumerState<PluginErrorBand> {
  bool _repairing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = widget.data;
    final alerts = data.alerts;
    if (alerts.contains(PluginAlert.proRequired)) {
      return KInlineNotice(
        icon: KIcons.permission,
        tone: KInlineNoticeTone.errorFilled,
        title: l10n.pluginsPkgProTitle,
        message: '',
      );
    }
    final packageBad =
        alerts.contains(PluginAlert.packageMissing) ||
        alerts.contains(PluginAlert.broken) ||
        alerts.contains(PluginAlert.reinstallFromFile);
    if (packageBad) {
      // Only a repository or link install can fetch its package again.
      final canRepair =
          data.origin == PluginOrigin.repo || data.origin == PluginOrigin.link;
      return KInlineNotice(
        icon: KIcons.warning,
        tone: KInlineNoticeTone.errorFilled,
        title: l10n.pluginsPageBrokenTitle,
        message: canRepair
            ? l10n.pluginsPageBrokenBody
            : l10n.pluginsPageBrokenBodyFile,
        actionLabel: canRepair ? l10n.pluginsPageReinstall : null,
        onAction: canRepair ? () => unawaited(_repair()) : null,
        actionBusy: _repairing,
        actionBusyLabel: l10n.pluginsPageUpdateBusy,
      );
    }
    if (alerts.contains(PluginAlert.missingRequiredConfig)) {
      return KInlineNotice(
        icon: KIcons.warning,
        tone: KInlineNoticeTone.errorFilled,
        title: l10n.pluginsPageNeedsConfigTitle(data.row.name),
        message: l10n.pluginsPageNeedsConfigBody(data.missingConfig.join(', ')),
        actionLabel: l10n.pluginsPageOpenConfig,
        onAction: widget.onOpenConfig,
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _repair() async {
    setState(() => _repairing = true);
    await repairPluginFlow(
      context,
      ref.read(installOpsProvider),
      installId: widget.data.row.installId,
      name: widget.data.row.name,
    );
    if (mounted) setState(() => _repairing = false);
  }
}

/// The red band of a plugin the server told to slow down (a 429): it says
/// when Kanaru asks again and opens the log. The page shows it in place of
/// [PluginErrorBand] and only while the pause lasts. The length in the title
/// is read once per pause (it does not count down while the page is open).
class PluginPausedBand extends StatefulWidget {
  const PluginPausedBand({
    super.key,
    required this.installId,
    required this.until,
  });

  final String installId;

  /// When the pause ends.
  final DateTime until;

  @override
  State<PluginPausedBand> createState() => _PluginPausedBandState();
}

class _PluginPausedBandState extends State<PluginPausedBand> {
  late int _minutes = _minutesOf(widget.until);

  static int _minutesOf(DateTime until) {
    final seconds = until.difference(DateTime.now()).inSeconds;
    return seconds <= 60 ? 1 : (seconds / 60).ceil();
  }

  @override
  void didUpdateWidget(PluginPausedBand old) {
    super.didUpdateWidget(old);
    if (old.until != widget.until) _minutes = _minutesOf(widget.until);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return KInlineNotice(
      icon: KIcons.warning,
      tone: KInlineNoticeTone.errorFilled,
      title: l10n.pluginsPausedTitle(_minutes),
      message: l10n.pluginsPausedBody(
        DateFormat('HH:mm').format(widget.until.toLocal()),
      ),
      actionLabel: l10n.pluginsPageLog,
      onAction: () => context.push(PluginPaths.pluginLogs(widget.installId)),
    );
  }
}
