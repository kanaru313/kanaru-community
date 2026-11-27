import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../ai/domain/loop/loop_state.dart';
import '../../../../ai/state/ai_chat_stats_provider.dart';
import '../../../../ai/state/chat_session.dart';
import 'ai_clear_history_dialog.dart';

final _log = Logger('settings.ai_history');

/// "Lịch sử trò chuyện": how many conversations are stored and their size,
/// and "Xoá tất cả cuộc trò chuyện" (disabled with none stored or while the
/// numbers load; usable when reading them failed).
class AiHistorySection extends ConsumerStatefulWidget {
  const AiHistorySection({super.key});

  @override
  ConsumerState<AiHistorySection> createState() => _AiHistorySectionState();
}

class _AiHistorySectionState extends ConsumerState<AiHistorySection> {
  /// True from the confirm until the delete ends: [Xoá] is off meanwhile.
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stats = ref.watch(aiChatStatsProvider);
    // A reload keeps showing the last numbers; loading is only "no value yet".
    final count = stats.value?.conversations;
    final canClear =
        !_deleting && (stats.hasError || (count != null && count > 0));
    return SetupSection(
      title: Text(l10n.aiSetHistTitle),
      children: [
        _StatsRow(
          conversations: count,
          bytes: stats.value?.bytes ?? 0,
          failed: stats.hasError,
        ),
        SetupRowFrame(
          leading: const Icon(KIcons.delete),
          title: Text(l10n.aiSetHistClearTitle),
          subtitle: Text(l10n.aiSetHistClearDesc),
          trailing: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: canClear ? () => _clearAll(count) : null,
            child: Text(l10n.aiSetHistClearButton),
          ),
        ),
      ],
    );
  }

  /// Asks, then deletes every conversation (the session stops a running turn
  /// and clears the run logs of the AI services). [count] is null when the
  /// numbers could not be read.
  Future<void> _clearAll(int? count) async {
    final l10n = AppLocalizations.of(context);
    // Taken before the awaits: the page may be gone when the delete ends.
    final messenger = ScaffoldMessenger.maybeOf(context);
    final session = ref.read(chatSessionProvider.notifier);
    final turn = ref.read(chatSessionProvider).turnState;
    final running =
        turn == TurnState.streaming || turn == TurnState.runningTools;
    final sentences = [
      l10n.aiSetHistDialogRemoved(
        count == null
            ? l10n.aiSetHistDialogWhatAll
            : l10n.aiSetHistDialogWhat(count),
      ),
      if (running) l10n.aiSetHistDialogStop,
      l10n.aiSetHistDialogLogs,
    ];
    final ok = await showKDialog<bool>(
      context,
      builder: (dialog) => AiClearHistoryDialog(
        title: l10n.aiSetHistDialogTitle,
        body: sentences.join(' '),
        undo: l10n.aiSetHistDialogUndo,
        confirm: l10n.aiSetHistDialogConfirm,
      ),
    );
    if (ok != true) return;
    if (mounted) setState(() => _deleting = true);
    try {
      await session.deleteAll();
    } on Object catch (e, st) {
      // Only logged: no message reaches the user (a known gap). The numbers
      // above reload from the store and show what is left.
      _log.warning('deleting all conversations failed', e, st);
      return;
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
    if (messenger != null && messenger.mounted) {
      showAppSnackBarOn(messenger, l10n.aiSetHistCleared);
    }
  }
}

/// The numbers row: reading, failed (with Retry) or the count and size.
class _StatsRow extends ConsumerWidget {
  const _StatsRow({
    required this.conversations,
    required this.bytes,
    required this.failed,
  });

  /// Null while the numbers are not read yet.
  final int? conversations;
  final int bytes;
  final bool failed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final count = conversations;
    if (count != null) {
      final locale = Localizations.localeOf(context).toString();
      return SetupRowFrame(
        leading: const Icon(KIcons.history),
        title: Text(
          count == 0
              ? l10n.aiSetHistNone
              : l10n.aiSetHistCount(count, _megabytes(bytes, locale)),
        ),
        subtitle: Text(l10n.aiSetHistWhere),
      );
    }
    if (failed) {
      return SetupRowFrame(
        leading: const Icon(KIcons.history),
        title: Text(l10n.aiSetHistErrorTitle),
        subtitle: Text(
          l10n.aiSetHistErrorDesc,
          style: TextStyle(color: scheme.error),
        ),
        trailing: TextButton(
          onPressed: () => ref.invalidate(aiChatStatsProvider),
          child: Text(l10n.aiSetHistRetry),
        ),
      );
    }
    return Semantics(
      label: l10n.aiSetHistLoading,
      child: SetupRowFrame(
        leading: const Icon(KIcons.history),
        title: Row(
          children: [
            const SizedBox.square(
              dimension: KIconSize.xs,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const KGap(KSpace.x2),
            Flexible(child: Text(l10n.aiSetHistLoading)),
          ],
        ),
      ),
    );
  }

  /// One decimal; a chat that holds anything never reads "0".
  String _megabytes(int bytes, String locale) {
    final mb = bytes / (1024 * 1024);
    final shown = bytes > 0 && mb < 0.1 ? 0.1 : mb;
    return NumberFormat('0.0', locale).format(shown);
  }
}
