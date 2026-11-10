import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../playback/domain/playback_notice.dart';
import '../../playback/state/playback_providers.dart';

/// Turns the player's notices into snack bars. Once started it listens for
/// good, track or not, so a notice raised as the last track goes is not lost.
/// The remove/undo toast is shown by the UI action that removes; every other
/// notice, "queue is empty" included, comes from the player.
///
/// Listening creates the player, which must not happen while the first frame
/// builds: by default it starts after the first frame. A shell that creates
/// the player itself sets [autoStart] to false and calls
/// [PlaybackNoticeListenerState.start] in the same callback, so no notice
/// falls between the player's creation and the first listener.
class PlaybackNoticeListener extends ConsumerStatefulWidget {
  const PlaybackNoticeListener({
    super.key,
    required this.child,
    this.autoStart = true,
  });

  final Widget child;
  final bool autoStart;

  @override
  ConsumerState<PlaybackNoticeListener> createState() =>
      PlaybackNoticeListenerState();
}

class PlaybackNoticeListenerState
    extends ConsumerState<PlaybackNoticeListener> {
  StreamSubscription<PlaybackNotice>? _subscription;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => start());
    }
  }

  /// Starts listening (once). Safe to call from a post-frame callback.
  void start() {
    if (_subscription != null || !mounted) return;
    // The controller's own stream, not a provider: a provider drops an
    // update equal to the last one, and notices such as "end of the queue"
    // are equal every time.
    _subscription = ref.read(playerControllerProvider).notices.listen((notice) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        noticeText(AppLocalizations.of(context), notice),
      );
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Words for [notice].
String noticeText(AppLocalizations l10n, PlaybackNotice notice) =>
    switch (notice) {
      TrackSkipped(:final title, :final count) when count > 1 =>
        l10n.playbackNoticeSkippedMany(title, '${count - 1}'),
      TrackSkipped(:final title) => l10n.playbackNoticeSkipped(title),
      TrackFailed(:final title) => l10n.playbackNoticeFailed(title),
      FirstTrack() => l10n.playbackNoticeFirstTrack,
      QueueEnd() => l10n.playbackNoticeQueueEnd,
      QueueEmpty() => l10n.playbackNoticeQueueEmpty,
      FocusDenied() => l10n.playbackNoticeFocusDenied,
    };
