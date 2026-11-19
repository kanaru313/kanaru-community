import 'dart:io';

import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../state/covers/cover_dialog_options.dart';
import '../../state/covers/cover_dialog_state.dart';
import '../../state/custom_cover_providers.dart';
import 'cover_art.dart';

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
      return _panned(context, preview.file, preview.width, preview.height);
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

  /// The preview shown cover-fit and slid to the pan offset along its long
  /// axis: the same cut `cropFor` gives, so the frame shows what is saved.
  Widget _panned(BuildContext context, File file, int w, int h) {
    final px = (frame * MediaQuery.devicePixelRatioOf(context)).ceil();
    final t = state.offset * 2 - 1;
    return Image.file(
      file,
      width: frame,
      height: frame,
      fit: BoxFit.cover,
      alignment: w > h ? Alignment(t, 0) : Alignment(0, t),
      // Decode the short side at frame size; the long side follows.
      cacheWidth: w > h ? null : px,
      cacheHeight: w > h ? px : null,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => _skeleton,
    );
  }
}
