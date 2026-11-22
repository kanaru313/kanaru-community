import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/state/updates_provider.dart';
import '../store/store_actions.dart';

/// The text button at the head of the Cập nhật block: "Cập nhật tất cả (n)",
/// and while the run goes "Đang cập nhật i / n…" (locked). Nothing when no
/// update is left to run.
class UpdateAllButton extends ConsumerWidget {
  const UpdateAllButton({
    super.key,
    required this.count,
    required this.actions,
  });

  /// Updates that "Cập nhật tất cả" would install now.
  final int count;
  final StoreActions actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(updateAllStateProvider);
    if (state.running) {
      final shown = state.total == 0
          ? 0
          : (state.done + 1).clamp(1, state.total);
      return TextButton(
        onPressed: null,
        child: Text(l10n.pluginsUpdateAllRunning(shown, state.total)),
      );
    }
    if (count == 0) return const SizedBox.shrink();
    return TextButton(
      onPressed: actions.onUpdateAll == null
          ? null
          : () => actions.onUpdateAll!(context),
      child: Text(l10n.pluginsUpdateAll(count)),
    );
  }
}
