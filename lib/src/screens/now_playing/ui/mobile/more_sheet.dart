import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../lyrics/state/playing_lyrics_providers.dart';
import '../../../../lyrics/ui/lyrics_for_track_modal.dart';
import '../../../../media/domain/cover_files.dart';
import '../../../../playback/state/playback_providers.dart';
import '../../../../playback/state/track_info_providers.dart';
import '../../../../playback/ui/track_cover.dart';
import '../now_playing_more_items.dart';

/// Opens the "More" bottom sheet of the mobile page: the current track's head
/// (cover, title, "artist · album") over the shared item list.
///
/// "Nguồn lời bài" runs after the sheet has popped, so its opener is built
/// here, from the page's context, which outlives the sheet.
Future<void> showNowPlayingMoreSheet(BuildContext context) {
  final container = ProviderScope.containerOf(context);
  void openLyrics() {
    final id = container.read(playingLyricsProvider).trackId;
    if (id == null || !context.mounted) return;
    unawaited(showLyricsForTrack(context, id, followsPlaying: true));
  }

  return showKSheet<void>(
    context,
    useRootNavigator: true,
    builder: (_) => NowPlayingMoreSheet(onOpenLyrics: openLyrics),
  );
}

class NowPlayingMoreSheet extends ConsumerWidget {
  const NowPlayingMoreSheet({super.key, this.onOpenLyrics});

  /// Opens "Lời cho bài này" from the page under the sheet (null disables
  /// the item).
  final VoidCallback? onOpenLyrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final id = ref.watch(nowPlayingProvider.select((n) => n.value?.trackId));
    final info = id == null ? null : ref.watch(trackInfoProvider(id)).value;
    final groups = nowPlayingMoreItems(
      context,
      info,
      onOpenLyrics: onOpenLyrics,
    );
    final sub = [
      if (info?.artist != null) info!.artist!,
      if (info?.album != null) info!.album!,
    ].join(' · ');
    return ListView(
      shrinkWrap: true,
      // Rows follow the host (full-bleed in the sheet): no side padding here.
      padding: const EdgeInsets.only(top: KSpace.x2, bottom: KSpace.x4),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KSpace.x4,
            0,
            KSpace.x4,
            KSpace.x3,
          ),
          child: Row(
            spacing: KSpace.x3,
            children: [
              TrackCover(
                coverKey: info?.coverKey,
                seed: info?.coverSeed ?? '',
                size: CoverSize.thumb,
                dimension: 48,
                radius: KRadius.xs,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info?.title ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium,
                    ),
                    if (sub.isNotEmpty)
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        for (var g = 0; g < groups.length; g++) ...[
          if (g > 0) const SizedBox(height: KSpace.x3),
          for (final item in groups[g])
            Padding(
              padding: const EdgeInsets.only(bottom: KSpace.x1),
              child: KListRow(
                enabled: item.onTap != null,
                leading: Icon(item.icon),
                title: item.liveLabel?.call(context) ?? Text(item.label),
                trailing: !item.soon
                    ? null
                    : item.pro
                    ? const ProBadge()
                    : Text(l10n.appComingSoon, style: text.labelMedium),
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).pop();
                  item.onTap?.call();
                },
              ),
            ),
        ],
      ],
    );
  }
}
