import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../state/history/history_actions.dart';
import '../../state/history/history_providers.dart';
import '../browse/library_list_scaffold.dart';

/// How long [HistoryCollapse] takes; none when the platform asks for reduced
/// motion.
Duration historyCollapseDuration(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : KMotion.normal;

/// Shows [child] while [show], and folds it away (fade and shrink) when it
/// turns false. Nothing stays in the tree afterwards.
class HistoryCollapse extends StatelessWidget {
  const HistoryCollapse({super.key, required this.show, required this.child});

  final bool show;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = historyCollapseDuration(context);
    // An animated size with no time to run re-dirties itself in layout.
    if (duration == Duration.zero) {
      final shown = show ? child : const SizedBox.shrink();
      return shown;
    }
    return AnimatedSize(
      duration: duration,
      curve: KMotion.emphasized,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: KMotion.emphasized,
        switchOutCurve: KMotion.emphasized,
        child: show
            ? child
            : const SizedBox(
                key: ValueKey('collapsed'),
                width: double.infinity,
              ),
      ),
    );
  }
}

/// "History recording is off" strip above the hero, with a Turn on action
/// that switches recording back on, folds the strip away and says so in a
/// toast. Nothing while recording is on.
class HistoryRecordingNotice extends ConsumerWidget {
  const HistoryRecordingNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final off = !ref.watch(historyRecordingProvider);
    return HistoryCollapse(
      show: off,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          libraryGutter(context),
          0,
          libraryGutter(context),
          KSpace.x3,
        ),
        child: KInlineNotice(
          icon: KIcons.historyOff,
          message: l10n.historyRecordingOff,
          actionLabel: l10n.historyRecordingOn,
          actionSemanticsLabel: l10n.historyRecordingOnLabel,
          onAction: () => unawaited(_enable(context, ref, l10n)),
        ),
      ),
    );
  }

  Future<void> _enable(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(historyActionsProvider).enableRecording();
      if (messenger.mounted) {
        showAppSnackBarOn(messenger, l10n.historyRecordingEnabled);
      }
    } on Object {
      if (messenger.mounted) {
        showAppSnackBarOn(messenger, l10n.historyWriteFailed);
      }
    }
  }
}
