import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../media/domain/track_id.dart';
import '../lyrics_for_track_modal.dart';

/// What "Tìm lời trực tuyến…" and "Tìm thủ công…" of the lyrics area open for
/// [id]: the one place that decides it. Today it is "Lời cho bài này" (the
/// picker is not built yet); the Chọn lời picker replaces the target here.
void openFindOnline(BuildContext context, TrackId id) {
  unawaited(showLyricsForTrack(context, id, followsPlaying: true));
}
