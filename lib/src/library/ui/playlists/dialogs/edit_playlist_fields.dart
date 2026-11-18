import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/playlists/playlist_text_rules.dart';

/// The Name field of every playlist form: counter `n / 200` on the cleaned
/// text, and an error under the field (never replaced by a hint: it is state)
/// when the name is empty or too long.
class PlaylistNameField extends StatelessWidget {
  const PlaylistNameField({
    super.key,
    required this.controller,
    this.autofocus = false,
    this.enabled = true,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool autofocus;
  final bool enabled;
  final TextInputAction textInputAction;

  /// Enter. Not called for a name that fails validation.
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final problem = checkPlaylistName(value.text);
        return TextField(
          controller: controller,
          autofocus: autofocus,
          enabled: enabled,
          textInputAction: textInputAction,
          onSubmitted: (_) {
            if (problem == null) onSubmitted?.call();
          },
          decoration: InputDecoration(
            labelText: l10n.playlistNameLabel,
            counterText: l10n.plScreensCharCount(
              graphemeLength(cleanPlaylistName(value.text)),
              playlistNameMaxLength,
            ),
            errorText: switch (problem) {
              PlaylistNameProblem.empty => l10n.playlistNameEmpty,
              PlaylistNameProblem.tooLong => l10n.playlistNameTooLong,
              null => null,
            },
          ),
        );
      },
    );
  }
}

/// The multi-line Description field of the Edit form: keeps line breaks,
/// counter `n / 2000`, error when too long.
class PlaylistDescriptionField extends StatelessWidget {
  const PlaylistDescriptionField({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          enabled: enabled,
          minLines: 3,
          maxLines: 6,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            labelText: l10n.playlistDescriptionLabel,
            hintText: l10n.playlistDescriptionHint,
            alignLabelWithHint: true,
            counterText: l10n.plScreensCharCount(
              graphemeLength(cleanPlaylistDescription(value.text)),
              playlistDescriptionMaxLength,
            ),
            errorText: isPlaylistDescriptionTooLong(value.text)
                ? l10n.playlistDescriptionTooLong
                : null,
          ),
        );
      },
    );
  }
}
