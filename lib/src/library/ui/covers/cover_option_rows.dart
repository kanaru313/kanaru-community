import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../state/covers/cover_dialog_options.dart';
import '../../state/covers/cover_dialog_state.dart';
import '../../state/covers/cover_draft.dart';
import '../../state/custom_cover_providers.dart';
import '../songs/song_row_placeholder.dart';
import 'cover_art.dart';
import 'cover_row_parts.dart';

/// Side of the row thumbs.
/// The library row's cover, so a picker row is the same size.
const double _thumb = KMediaCard.coverSize;

/// Album suggestion rows shown before "Xem thêm".
const int coverCollapsedSuggestionRows = 4;

/// Skeleton rows shown while the options are read.
const int coverLoadingRows = 3;

/// The choices of the cover dialog as one sliver: Automatic, the current
/// custom image, the picked image, the album suggestions and the
/// pick-from-device action. Rows are `SelectionRow`s of pictures that look
/// alike; they ignore taps while a save runs. The suggestions are a lazy
/// sliver list (rows and their thumbs are built when scrolled near), showing
/// the first [coverCollapsedSuggestionRows] until [suggestionsExpanded].
class CoverOptionRows extends StatelessWidget {
  const CoverOptionRows({
    super.key,
    required this.kind,
    required this.itemKey,
    required this.state,
    required this.suggestionsExpanded,
    required this.onToggleSuggestions,
    required this.onSelect,
    required this.onRetry,
  });

  final CustomCoverKind kind;
  final String itemKey;
  final CoverDialogState state;
  final bool suggestionsExpanded;
  final VoidCallback onToggleSuggestions;
  final ValueChanged<String> onSelect;

  /// Reads the options again after they failed to load.
  final VoidCallback onRetry;

  bool get _round => kind == CustomCoverKind.artist;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = state.options.value;
    if (options == null) {
      // Same states as the library lists: skeleton rows while reading, the
      // inline "could not load" row with Retry when it failed.
      if (state.options.hasError) {
        return SliverToBoxAdapter(
          child: SongRowFailed(
            extent: KMediaCard.extentOf(MediaQuery.textScalerOf(context)),
            onRetry: onRetry,
          ),
        );
      }
      return SliverToBoxAdapter(
        child: Column(
          children: [
            for (var i = 0; i < coverLoadingRows; i++)
              const KMediaCard(title: '', loading: true, filled: false),
          ],
        ),
      );
    }
    final picked = state.picked;
    final groupTitle = switch (kind) {
      CustomCoverKind.artist => l10n.coverGroupArtistAlbums,
      _ => l10n.coverGroupPlaylistAlbums,
    };
    final suggestions = options.suggestions;
    final more = suggestions.length - coverCollapsedSuggestionRows;
    final shown = suggestionsExpanded || more <= 0
        ? suggestions.length
        : coverCollapsedSuggestionRows;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _row(
                CoverRowIds.automatic,
                title: l10n.coverAutoTitle,
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
                  title: l10n.coverCurrentTitle,
                  subtitle: l10n.coverCurrentSubtitle,
                  art: _file(options.current!.thumb, itemKey),
                ),
              if (picked != null) _pickedRow(l10n, picked),
              if (suggestions.isNotEmpty) CoverGroupTitle(groupTitle),
            ],
          ),
        ),
        SliverList.builder(
          itemCount: shown,
          itemBuilder: (context, i) {
            final s = suggestions[i];
            return _row(
              s.rowId,
              title: s.title,
              subtitle: s.year == null
                  ? l10n.coverAlbumSubtitle
                  : l10n.coverAlbumSubtitleYear(s.year!),
              art: _file(s.thumb, s.title),
            );
          },
        ),
        if (more > 0)
          SliverToBoxAdapter(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: KSpace.x4),
                child: TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, KLayout.compactButton),
                    padding: const EdgeInsets.symmetric(horizontal: KSpace.x3),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onToggleSuggestions,
                  child: Text(
                    suggestionsExpanded
                        ? l10n.libraryShowLess
                        : l10n.coverMoreAlbums(more),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _pickedRow(AppLocalizations l10n, CoverPicked picked) => _row(
    CoverRowIds.picked,
    enabled: !picked.reading,
    title: picked.image.nameIsGenerated
        ? l10n.coverPickedGeneratedName
        : picked.image.name,
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
  );

  Widget _file(File file, String seed) => FileCoverArt(
    file: file,
    seed: seed,
    dimension: _thumb,
    radius: coverThumbRadius,
    circle: _round,
  );

  Widget _row(
    String id, {
    required String title,
    String? subtitle,
    required Widget art,
    bool enabled = true,
  }) => SelectionRow.media(
    selected: state.selectedId == id,
    enabled: enabled,
    alikeOptions: true,
    cover: art,
    circleCover: _round,
    mediaTitle: title,
    mediaLine2: subtitle,
    onTap: state.saving ? null : () => onSelect(id),
  );
}
