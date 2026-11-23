import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../media/domain/track_id.dart';
import '../../state/playing_lyrics_providers.dart';
import '../lyrics_keep_notice.dart';
import 'picker_actions.dart';
import 'picker_desktop.dart';
import 'picker_mobile.dart';

export 'picker_actions.dart' show PickedLyrics, PickerUse;

/// Width of the desktop dialog (the mockup's 780 dp).
const double _dialogWidth = 780;

/// Opens "Chọn lời" for [trackId]: a dialog of 780 dp on the desktop shell, a
/// full-height sheet on the touch shells, over every navigator. It searches
/// the sources that are on at once; the ones that are off are asked only when
/// the user taps Tìm.
///
/// [onBack] runs after ← (also Back, Esc and Huỷ) closed the picker: it opens
/// "Lời cho bài này" again; without it they only close. ✕ closes for good.
/// [use] is what "Dùng lời này" does with the chosen result; the default
/// keeps it as the song's own copy. With [followsPlaying] it closes, once,
/// when the playing track changes or playback stops.
Future<void> showLyricsPicker(
  BuildContext context,
  TrackId trackId, {
  VoidCallback? onBack,
  PickerUse? use,
  bool followsPlaying = false,
}) {
  Widget content(BuildContext _) => LyricsPickerHost(
    trackId: trackId,
    onBack: onBack,
    use: use,
    followsPlaying: followsPlaying,
  );
  if (FormFactor.of(context) == FormFactor.desktop) {
    return showKDialog<void>(
      context,
      maxWidth: _dialogWidth,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(vertical: KSpace.x6),
        clipBehavior: Clip.antiAlias,
        child: content(context),
      ),
    );
  }
  return showKSheet<void>(
    context,
    useRootNavigator: true,
    fixedHeight: true,
    maxHeightFraction: 1,
    builder: content,
  );
}

/// The picker's route: closes it once (whatever asks first), follows the
/// playing track, and gives its two layouts the actions they call.
class LyricsPickerHost extends ConsumerStatefulWidget {
  const LyricsPickerHost({
    super.key,
    required this.trackId,
    this.onBack,
    this.use,
    this.followsPlaying = false,
  });

  final TrackId trackId;
  final VoidCallback? onBack;
  final PickerUse? use;
  final bool followsPlaying;

  @override
  ConsumerState<LyricsPickerHost> createState() => _LyricsPickerHostState();
}

class _LyricsPickerHostState extends ConsumerState<LyricsPickerHost> {
  /// One pop only, whatever asks to close first.
  bool _closing = false;

  /// A close was asked while the preview page covered the picker: it pops
  /// once the picker is the current route again.
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

  /// False when the picker is already closing or left its route (Esc, Back or
  /// the scrim got there first), so callers do not act twice.
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

  void _back() {
    final onBack = widget.onBack;
    if (!_requestClose()) return;
    if (onBack == null) return;
    // After the pop has started: the next modal opens over the same
    // navigator, so its context outlives this one.
    WidgetsBinding.instance.addPostFrameCallback((_) => onBack());
  }

  void _pick(PickedLyrics picked) {
    // The notice is taken before the route closes.
    final use =
        widget.use ??
        keepForTrack(ref, widget.trackId, notices: LyricsNotices.of(context));
    if (_requestClose()) runPickerUse(use, picked);
  }

  @override
  Widget build(BuildContext context) {
    final actions = PickerActions(
      close: _requestClose,
      back: _back,
      pick: _pick,
    );
    // Back and Esc do what ← does (the way back to "Lời cho bài này"); ✕ and
    // "Dùng lời này" close it for good. Without a way back they just close.
    return PopScope(
      canPop: widget.onBack == null || _closing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        child: FormFactor.of(context) == FormFactor.desktop
            ? PickerDesktop(trackId: widget.trackId, actions: actions)
            : PickerMobile(trackId: widget.trackId, actions: actions),
      ),
    );
  }
}
