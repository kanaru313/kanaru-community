import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/state/store_ops.dart' show pluginIconProvider;
import '../lyrics_spinner.dart';
import 'translate_entry_state.dart';
import 'translate_labels.dart';
import 'translate_toggle.dart';

/// The lyrics-screen header button of the mobile shell: opens "Dịch lời".
/// Translation on with a translation shown: the icon of the plugin in use (as
/// the source button shows its lyrics plugin); on without one: the icon in
/// primary; a run going: a ring instead of the icon; any failure: the red alert dot on the
/// corner; no lyrics: dimmed and inert. Only this widget watches the entry
/// state.
class TranslateButton extends ConsumerWidget {
  const TranslateButton({
    super.key,
    this.opener = openTranslateModalForPlaying,
  });

  final TranslateOpener opener;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(translateEntryProvider);
    final id = state.trackId;
    final installId = state.installId;
    final shownPlugin = state.on && state.translated && installId != null;
    final label = shownPlugin
        ? '${translateEntryLabel(l10n, state)} · ${state.pluginName ?? ''}'
        : translateEntryLabel(l10n, state);
    final face = state.working
        ? LyricsSpinner(
            size: KIconSize.md - 2,
            color: scheme.primary,
            strokeWidth: 2.5,
          )
        : shownPlugin
        ? KSourceAvatar(
            label: state.pluginName ?? '',
            size: KIconSize.md,
            imageBytes: ref.watch(pluginIconProvider(installId)).value,
          )
        : const Icon(KIcons.languages);
    return KIconButton(
      tooltip: label,
      color: state.on && state.available ? scheme.primary : null,
      onPressed: state.available && id != null
          ? () => unawaited(opener(context, id))
          : null,
      // The red dot sits on the glyph's corner, not the button's.
      child: state.failed ? KAlertDot.corner(child: face) : face,
    );
  }
}
