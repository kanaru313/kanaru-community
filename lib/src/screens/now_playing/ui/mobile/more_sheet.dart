import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../media/domain/cover_files.dart';
import '../../../../playback/state/playback_providers.dart';
import '../../../../playback/state/track_info_providers.dart';
import '../../../../playback/ui/track_cover.dart';
import '../now_playing_more_items.dart';

/// Opens the "More" bottom sheet of the mobile page: the current track's head
/// (cover, title, "artist · album") over the shared item list.
Future<void> showNowPlayingMoreSheet(BuildContext context) => showKSheet<void>(
  context,
  useRootNavigator: true,
  builder: (_) => const NowPlayingMoreSheet(),
);

class NowPlayingMoreSheet extends ConsumerWidget {
  const NowPlayingMoreSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final id = ref.watch(nowPlayingProvider.select((n) => n.value?.trackId));
    final info = id == null ? null : ref.watch(trackInfoProvider(id)).value;
    final groups = nowPlayingMoreItems(context, info);
    final sub = [
      if (info?.artist != null) info!.artist!,
      if (info?.album != null) info!.album!,
    ].join(' · ');
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(
        KSpace.x4,
        KSpace.x2,
        KSpace.x4,
        KSpace.x4,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: KSpace.x3),
          child: Row(
            spacing: KSpace.x3,
            children: [
              TrackCover(
                coverKey: info?.coverKey,
                seed: info?.albumKey?.toString() ?? info?.title ?? '',
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
                title: Text(item.label),
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
