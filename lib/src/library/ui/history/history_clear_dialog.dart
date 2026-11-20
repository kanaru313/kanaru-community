import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'package:logging/logging.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/history/history_clear_scope.dart';
import '../../state/history/history_actions.dart';
import '../../state/history/history_providers.dart';
import '../../state/history/local_day_provider.dart';
import 'history_toasts.dart';

final _log = Logger('library.history');

/// Asks which part of the history to clear ("Clear history?": last hour,
/// today, last 7 days, everything, each with its play count), clears it and
/// says so with a toast. No undo.
///
/// The counts and the delete share one `now` taken when the dialog opens, so
/// what the rows promise is what goes. The dialog stays open while the clear
/// runs (Clear shows progress, nothing closes it); the toast comes from the
/// dialog itself on the root navigator's messenger, so it shows even when the
/// dialog's route was removed meanwhile. [context] belongs to the root
/// navigator.
Future<void> showHistoryClearDialog(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final now = container.read(historyClockProvider)();
  await showKDialog<void>(
    context,
    builder: (_) => HistoryClearDialog(now: now),
  );
}

/// The "Clear history?" dialog; see [showHistoryClearDialog].
class HistoryClearDialog extends ConsumerStatefulWidget {
  const HistoryClearDialog({super.key, required this.now});

  /// The moment every option's bounds and count are taken from.
  final DateTime now;

  @override
  ConsumerState<HistoryClearDialog> createState() => _HistoryClearDialogState();
}

class _HistoryClearDialogState extends ConsumerState<HistoryClearDialog> {
  Map<ClearScope, int>? _counts;
  bool _countFailed = false;
  ClearScope? _picked;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _countFailed = false);
    try {
      final counts = await ref.read(historyActionsProvider).counts(widget.now);
      if (mounted) setState(() => _counts = counts);
    } on Object catch (e) {
      _log.warning('Counting the plays to clear failed: ${e.runtimeType}');
      // A count that cannot be read leaves nothing to clear: Retry reads it
      // again.
      if (mounted) setState(() => _countFailed = true);
    }
  }

  Future<void> _clear() async {
    final scope = _picked;
    if (scope == null || _busy) return;
    // Taken before the await: the toast must not depend on this dialog (its
    // route can be removed from outside while the clear runs).
    final messenger = ScaffoldMessenger.of(
      Navigator.of(context, rootNavigator: true).context,
    );
    final l10n = AppLocalizations.of(context);
    final actions = ref.read(historyActionsProvider);
    setState(() => _busy = true);
    int? removed;
    try {
      removed = await actions.clear(scope, widget.now);
    } on Object catch (e) {
      _log.warning('Clearing the history threw: ${e.runtimeType}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    showHistoryClearedToast(messenger, l10n, removed);
    if (mounted) Navigator.of(context).pop();
  }

  String _label(AppLocalizations l10n, ClearScope scope) => switch (scope) {
    ClearScope.hour => l10n.historyClearHour,
    ClearScope.today => l10n.historyClearToday,
    ClearScope.week => l10n.historyClearWeek,
    ClearScope.all => l10n.historyClearAll,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final clearing = ref.watch(historyClearingProvider);
    final counts = _counts;
    final picked = _picked;
    final canClear =
        !_busy &&
        !clearing &&
        counts != null &&
        picked != null &&
        (counts[picked] ?? 0) > 0;
    return PopScope(
      // A clear in flight cannot be taken back: Esc, Back and the scrim wait.
      canPop: !_busy,
      child: AlertDialog(
        title: Text(l10n.historyClearTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final scope in ClearScope.values)
                SelectionRow(
                  title: Text(_label(l10n, scope)),
                  subtitle: counts == null
                      ? null
                      : Text(l10n.historyHeroPlays(counts[scope] ?? 0)),
                  selected: picked == scope,
                  enabled: !_busy,
                  onTap: () => setState(() => _picked = scope),
                ),
              if (_countFailed) ...[
                const SizedBox(height: KSpace.x2),
                Text(
                  l10n.historyClearCountFailed,
                  style: TextStyle(color: scheme.error),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () => unawaited(_load()),
                    child: Text(l10n.historyClearRetry),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: canClear ? () => unawaited(_clear()) : null,
            child: _busy
                ? Semantics(
                    label: l10n.historyClearConfirm,
                    child: const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Text(l10n.historyClearConfirm),
          ),
        ],
      ),
    );
  }
}
