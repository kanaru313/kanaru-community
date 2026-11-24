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
import 'translation_language_name.dart';

/// The "Dịch" pill of the desktop Now Playing header. Translation off: "Dịch";
/// on: the `secondaryContainer` fill; translated: the plugin's icon and the
/// language; a run going: a ring and "Đang dịch"; any failure: the red alert
/// dot on the corner; no lyrics: half transparent and inert.
///
/// A click opens "Dịch lời" through [opener]; a right click turns translation
/// on or off ([toggleTranslation]), like the `T` key.
class TranslatePill extends ConsumerWidget {
  const TranslatePill({super.key, this.opener = openTranslateModalForPlaying});

  final TranslateOpener opener;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(translateEntryProvider);
    final id = state.trackId;
    final label = translateEntryLabel(l10n, state);
    final fill = state.on && state.available
        ? scheme.secondaryContainer
        : scheme.surfaceContainerHigh;
    final ink = state.on && state.available
        ? scheme.onSecondaryContainer
        : scheme.onSurface;
    final enabled = state.available && id != null;
    Widget pill = Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: fill,
          shape: KShape.of(KRadius.full),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? () => unawaited(opener(context, id)) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KSpace.x3,
                vertical: KSpace.x2,
              ),
              child: DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: ink),
                child: _Face(state: state, ink: ink),
              ),
            ),
          ),
        ),
      ),
    );
    pill = Tooltip(
      message: [label, l10n.lyricsTranslateEntryHintDesktop].join('\n'),
      excludeFromSemantics: true,
      child: pill,
    );
    if (state.failed) pill = KAlertDot.corner(child: pill);
    if (!enabled) return Opacity(opacity: 0.5, child: pill);
    return KContextRegion(
      longPressOpens: false,
      onOpen: (_) => toggleTranslationNow(context, ref),
      child: pill,
    );
  }
}

class _Face extends ConsumerWidget {
  const _Face({required this.state, required this.ink});

  final TranslateEntryState state;
  final Color ink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final target = state.target;
    final installId = state.installId;
    final Widget lead;
    final String text;
    if (state.working) {
      lead = LyricsSpinner(size: KIconSize.xs, color: ink, strokeWidth: 2);
      text = l10n.lyricsTranslatePillWorking;
    } else if (state.translated && installId != null && target != null) {
      lead = KSourceAvatar(
        label: state.pluginName ?? '',
        size: KIconSize.xs,
        imageBytes: ref.watch(pluginIconProvider(installId)).value,
      );
      text = translationLanguageName(l10n, target);
    } else {
      lead = Icon(KIcons.language, size: KIconSize.xs, color: scheme.onSurface);
      text = l10n.playbackTranslate;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: KSpace.x1,
      children: [
        lead,
        Flexible(
          child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
