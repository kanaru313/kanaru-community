import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../extension/state/extension_providers.dart';
import '../../../domain/playlists/playlist_ids.dart';
import '../../../state/playlists/playlist_providers.dart';
import '../../browse/library_list_scaffold.dart';
import '../../browse/library_navigation.dart';
import '../../library_locations.dart';

/// One tile of the hub: Favorites, three pages that are not built yet and
/// Stats (Pro). A null [onTap] is a dimmed, inert tile.
class _HubTile {
  const _HubTile({
    required this.icon,
    required this.label,
    this.line,
    this.pro = false,
    this.onTap,
  });

  final IconData icon;
  final String label;

  /// Small line under the label (count or "Coming soon").
  final String? line;

  /// Shows the Pro badge before [line].
  final bool pro;
  final VoidCallback? onTap;
}

/// Two-column grid of shortcuts above "Playlist của bạn" (mobile shell only).
/// History, Most played and Queue take their label, icon and "coming soon"
/// state from the navigation items, so they come alive when those pages do.
class PlaylistsHub extends ConsumerWidget {
  const PlaylistsHub({super.key});

  static const double tileHeight = 56;
  static const BorderRadius _radius = BorderRadius.all(Radius.circular(16));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final registry = ref.watch(extensionRegistryProvider);
    final favorites = ref.watch(favoritesSummaryProvider).value;
    final soon = l10n.appComingSoon;
    final tiles = <_HubTile>[
      _HubTile(
        icon: KIcons.favorites,
        label: l10n.libraryNavFavorites,
        line: favorites == null
            ? null
            : l10n.playlistTrackCount(favorites.trackCount),
        onTap: () => openLibraryPage<void>(
          context,
          LibraryLocations.playlist(PlaylistUids.favorites),
        ),
      ),
      for (final id in const ['history', 'most_played', 'queue'])
        for (final item in registry.navItems.where((n) => n.id == id))
          _HubTile(
            icon: item.icon,
            label: item.label(context),
            line: item.comingSoon ? soon : null,
            onTap: item.comingSoon
                ? null
                : () => openLibraryPage<void>(context, item.path),
          ),
      _HubTile(
        icon: KIcons.stats,
        label: l10n.playlistHubStats,
        line: soon,
        pro: true,
      ),
    ];
    final scaler = MediaQuery.textScalerOf(context);
    // Label and small line at the current text scale, plus padding.
    final text = Theme.of(context).textTheme;
    final label = text.labelLarge!;
    final small = text.labelSmall!;
    final height = math.max(
      tileHeight,
      scaler.scale(
            (label.fontSize ?? 14) * (label.height ?? 1.4) +
                (small.fontSize ?? 11) * (small.height ?? 1.4),
          ) +
          2 * KSpace.x2,
    );
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        libraryGutter(context),
        KSpace.x2,
        libraryGutter(context),
        KSpace.x2,
      ),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: KSpace.x2,
          crossAxisSpacing: KSpace.x2,
          mainAxisExtent: height,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => _HubTileView(tile: tiles[i], radius: _radius),
          childCount: tiles.length,
        ),
      ),
    );
  }
}

class _HubTileView extends StatelessWidget {
  const _HubTileView({required this.tile, required this.radius});

  final _HubTile tile;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final enabled = tile.onTap != null;
    final line = tile.line;
    final body = DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: radius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KSpace.x3),
        child: Row(
          spacing: KSpace.x3,
          children: [
            Icon(tile.icon, size: KIconSize.md, color: scheme.primary),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tile.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (line != null)
                    Row(
                      spacing: KSpace.x1,
                      children: [
                        if (tile.pro) const ProBadge(),
                        Flexible(
                          child: Text(
                            line,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      container: true,
      explicitChildNodes: false,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: enabled
            ? KPressable(radius: radius, onTap: tile.onTap, child: body)
            : body,
      ),
    );
  }
}
