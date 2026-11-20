import 'dart:math' as math;

import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../media/domain/cover_files.dart';
import '../../../playback/ui/track_cover.dart';

/// The automatic cover of a collection page from 1 to 4 cover keys: the
/// single [TrackCover] of one key, a [KCoverMosaic] of 2 to 4, else (no key)
/// the placeholder cover of [seed]. Shared by the playlist and History heroes.
///
/// [size] is the cover file to decode for the tiles; see
/// `playlistCoverFileSize`. The result is the cover itself, not a wrapper, so
/// a caller can wrap or inspect it directly.
Widget autoCoverArt({
  required List<String> keys,
  required String seed,
  required CoverSize size,
  required double dimension,
  required BorderRadius radius,
}) {
  if (keys.length < 2) {
    return TrackCover(
      coverKey: keys.firstOrNull,
      seed: seed,
      size: size,
      dimension: dimension,
      radius: radius,
    );
  }
  return KCoverMosaic(
    size: dimension,
    radius: radius,
    tiles: [
      for (final key in keys.take(4))
        (context, w, h) {
          final side = math.max(w, h);
          // TrackCover draws a square; the tile crops it to w x h.
          return ClipRect(
            child: OverflowBox(
              minWidth: side,
              maxWidth: side,
              minHeight: side,
              maxHeight: side,
              child: TrackCover(
                coverKey: key,
                seed: seed,
                size: size,
                dimension: side,
                radius: BorderRadius.zero,
              ),
            ),
          );
        },
    ],
  );
}
