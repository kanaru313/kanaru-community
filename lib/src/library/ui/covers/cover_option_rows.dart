import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../state/covers/cover_dialog_options.dart';
import '../../state/covers/cover_dialog_state.dart';
import '../../state/custom_cover_providers.dart';
import 'cover_art.dart';
import 'cover_row_parts.dart';

/// Side of the row thumbs.
const double _thumb = 48;

/// The choices of the cover dialog: Automatic, the current custom image, the
/// picked image, the album suggestions and the pick-from-device action. Rows
/// are `SelectionRow`s of pictures that look alike; they ignore taps while a
/// save runs.
class CoverOptionRows extends StatelessWidget {
  const CoverOptionRows({
    super.key,
    required this.kind,
    required this.itemKey,
    required this.state,
    required this.onSelect,
    required this.onPick,
  });

  final CustomCoverKind kind;
  final String itemKey;
  final CoverDialogState state;
  final ValueChanged<String> onSelect;
  final VoidCallback onPick;

  bool get _round => kind == CustomCoverKind.artist;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = state.options.value;
    if (options == null) {
      if (state.options.hasError) return CoverMessage(l10n.coverErrorRead);
      return Column(
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.all(KSpace.x3),
              child: Align(
                alignment: Alignment.centerLeft,
                child: KCover.loading(
                  size: _thumb,
                  radius: coverThumbRadius,
                  circle: _round,
                ),
              ),
            ),
        ],
      );
    }
    final picked = state.picked;
    final groupTitle = switch (kind) {
      CustomCoverKind.artist => l10n.coverGroupArtistAlbums,
      _ => l10n.coverGroupPlaylistAlbums,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _row(
          CoverRowIds.automatic,
          title: Row(
            children: [
              Flexible(child: CoverText(l10n.coverAutoTitle)),
              const KGap(KSpace.x2),
              CoverPill(l10n.coverDefaultPill),
            ],
          ),
          subtitle: switch (kind) {
            CustomCoverKind.album => l10n.coverAutoAlbum,
            CustomCoverKind.artist => l10n.coverAutoArtist,
            CustomCoverKind.playlist => l10n.coverAutoPlaylist,
          },
          art: AutomaticCoverArt(
            kind: kind,
            itemKey: itemKey,
            options: options,
            dimension: _thumb,
            radius: coverThumbRadius,
          ),
        ),
        if (options.current != null)
          _row(
            CoverRowIds.current,
            title: CoverText(l10n.coverCurrentTitle),
            subtitle: l10n.coverCurrentSubtitle,
            art: _file(options.current!.thumb, itemKey),
          ),
        if (picked != null)
          _row(
            CoverRowIds.picked,
            enabled: !picked.reading,
            title: CoverText(
              picked.image.nameIsGenerated
                  ? l10n.coverPickedGeneratedName
                  : picked.image.name,
            ),
            subtitle: picked.preview == null
                ? l10n.coverPickedReading
                : l10n.coverPickedSubtitle(
                    picked.preview!.width,
                    picked.preview!.height,
                  ),
            art: picked.preview == null
                ? const SizedBox.square(
                    dimension: _thumb,
                    child: Center(
                      child: SizedBox.square(
                        dimension: KIconSize.md,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : _file(picked.preview!.file, itemKey),
          ),
        if (options.suggestions.isNotEmpty) ...[
          CoverGroupTitle(groupTitle),
          for (final s in options.suggestions)
            _row(
              s.rowId,
              title: CoverText(s.title),
              subtitle: s.year == null
                  ? l10n.coverAlbumSubtitle
                  : l10n.coverAlbumSubtitleYear(s.year!),
              art: _file(s.thumb, s.title),
            ),
        ],
        CoverGroupTitle(l10n.coverGroupOther),
        KListRow(
          leading: const Icon(KIcons.imageAdd, size: KIconSize.md),
          title: Text(
            FormFactor.of(context) == FormFactor.mobile
                ? l10n.coverPickMobile
                : l10n.coverPickDesktop,
          ),
          enabled: !state.saving,
          onTap: onPick,
        ),
      ],
    );
  }

  Widget _file(File file, String seed) => FileCoverArt(
    file: file,
    seed: seed,
    dimension: _thumb,
    radius: coverThumbRadius,
    circle: _round,
  );

  Widget _row(
    String id, {
    required Widget title,
    required String subtitle,
    required Widget art,
    bool enabled = true,
  }) => SelectionRow(
    selected: state.selectedId == id,
    enabled: enabled,
    alikeOptions: true,
    leading: art,
    title: title,
    subtitle: CoverText(subtitle),
    onTap: state.saving ? null : () => onSelect(id),
  );
}
