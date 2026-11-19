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

  /// The automatic cover, always under the picture: while a file decodes (or
  /// fails to) this shows, so the frame is never blank between two choices.
  Widget _base(CoverDialogOptions options) => AutomaticCoverArt(
    kind: kind,
    itemKey: itemKey,
    options: options,
    dimension: frame,
    radius: BorderRadius.zero,
  );

  @override
  Widget build(BuildContext context) {
    final options = state.options.value;
    final id = state.selectedId;
    if (options == null || id == null) return _skeleton;
    final preview = state.picked?.preview;
    // One picture widget for every file choice (same slot, same type), so a
    // change of file is gapless.
    final Widget? top;
    if (id == CoverRowIds.picked) {
      top = preview == null
          ? null
          : PannedCoverImage(
              file: preview.file,
              width: preview.width,
              height: preview.height,
              offset: state.offset,
              dimension: frame,
              errorBuilder: _hidden,
            );
    } else {
      // Current cover and suggestions: what is saved is the file itself,
      // centred, never the pan of the picked image.
      final File? file = id == CoverRowIds.current
          ? options.current?.thumb
          : state.selectedSuggestion?.thumb;
      top = file == null
          ? null
          : PannedCoverImage(
              file: file,
              dimension: frame,
              errorBuilder: _hidden,
            );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        // Picked image still being read: skeleton, as before.
        if (id == CoverRowIds.picked && preview == null)
          _skeleton
        else
          _base(options),
        top ?? const SizedBox.shrink(),
      ],
    );
  }

  /// Unreadable file: the cover underneath shows.
  static Widget _hidden(BuildContext _, Object _, StackTrace? _) =>
      const SizedBox.shrink();
}
