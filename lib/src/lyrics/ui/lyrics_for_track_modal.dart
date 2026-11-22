import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../media/domain/track_id.dart';
import '../state/playing_lyrics_providers.dart';
import 'lyrics_for_track_body.dart';

/// Opens "Lời cho bài này" for [id]: a bottom sheet on the mobile shell, a
/// dialog of [KLayout.dialog] on the desktop shell, over every navigator.
///
/// With [followsPlaying] it closes, once, when the playing track changes or
/// playback stops (the Now Playing entry points). Without it the modal stays
/// on [id] (a song menu). Esc, Back, the close button and the scrim close it.
Future<void> showLyricsForTrack(
  BuildContext context,
  TrackId id, {
  bool followsPlaying = false,
}) {
  Widget content(BuildContext _) =>
      _LyricsForTrackModal(trackId: id, followsPlaying: followsPlaying);
  if (FormFactor.of(context) == FormFactor.desktop) {
    return showKDialog<void>(
      context,
      maxWidth: KLayout.dialog,
      // The 440 dp cap already leaves room to the window edges, so the
      // dialog's own side inset must not shrink it.
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(vertical: KSpace.x6),
        child: content(context),
      ),
    );
  }
  return showKSheet<void>(context, useRootNavigator: true, builder: content);
}

class _LyricsForTrackModal extends ConsumerStatefulWidget {
  const _LyricsForTrackModal({
    required this.trackId,
    required this.followsPlaying,
  });

  final TrackId trackId;
  final bool followsPlaying;

  @override
  ConsumerState<_LyricsForTrackModal> createState() =>
      _LyricsForTrackModalState();
}

class _LyricsForTrackModalState extends ConsumerState<_LyricsForTrackModal> {
  /// One pop only, whatever asks to close first (a choice, the close button,
  /// the track changing during the exit animation).
  bool _closing = false;

  /// A close was asked while another route covered the modal: it pops once
  /// the modal is the current route again.
  bool _closeWhenCurrent = false;

  @override
  void initState() {
    super.initState();
    if (widget.followsPlaying) {
      ref.listenManual(playingLyricsProvider.select((p) => p.trackId), (
        _,
        playing,
      ) {
        if (playing != widget.trackId) _requestClose();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_closeWhenCurrent && (ModalRoute.of(context)?.isCurrent ?? false)) {
      _closeWhenCurrent = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _pop());
    }
  }

  void _pop() {
    if (mounted) Navigator.of(context).pop();
  }

  /// Closes the modal. False when it is already closing or already left its
  /// route (Esc, Back or the scrim got there first), so callers do not act
  /// twice.
  bool _requestClose() {
    final route = ModalRoute.of(context);
    if (_closing || route == null || !route.isActive) return false;
    _closing = true;
    if (route.isCurrent) {
      _pop();
    } else {
      _closeWhenCurrent = true;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) => Semantics(
    scopesRoute: true,
    explicitChildNodes: true,
    child: LyricsForTrackBody(trackId: widget.trackId, close: _requestClose),
  );
}
