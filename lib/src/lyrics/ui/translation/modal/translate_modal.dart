import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../media/domain/track_id.dart';
import '../../../state/playing_lyrics_providers.dart';
import 'translate_body.dart';
import 'translate_frame.dart';

/// Opens "Dịch lời" for [trackId]: a bottom sheet on the mobile shell, a
/// dialog of [KLayout.dialog] on the desktop shell, over every navigator.
/// Choosing a value opens a page over it (the modal stays dimmed below); Esc
/// and Back close the topmost page, then the modal.
///
/// With [followsPlaying] the modal and its pages close, once, when the
/// playing track changes or playback stops (the Now Playing entry points).
/// Without it the modal stays on [trackId] (a song menu).
Future<void> showTranslateModal(
  BuildContext context,
  TrackId trackId, {
  bool followsPlaying = false,
}) {
  final control = TranslateModalControl(
    trackId: trackId,
    followsPlaying: followsPlaying,
    navigator: Navigator.of(context, rootNavigator: true),
  );
  return showTranslateFrame(
    context,
    control,
    (_) => _TranslateModal(control: control),
  );
}

class _TranslateModal extends ConsumerStatefulWidget {
  const _TranslateModal({required this.control});

  final TranslateModalControl control;

  @override
  ConsumerState<_TranslateModal> createState() => _TranslateModalState();
}

class _TranslateModalState extends ConsumerState<_TranslateModal> {
  @override
  void initState() {
    super.initState();
    final control = widget.control;
    if (control.followsPlaying) {
      ref.listenManual(playingLyricsProvider.select((p) => p.trackId), (
        _,
        playing,
      ) {
        if (playing != control.trackId) control.closeAll();
      });
    }
  }

  @override
  Widget build(BuildContext context) => TranslateBody(control: widget.control);
}
