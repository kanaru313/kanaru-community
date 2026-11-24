import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../lyrics_spinner.dart';
import 'translate_entry_state.dart';
import 'translate_labels.dart';
import 'translate_toggle.dart';

/// Size of the dot under the icon while translation is on.
const double _onDot = 6;

/// The lyrics-screen header button of the mobile shell: opens "Dịch lời".
/// Translation on: icon in primary with a 6 dp primary dot under it; a run
/// going: a ring instead of the icon; any failure: the red alert dot on the
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
    final label = translateEntryLabel(l10n, state);
    final button = KIconButton(
      tooltip: label,
      color: state.on && state.available ? scheme.primary : null,
      onPressed: state.available && id != null
          ? () => unawaited(opener(context, id))
          : null,
      child: state.working
          ? LyricsSpinner(
              size: KIconSize.md - 2,
              color: scheme.primary,
              strokeWidth: 2.5,
            )
          : _Glyph(dot: state.on && state.available),
    );
    return state.failed ? KAlertDot.corner(child: button) : button;
  }
}

/// The translate icon, with the "on" dot under it when [dot].
class _Glyph extends StatelessWidget {
  const _Glyph({required this.dot});

  final bool dot;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: KIconSize.md,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const Icon(KIcons.languages),
          if (dot)
            Positioned(
              bottom: -(_onDot / 2 + 2),
              child: ExcludeSemantics(
                child: SizedBox.square(
                  dimension: _onDot,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
