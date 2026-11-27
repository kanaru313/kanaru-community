import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../ai/state/ai_settings_providers.dart';

final _log = Logger('settings.ai_confirm');

/// "Hộp xác nhận": one row with a button that turns the "Bật Tự động?" question
/// back on. The page shows the block only while `ai.auto_ask` is off, so
/// turning it on removes the block.
class AiConfirmSection extends ConsumerWidget {
  const AiConfirmSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return SetupSection(
      title: Text(l10n.aiSetConfirmTitle),
      children: [
        SetupRowFrame(
          leading: const Icon(KIcons.bolt),
          title: Text(l10n.aiSetConfirmRow),
          subtitle: Text(l10n.aiSetConfirmDesc),
          trailing: FilledButton.tonal(
            onPressed: () => _turnOn(context, ref),
            child: Text(l10n.aiSetConfirmOn),
          ),
        ),
      ],
    );
  }

  Future<void> _turnOn(BuildContext context, WidgetRef ref) async {
    final message = AppLocalizations.of(context).aiSetConfirmToast;
    // Taken before the await: the block (and this context) goes away when
    // the setting turns on.
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await ref.read(aiAutoAskProvider.notifier).set(true);
    } on Object catch (e, st) {
      // The settings store reports a failing write on the page banner.
      _log.warning('saving ai.auto_ask failed', e, st);
      return;
    }
    if (messenger != null && messenger.mounted) {
      showAppSnackBarOn(messenger, message);
    }
  }
}
