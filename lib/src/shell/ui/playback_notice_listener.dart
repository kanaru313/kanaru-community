import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../playback/domain/playback_notice.dart';
import '../../playback/state/queue_view_provider.dart';

/// Turns the player's notices into snack bars. Once [enabled] it listens
/// for good, track or not, so a notice raised as the last track goes is not
/// lost. Notices raised by a UI action (remove with undo) are shown by that
/// action instead.
class PlaybackNoticeListener extends ConsumerWidget {
  const PlaybackNoticeListener({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;

  /// False until the shell has created the player: listening creates it, and
  /// that must not happen while the first frame builds.
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The child stays in the same place whether or not we listen.
    if (enabled) {
      ref.listen<AsyncValue<PlaybackNotice>>(playbackNoticesProvider, (
        _,
        next,
      ) {
        final notice = next.value;
        if (notice == null) return;
        showAppSnackBar(
          context,
          noticeText(AppLocalizations.of(context), notice),
        );
      });
    }
    return child;
  }
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
