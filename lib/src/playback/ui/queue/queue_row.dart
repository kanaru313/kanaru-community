import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/cover_files.dart';
import '../../../media/domain/track_info.dart';
import '../../domain/queue_state.dart';
import '../../state/playback_providers.dart';
import '../../state/queue_row_infos.dart';
import '../track_cover.dart';
import 'queue_row_hooks.dart';

/// One queue row: cover (with the equalizer on the current one), title and
/// artist, the drag handle, and on desktop the host's trailing widget and ⋮.
///
/// Rows watch only their own info and, for the current row, play/pause; a
/// position tick rebuilds nothing here.
class QueueRow extends ConsumerWidget {
  const QueueRow({
    super.key,
    required this.item,
    required this.index,
    required this.role,
    required this.size,
    required this.onRemove,
    this.trailing,
    this.menu,
  });

  final QueueItem item;
  final int index;
  final QueueRowRole role;
  final QueueRowSize size;
  final VoidCallback onRemove;
  final QueueRowTrailing? trailing;
  final QueueRowMenu? menu;

  bool get _desktop => size == QueueRowSize.desktop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final info = ref.watch(
      queueRowInfosProvider.select((m) => m[item.trackId]),
    );
    void openMenu(Offset? at) => menu?.call(context, item, info, at);
    Widget row = Row(
      children: [
        const SizedBox(width: KSpace.x2),
        if (_desktop) _Handle(index: index, size: size),
        Expanded(
          child: Opacity(
            opacity: role == QueueRowRole.played ? 0.5 : 1,
            child: Row(
              spacing: KSpace.x3,
              children: [
                _Cover(info: info, role: role, size: size),
                Expanded(
                  child: _Titles(info: info, desktop: _desktop),
                ),
              ],
            ),
          ),
        ),
        if (_desktop && trailing != null) trailing!(context, item, info),
        if (_desktop && menu != null)
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(KIcons.moreVert),
              tooltip: AppLocalizations.of(context).playbackMore,
              onPressed: () {
                final box = context.findRenderObject()! as RenderBox;
                openMenu(box.localToGlobal(box.size.center(Offset.zero)));
              },
            ),
          ),
        if (!_desktop) _Handle(index: index, size: size),
        const SizedBox(width: KSpace.x2),
      ],
    );
    row = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: KRadius.md,
        color: role == QueueRowRole.current ? scheme.secondaryContainer : null,
      ),
      child: KPressable(
        radius: KRadius.md,
        onTap: () => role == QueueRowRole.current
            ? null
            : ref.read(playerControllerProvider).playEntry(item.entryId),
        child: row,
      ),
    );
    if (_desktop) {
      row = CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.delete): onRemove},
        child: row,
      );
    }
    return KContextRegion(
      longPressOpens: !_desktop,
      onOpen: openMenu,
      child: SizedBox(
        height: size.extent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: KSpace.x1 / 2),
          child: row,
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle({required this.index, required this.size});

  final int index;
  final QueueRowSize size;

  @override
  Widget build(BuildContext context) {
    return ReorderableDragStartListener(
      index: index,
      child: Semantics(
        label: AppLocalizations.of(context).playbackQueueReorder,
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          // Hit area at least KLayout.minTarget on mobile; the icon stays
          // centred.
          child: SizedBox.square(
            dimension: size == QueueRowSize.mobile
                ? KLayout.minTarget
                : size.handle,
            child: Icon(
              KIcons.dragHandle,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _Cover extends ConsumerWidget {
  const _Cover({required this.info, required this.role, required this.size});

  final TrackInfo? info;
  final QueueRowRole role;
  final QueueRowSize size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cover = TrackCover(
      coverKey: info?.coverKey,
      seed: info?.albumKey?.toString() ?? info?.title ?? '',
      size: CoverSize.thumb,
      dimension: size.cover,
      radius: KRadius.xs,
    );
    if (role != QueueRowRole.current) return cover;
    final playing = ref.watch(isPlayingProvider);
    return Stack(
      alignment: Alignment.center,
      children: [
        cover,
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: KRadius.xs,
            color: Colors.black.withValues(alpha: 0.45),
          ),
          child: SizedBox.square(dimension: size.cover),
        ),
        KEqualizerIcon(playing: playing, color: Colors.white),
      ],
    );
  }
}

class _Titles extends StatelessWidget {
  const _Titles({required this.info, required this.desktop});

  final TrackInfo? info;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final sub = text.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final i = info;
    if (i == null) {
      // Same height as the loaded lines, so rows do not jump.
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final w in [140.0, 90.0])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: SizedBox(
                width: w,
                height: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: KRadius.xs,
                  ),
                ),
              ),
            ),
        ],
      );
    }
    final album = [
      if (i.album != null) i.album!,
      if (i.year != null) '${i.year}',
    ].join(' • ');
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          i.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (i.artist != null)
          Text(
            i.artist!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: sub,
          ),
        if (desktop && album.isNotEmpty)
          Text(album, maxLines: 1, overflow: TextOverflow.ellipsis, style: sub),
      ],
    );
  }
}
