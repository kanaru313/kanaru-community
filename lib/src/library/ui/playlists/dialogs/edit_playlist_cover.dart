import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/playlists/playlist_models.dart';
import '../../../state/covers/cover_draft.dart';
import '../../../state/custom_cover_providers.dart';
import '../../covers/pick_custom_cover.dart';
import '../../playlist_common/playlist_cover.dart';
import 'playlist_form_model.dart';

/// Cover part of the Edit form: a live preview, [Change cover…], and either
/// [Automatic cover] (a custom cover exists: stages its removal until Save)
/// or the plain statement that the automatic cover is in use.
///
/// Nothing is written here: [form] only records the staged change (an
/// automatic cover, or the draft the cover dialog returned in form mode); the
/// dialog's Save applies it and Cancel drops it.
class PlaylistCoverEditor extends ConsumerWidget {
  const PlaylistCoverEditor({
    super.key,
    required this.summary,
    required this.form,
    required this.dimension,
    this.enabled = true,
  });

  final PlaylistSummary summary;

  /// Holds the staged cover change.
  final PlaylistFormModel form;

  /// Preview side: 200 on desktop, 120 on mobile.
  final double dimension;

  /// False while the dialog saves.
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final custom = ref.watch(
      customCoverKeyProvider((
        kind: CustomCoverKind.playlist,
        itemKey: summary.uid,
      )),
    );
    return ValueListenableBuilder<FormCoverEdit>(
      valueListenable: form.coverEdit,
      builder: (context, edit, _) {
        final draft = edit is ChoiceFormCover ? edit.draft : null;
        final file = draft?.displayFile;
        // An image is staged, or the automatic cover is (chosen or picked).
        final staged =
            edit is AutomaticFormCover || (draft?.isAutomatic ?? false);
        final hasCustom = custom.value != null || file != null;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (file != null)
              ExcludeSemantics(child: _StagedImage(file, dimension))
            else
              PlaylistCover(
                uid: summary.uid,
                autoCoverKeys: summary.autoCoverKeys,
                dimension: dimension,
                automaticOnly: staged,
              ),
            const KGap(KSpace.x3),
            FilledButton.tonalIcon(
              onPressed: !enabled ? null : () => _choose(context, draft),
              icon: const Icon(KIcons.image),
              label: Text(l10n.playlistCoverChoose),
            ),
            if (hasCustom && !staged)
              TextButton(
                onPressed: enabled
                    ? () => form.stageCover(const FormCoverEdit.automatic())
                    : null,
                child: Text(l10n.playlistCoverAuto),
              )
            else if (!custom.isLoading)
              // State, not a hint: which cover the playlist uses. The longer
              // explanation is only a screen-reader hint.
              Padding(
                padding: const EdgeInsets.only(top: KSpace.x2),
                child: Semantics(
                  hint: l10n.playlistCoverAutoHint,
                  child: Text(
                    l10n.playlistCoverUsingAuto,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Opens the cover dialog in form mode on the staged draft and stages what
  /// it returns; null (cancelled) changes nothing.
  Future<void> _choose(BuildContext context, CoverDraft? draft) async {
    final picked = await pickCoverForForm(
      context,
      CustomCoverKind.playlist,
      summary.uid,
      draft: draft,
    );
    if (picked == null) return;
    // Back on the stored cover: nothing stays pending.
    form.stageCover(
      picked.keepsStored
          ? const FormCoverEdit.keep()
          : FormCoverEdit.choice(picked),
    );
  }
}

/// The staged image, cut square the way a cover is shown.
class _StagedImage extends StatelessWidget {
  const _StagedImage(this.file, this.dimension);

  final File file;
  final double dimension;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: KRadius.sm,
    child: Image.file(
      file,
      width: dimension,
      height: dimension,
      fit: BoxFit.cover,
      // A missing preview file leaves the empty tile, never an error box.
      errorBuilder: (_, _, _) => SizedBox.square(dimension: dimension),
    ),
  );
}
