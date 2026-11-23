import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../playback/state/now_playing_panel.dart';
import '../../domain/online/online_search_state.dart';
import '../lyrics_settings_link.dart';
import '../online/online_labels.dart';
import '../lyrics_spinner.dart';

/// "Đang tìm trong LRCLIB…": a source that has not answered yet (or, with
/// the general label, the picker waiting for its first search).
class PickerLoadingNote extends StatelessWidget {
  const PickerLoadingNote({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KSpace.x4,
        vertical: KSpace.x3,
      ),
      child: Row(
        spacing: KSpace.x3,
        children: [
          LyricsSpinner(size: KIconSize.sm, color: scheme.onSurfaceVariant),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// A source that failed, needs setup or is paused, in one line. A source that
/// needs setup has an action that opens its plugin page: the router is taken
/// before the picker closes, because its context is gone after it pops.
class PickerFailureNote extends ConsumerWidget {
  const PickerFailureNote({
    super.key,
    required this.sourceId,
    required this.name,
    required this.part,
    required this.closePicker,
  });

  final String sourceId;
  final String name;
  final SourceSearch part;

  /// Closes the picker (and the preview over it); true when it did.
  final bool Function() closePicker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final needsConfig = part.phase == SourceSearchPhase.needsConfig;
    final message = pickerFailureMessage(context, part, name);
    final router = GoRouter.of(context);
    final panel = ref.read(nowPlayingPanelProvider.notifier);
    return KInlineNotice(
      icon: part.phase == SourceSearchPhase.paused
          ? KIcons.comingSoon
          : KIcons.offline,
      tone: needsConfig ? KInlineNoticeTone.normal : KInlineNoticeTone.error,
      message: message,
      actionLabel: needsConfig ? l10n.lyricsPickerOpenPlugin : null,
      onAction: needsConfig
          ? () {
              if (!closePicker()) return;
              // The desktop Now Playing panel would hide the page.
              panel.close();
              router.go(lyricsPluginPageLocation(sourceId));
            }
          : null,
    );
  }
}

/// The one line for a source that failed, needs setup or is paused.
String pickerFailureMessage(
  BuildContext context,
  SourceSearch part,
  String name,
) {
  final l10n = AppLocalizations.of(context);
  return switch (part.phase) {
    SourceSearchPhase.needsConfig => l10n.lyricsPickerNeedsConfig(name),
    SourceSearchPhase.paused => l10n.lyricsPickerPaused(
      name,
      part.until == null ? '' : formatClock(context, part.until!),
    ),
    _ => switch (part.failure) {
      SourceSearchFailure.server => l10n.lyricsPickerFailServer(name),
      SourceSearchFailure.rateLimited => l10n.lyricsPickerFailRateLimited(name),
      SourceSearchFailure.invalid => l10n.lyricsPickerFailInvalid(name),
      _ => l10n.lyricsPickerFailNetwork(name),
    },
  };
}
