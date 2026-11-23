import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../media/domain/track_id.dart';
import '../lyrics_for_track_modal.dart';
import '../picker/lyrics_picker.dart';

/// What "Tìm lời trực tuyến…" and "Tìm thủ công…" of the lyrics area open for
/// [id]: the one place that decides it. It is the Chọn lời picker; ← goes
/// back to "Lời cho bài này".
void openFindOnline(BuildContext context, TrackId id) {
  unawaited(
    showLyricsPicker(
      context,
      id,
      followsPlaying: true,
      onBack: () {
        if (!context.mounted) return;
        unawaited(showLyricsForTrack(context, id, followsPlaying: true));
      },
    ),
  );
}
