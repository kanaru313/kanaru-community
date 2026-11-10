import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/scan_status.dart';
import '../../state/scan/scan_capabilities.dart';
import '../../state/scan_providers.dart';
import 'scan_card_state.dart';

/// The library scan card at the top of Home: progress while tags and covers
/// are read, then a short summary that hides itself. Shows nothing while the
/// status is loading, failed to load, idle, listing or stale. A scan that
/// failed is not shown here (no design for it yet).
class ScanProgressCard extends ConsumerStatefulWidget {
  const ScanProgressCard({super.key, this.now = DateTime.now});

  /// The clock for the freshness check; tests pass their own.
  final DateTime Function() now;

  @override
  ConsumerState<ScanProgressCard> createState() => _ScanProgressCardState();
}

class _ScanProgressCardState extends ConsumerState<ScanProgressCard> {
  Timer? _hideTimer;

  /// The announcement the timer was started for, and the one already hidden.
  ScanFinished? _timed, _hidden;

  @override
  void initState() {
    super.initState();
    ref.listenManual(
      scanStatusProvider,
      (_, next) => _track(next.value),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  /// Whether the scan that just finished was asked for by a caller.
  bool _announceEmpty() {
    final Object commands = ref.read(libraryScanCommandsProvider);
    return commands is ScanOrigin && commands.lastFinishWasRequested;
  }

  /// Starts the hide timer once per announcement.
  void _track(ScanStatus? status) {
    final now = widget.now();
    final finished = finishedOf(
      scanCardStateOf(status, now, announceEmpty: _announceEmpty()),
    );
    if (finished == null || identical(finished, _timed)) return;
    _hideTimer?.cancel();
    _timed = finished;
    final left = scanSummaryFreshness - now.difference(finished.at);
    final wait = left < scanSummaryVisible ? left : scanSummaryVisible;
    _hideTimer = Timer(wait, () {
      if (!mounted) return;
      setState(() => _hidden = finished);
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(scanStatusProvider).value;
    final state = scanCardStateOf(
      status,
      widget.now(),
      announceEmpty: _announceEmpty(),
    );
    final l10n = AppLocalizations.of(context);
    final Widget card;
    switch (state) {
      case ScanCardHidden():
        return const SizedBox.shrink();
      case ScanCardProgress(:final done, :final total, :final progress):
        card = ProgressNoticeCard(
          icon: KIcons.rescan,
          title: Text(l10n.scanHomeScanning),
          subtitle: Text(l10n.scanHomeProgress(done, total)),
          progress: progress,
        );
      case ScanCardAdded(
        :final finished,
        :final added,
        :final albums,
        :final artists,
      ):
        if (identical(finished, _hidden)) return const SizedBox.shrink();
        card = ProgressNoticeCard(
          icon: KIcons.select,
          title: Text(l10n.scanHomeAdded(added)),
          subtitle: Text(l10n.scanHomeAddedDetail(albums, artists)),
          showBar: false,
        );
      case ScanCardNoTracks(:final finished):
        if (identical(finished, _hidden)) return const SizedBox.shrink();
        card = ProgressNoticeCard(
          icon: KIcons.folderOff,
          title: Text(l10n.scanHomeNoTracks),
          showBar: false,
        );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: KSpace.x3),
      child: card,
    );
  }
}
