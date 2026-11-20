import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../media/domain/cover_files.dart';
import '../../../../playback/state/playback_providers.dart';
import '../../../../playback/state/track_info_providers.dart';
import '../../../../playback/ui/sleep_timer/sleep_timer_modal.dart';
import '../../../../playback/ui/track_cover.dart';
import '../now_playing_more_items.dart';
import 'now_playing_chrome.dart';

/// The ⋮ dropdown of the desktop header: the track's head row and the shared
/// items. It pins [chrome] while it is open, so the header stays shown.
class DesktopMoreMenu extends ConsumerStatefulWidget {
  const DesktopMoreMenu({super.key, required this.chrome});

  final NowPlayingChrome chrome;

  @override
  ConsumerState<DesktopMoreMenu> createState() => _DesktopMoreMenuState();
}

class _DesktopMoreMenuState extends ConsumerState<DesktopMoreMenu> {
  /// Whether this menu holds a pin, so it is given back exactly once.
  bool _pinned = false;

  /// The ⋮ button: the sleep timer returns focus to it.
  final _moreFocus = FocusNode(debugLabel: 'desktop more menu');

  void _setPinned(bool pinned) {
    if (_pinned == pinned) return;
    _pinned = pinned;
    pinned ? widget.chrome.pinFloating() : widget.chrome.unpinFloating();
  }

  @override
  void dispose() {
    // The menu leaves with its header: give the pin back.
    _setPinned(false);
    _moreFocus.dispose();
    super.dispose();
  }

  /// Opens the sleep timer with the header pinned. A menu that left the tree
  /// meanwhile (Now Playing closed) leaves the controller alone: the screen
  /// disposes it.
  Future<void> _openSleepTimer() => widget.chrome.whilePinned(
    () => showSleepTimer(context, returnFocus: _moreFocus),
    stillOwned: () => mounted,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final id = ref.watch(nowPlayingProvider.select((n) => n.value?.trackId));
    final info = id == null ? null : ref.watch(trackInfoProvider(id)).value;
    final groups = nowPlayingMoreItems(
      context,
      info,
      openSleepTimer: () => unawaited(_openSleepTimer()),
    );
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
      child: item.liveLabel?.call(context) ?? Text(item.label),
    );
    return MenuAnchor(
      onOpen: () => _setPinned(true),
      onClose: () => _setPinned(false),
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
                seed: info?.coverSeed ?? '',
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
      builder: (context, controller, _) => KIconButton(
        icon: KIcons.moreVert,
        tooltip: l10n.playbackMore,
        focusNode: _moreFocus,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}
