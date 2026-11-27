import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../playback/domain/playback_notice.dart';
import '../../playback/state/playback_providers.dart';
import '../../screens/plugins/plugin_paths.dart';
import 'playback_notice_snack_bar.dart';

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
      showPlaybackNotice(context, notice);
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

/// Shows [notice] as a snack bar: its words, and its action when it has one.
/// A rate-limit pause counts down in the bar and stays until the count ends.
void showPlaybackNotice(BuildContext context, PlaybackNotice notice) {
  final l10n = AppLocalizations.of(context);
  if (notice case PausedRateLimited()) {
    showCountdownSnackBar(
      context,
      sentence: (remaining) => rateLimitedSentence(l10n, notice, remaining),
      remaining: notice.remaining,
      actionLabel: l10n.playbackNoticeRetry,
      onAction: notice.retry,
    );
    return;
  }
  final action = noticeAction(notice);
  VoidCallback? onAction;
  String? label;
  switch (action) {
    case NoticeAction.retry:
      label = l10n.playbackNoticeRetry;
      onAction = switch (notice) {
        TrackFailed(:final retry) => retry,
        PausedOffline(:final retry) => retry,
        PausedSourceBusy(:final retry) => retry,
        _ => null,
      };
    case NoticeAction.openSettings:
      final router = GoRouter.maybeOf(context);
      if (notice is PausedNeedsConfig && router != null) {
        label = l10n.playbackNoticeOpenSettings;
        final path = PluginPaths.plugin(notice.installId);
        onAction = () => unawaited(router.push<void>(path));
      }
    case null:
      break;
  }
  showAppSnackBar(
    context,
    noticeText(l10n, notice),
    actionLabel: label,
    onAction: onAction,
  );
}

/// What the action button of a snack bar does.
enum NoticeAction { retry, openSettings }

/// The action [notice] offers, or null (local notices have none).
NoticeAction? noticeAction(PlaybackNotice notice) => switch (notice) {
  TrackFailed(:final retry) when retry != null => NoticeAction.retry,
  PausedOffline() ||
  PausedSourceBusy() ||
  PausedRateLimited() => NoticeAction.retry,
  PausedNeedsConfig() => NoticeAction.openSettings,
  _ => null,
};

/// "1 phút" / "45 giây": minutes rounded up from one minute, else seconds.
String pauseLengthText(AppLocalizations l10n, Duration length) =>
    length.inSeconds >= 60
    ? l10n.playbackNoticePauseMinutes((length.inSeconds + 59) ~/ 60)
    : l10n.playbackNoticePauseSeconds(length.inSeconds);

/// `m:ss` of [remaining] in whole seconds, rounded up.
String countdownText(Duration remaining) {
  final total = remaining.isNegative
      ? 0
      : (remaining.inMilliseconds + 999) ~/ 1000;
  final seconds = (total % 60).toString().padLeft(2, '0');
  return '${total ~/ 60}:$seconds';
}

/// The sentence of a rate-limit pause with [remaining] left; at zero the
/// "no longer paused" sentence.
String rateLimitedSentence(
  AppLocalizations l10n,
  PausedRateLimited notice,
  Duration remaining,
) => remaining > Duration.zero
    ? l10n.playbackNoticePausedRateLimited(
        notice.sourceName,
        pauseLengthText(l10n, notice.pauseLength),
        countdownText(remaining),
      )
    : l10n.playbackNoticePauseEnded(notice.sourceName);

/// Words for [notice].
String noticeText(AppLocalizations l10n, PlaybackNotice notice) =>
    switch (notice) {
      TrackSkipped(:final title, :final count) when count > 1 =>
        l10n.playbackNoticeSkippedMany(title, '${count - 1}'),
      TrackSkipped(:final title) => l10n.playbackNoticeSkipped(title),
      TrackFailed() => _failedText(l10n, notice),
      FirstTrack() => l10n.playbackNoticeFirstTrack,
      QueueEnd() => l10n.playbackNoticeQueueEnd,
      QueueEmpty() => l10n.playbackNoticeQueueEmpty,
      FocusDenied() => l10n.playbackNoticeFocusDenied,
      PausedOffline() => l10n.playbackNoticePausedOffline,
      PausedRateLimited() => rateLimitedSentence(
        l10n,
        notice,
        notice.remaining,
      ),
      PausedNeedsConfig(:final sourceName) =>
        l10n.playbackNoticePausedNeedsConfig(sourceName),
      PausedSourceBusy(:final sourceName) => l10n.playbackNoticePausedBusy(
        sourceName,
      ),
    };

String _failedText(AppLocalizations l10n, TrackFailed n) {
  final source = n.sourceName;
  final code = n.code;
  return switch (n.cause) {
    RemoteFailureCause.linkRefused when source != null && code != null =>
      l10n.playbackNoticeFailedLink(n.title, source, code),
    RemoteFailureCause.formatUnsupported when source != null =>
      l10n.playbackNoticeFailedFormat(n.title, source),
    RemoteFailureCause.gone when source != null =>
      l10n.playbackNoticeFailedGone(n.title, source),
    RemoteFailureCause.linkRefused || RemoteFailureCause.other
        when code != null =>
      l10n.playbackNoticeFailedCode(n.title, code),
    _ => l10n.playbackNoticeFailed(n.title),
  };
}
