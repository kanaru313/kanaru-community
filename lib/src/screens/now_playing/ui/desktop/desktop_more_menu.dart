import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../media/domain/cover_files.dart';
import '../../../../playback/state/playback_providers.dart';
import '../../../../playback/state/track_info_providers.dart';
import '../../../../playback/ui/track_cover.dart';
import '../now_playing_more_items.dart';

/// The ⋮ dropdown of the desktop header: the track's head row and the shared
/// items. [onOpenChanged] tells the header to stay shown while it is open.
class DesktopMoreMenu extends ConsumerWidget {
  const DesktopMoreMenu({super.key, required this.onOpenChanged});

  final ValueChanged<bool> onOpenChanged;

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
    MenuItemButton entry(NowPlayingMoreItem item) => MenuItemButton(
      leadingIcon: Icon(item.icon),
      onPressed: item.onTap,
      trailingIcon: !item.soon
          ? null
          : item.pro
          ? const ProBadge()
          : Text(l10n.appComingSoon, style: text.labelMedium),
      child: Text(item.label),
    );
    return MenuAnchor(
      onOpen: () => onOpenChanged(true),
      onClose: () => onOpenChanged(false),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHighest),
      ),
      menuChildren: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KSpace.x4,
            vertical: KSpace.x2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: KSpace.x3,
            children: [
              TrackCover(
                coverKey: info?.coverKey,
                seed: info?.albumKey?.toString() ?? info?.title ?? '',
                size: CoverSize.thumb,
                dimension: 44,
                radius: KRadius.xs,
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info?.title ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall,
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
        const Divider(height: 1),
        for (final item in groups[0]) entry(item),
        const Divider(height: 1),
        for (final item in groups[1]) entry(item),
      ],
      builder: (context, controller, _) => IconButton(
        icon: const Icon(KIcons.moreVert),
        tooltip: l10n.playbackMore,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}
