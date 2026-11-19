import 'dart:io';

import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../state/covers/cover_dialog_options.dart';
import '../../state/covers/cover_dialog_state.dart';
import '../../state/custom_cover_providers.dart';
import 'cover_art.dart';
import 'panned_cover_image.dart';

/// The picture inside the preview frame for the chosen row, [frame] wide and
/// high and square-cornered (the frame clips it). Only preview files and
/// thumbs are read, never the picked original.
class CoverFrameArt extends StatelessWidget {
  const CoverFrameArt({
    super.key,
    required this.kind,
    required this.itemKey,
    required this.state,
    required this.frame,
  });

  final CustomCoverKind kind;
  final String itemKey;
  final CoverDialogState state;
  final double frame;

  Widget get _skeleton =>
      KCover.loading(size: frame, radius: BorderRadius.zero);

  @override
  Widget build(BuildContext context) {
    final options = state.options.value;
    final id = state.selectedId;
    if (options == null || id == null) return _skeleton;
    if (id == CoverRowIds.picked) {
      final preview = state.picked?.preview;
      if (preview == null) return _skeleton;
      return PannedCoverImage(
        file: preview.file,
        width: preview.width,
        height: preview.height,
        offset: state.offset,
        dimension: frame,
        errorBuilder: (_, _, _) => _skeleton,
      );
    }
    final File? file = id == CoverRowIds.current
        ? options.current?.thumb
        : state.selectedSuggestion?.thumb;
    if (file != null) {
      return FileCoverArt(
        file: file,
        seed: itemKey,
        dimension: frame,
        radius: BorderRadius.zero,
      );
    }
    return AutomaticCoverArt(
      kind: kind,
      itemKey: itemKey,
      options: options,
      dimension: frame,
      radius: BorderRadius.zero,
    );
  }
}
