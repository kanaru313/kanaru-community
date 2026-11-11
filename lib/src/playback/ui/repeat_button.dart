import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart' hide RepeatMode;

import '../../../l10n/gen/app_localizations.dart';
import '../domain/repeat_mode.dart';
import '../state/playback_providers.dart';
import '../state/playback_settings_providers.dart';
import '../state/queue_view_provider.dart';
import 'repeat_menu.dart';

/// The repeat button: opens the repeat menu; its icon and tooltip show the
/// active mode and, under a counted repeat, the plays left. Lit (primary
/// colour and dot) unless the queue stops at its end; disabled while the queue
/// is empty. It watches the repeat fields only, so playback progress does not
/// rebuild it.
class RepeatButton extends ConsumerStatefulWidget {
  const RepeatButton({super.key});

  @override
  ConsumerState<RepeatButton> createState() => _RepeatButtonState();
}

class _RepeatButtonState extends ConsumerState<RepeatButton> {
  final _menu = MenuController();

  /// Number the counted row arms with while no count runs.
  int _draft = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final storedMode = ref.watch(repeatSettingProvider);
    final (empty, viewMode, times, stopped) = ref.watch(
      queueViewProvider.select((v) {
        final q = v.value;
        return (
          q == null || q.length == 0,
          q?.repeat,
          q?.repeatTimes ?? 0,
          q?.stopped ?? true,
        );
      }),
    );
    final mode = viewMode ?? storedMode;
    final counting = !empty && times > 0;
    if (empty && _menu.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _menu.isOpen) _menu.close();
      });
    }

    return MenuAnchor(
      controller: _menu,
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHighest),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      menuChildren: [
        RepeatMenuRows(
          mode: mode,
          times: counting ? times : 0,
          stopped: stopped || empty,
          draft: _draft,
          onMode: (m) {
            _menu.close();
            ref.read(playerControllerProvider).setRepeat(m);
          },
          onCount: (n) {
            if (empty) return;
            _menu.close();
            ref.read(playerControllerProvider).setRepeatTimes(n);
          },
          onStep: (n) {
            if (empty) return;
            if (counting) {
              ref.read(playerControllerProvider).setRepeatTimes(n);
            } else {
              setState(() => _draft = n);
            }
          },
        ),
      ],
      builder: (context, controller, _) => KToggleIconButton(
        iconWidget: KRepeatIcon(
          glyph: counting ? KRepeatGlyph.counted : repeatGlyph(mode),
          count: counting ? times : 0,
        ),
        active: counting || mode != RepeatMode.off,
        tooltip: repeatLabel(l10n, mode, counting ? times : 0),
        onPressed: empty
            ? null
            : () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}
