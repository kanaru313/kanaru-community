import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/domain/install/install_result.dart';
import '../../../plugins/state/install_ops.dart';
import '../../../plugins/state/plugin_page_provider.dart';
import '../../../plugins/state/store_ops.dart';
import '../install/package_flow.dart';
import '../updates/refresh_offers.dart';
import '../updates/update_actions.dart';
import '../updates/update_failures.dart';

/// "Có bản mới bản N" and its one button: [Cập nhật] updates in place (a
/// spinner while this plugin is being updated from anywhere), [Xem bản cập
/// nhật] opens the update screen when the new version adds hosts, and after
/// an update that found the package different from the list the button
/// becomes [Làm mới danh sách] (it refreshes the repository, nothing else).
/// Nothing for a plugin with no newer version, one installed from a file or
/// link, or whose repository was removed.
class UpdateBand extends ConsumerStatefulWidget {
  const UpdateBand({super.key, required this.data});

  final PluginPageData data;

  @override
  ConsumerState<UpdateBand> createState() => _UpdateBandState();
}

class _UpdateBandState extends ConsumerState<UpdateBand> {
  bool _running = false;

  @override
  Widget build(BuildContext context) {
    final update = widget.data.update;
    if (update == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final busy = _running || widget.data.updating;
    final offerRefresh = ref
        .watch(refreshOffersProvider)
        .contains(widget.data.row.installId);
    final hosts = update.newHosts;
    final String? message;
    final String label;
    final VoidCallback action;
    if (update.needsReview) {
      message = hosts.isEmpty
          ? l10n.pluginsPageReviewBodyAny
          : l10n.pluginsPageReviewBody(hosts.join(', '));
      label = l10n.pluginsPageReviewButton;
      action = _review;
    } else if (offerRefresh) {
      message = null;
      label = l10n.pluginsPageRefreshList;
      action = () => unawaited(_refresh(update.repoId));
    } else {
      message = null;
      label = l10n.pluginsUpdate;
      action = () => unawaited(_update());
    }
    return KInlineNotice(
      icon: KIcons.download,
      tone: KInlineNoticeTone.primaryFilled,
      title: l10n.pluginsPageUpdateTitle(update.version),
      message: message ?? '',
      actionLabel: label,
      onAction: action,
      actionBusy: busy,
      prominentAction: true,
      actionBusyLabel: l10n.pluginsPageUpdateBusy,
    );
  }

  void _review() => unawaited(
    reviewPluginUpdate(
      context,
      ref.read(installOpsProvider),
      installId: widget.data.row.installId,
      name: widget.data.row.name,
    ),
  );

  Future<void> _update() async {
    final offers = ref.read(refreshOffersProvider.notifier);
    final installId = widget.data.row.installId;
    setState(() => _running = true);
    final result = await updatePlugin(
      context,
      ref.read(installOpsProvider),
      ref.read(updateFailuresProvider.notifier),
      installId: widget.data.row.installId,
      name: widget.data.row.name,
    );
    // Only a package that differs from the list is cured by a refresh. Kept
    // even when the page was left meanwhile.
    if (result is InstallRefused &&
        result.failure == InstallFailure.catalogMismatch) {
      offers.offer(installId);
    }
    if (!mounted) return;
    setState(() => _running = false);
  }

  Future<void> _refresh(int repoId) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context).pluginsPageRefreshFailed;
    final offers = ref.read(refreshOffersProvider.notifier);
    final installId = widget.data.row.installId;
    setState(() => _running = true);
    final result = await ref.read(storeOpsProvider).refresh(repoId);
    final ok = result != null && result.error == null;
    if (ok) {
      offers.clear(installId);
    } else {
      showAppSnackBarOn(messenger, failed);
    }
    if (!mounted) return;
    setState(() => _running = false);
  }
}
