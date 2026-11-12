import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/cover_files.dart';
import '../../../media/domain/track_info.dart';
import '../../../media/domain/track_lines.dart';
import '../../domain/queue_state.dart';
import '../../state/playback_providers.dart';
import '../../state/queue_row_infos.dart';
import '../playback_time_label.dart';
import '../track_cover.dart';
import 'queue_row_hooks.dart';

/// One queue row, a flat [KMediaCard] like a library song row: cover (with
/// the equalizer on the current one), title / artists / `album • year`,
/// duration, the drag handle and the ⋮ menu button.
///
/// The handle sits left of the cover on desktop and right of the text on
/// mobile, where a long press on the row (not on the handle) opens the menu.
/// Rows watch only their own info and, for the current row, play/pause; a
/// position tick rebuilds nothing here.
class QueueRow extends ConsumerStatefulWidget {
  const QueueRow({
    super.key,
    required this.item,
    required this.index,
    required this.role,
    required this.size,
    required this.onRemove,
    this.favorite,
    this.menu,
  });

  final QueueItem item;
  final int index;
  final QueueRowRole role;
  final QueueRowSize size;
  final VoidCallback onRemove;
  final QueueRowFavorite? favorite;
  final QueueRowMenu? menu;

  @override
  ConsumerState<QueueRow> createState() => _QueueRowState();
}

class _QueueRowState extends ConsumerState<QueueRow> {
  /// The drag handle, so a long press that starts on it is not the row's.
  final _handleKey = GlobalKey();

  bool get _desktop => widget.size == QueueRowSize.desktop;

  void _openMenu(TrackInfo? info, Offset? at, {bool viaKeyboard = false}) =>
      widget.menu?.call(
        context,
        widget.item,
        info,
        at,
        viaKeyboard: viaKeyboard,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final item = widget.item;
    final role = widget.role;
    final info = ref.watch(
      queueRowInfosProvider.select((m) => m[item.trackId]),
    );
    final duration = info?.durationMs;
    final handle = _Handle(
      key: _handleKey,
      index: widget.index,
      dimension: _desktop ? KMediaCard.prefixWidth : KLayout.minTarget,
    );

    Widget row = KMediaCard(
      style: KMediaCardStyle.flat,
      title: info?.title ?? '',
      loading: info == null,
      line2: info == null ? null : trackArtistLine(info),
      line3: info == null ? null : trackAlbumLine(info),
      prefix: _desktop ? handle : null,
      leading: _Cover(info: info, current: role == QueueRowRole.current),
      top: duration == null
          ? null
          : Text(formatClock(Duration(milliseconds: duration))),
      bottom: widget.favorite?.call(context, item),
      accessory: _desktop ? null : handle,
      trailing: widget.menu == null
          ? null
          : Builder(
              builder: (button) => KMoreButton(
                tooltip: l10n.playbackMore,
                onPressed: ({required viaKeyboard}) {
                  final box = button.findRenderObject()! as RenderBox;
                  _openMenu(
                    info,
                    box.localToGlobal(box.size.center(Offset.zero)),
                    viaKeyboard: viaKeyboard,
                  );
                },
              ),
            ),
      current: role == QueueRowRole.current,
      currentLabel: l10n.playbackNowPlaying,
      dimmed: role == QueueRowRole.played,
      onTap: role == QueueRowRole.current
          ? () {}
          : () => ref.read(playerControllerProvider).playEntry(item.entryId),
    );
    if (!_desktop) {
      row = RawGestureDetector(
        behavior: HitTestBehavior.translucent,
        gestures: {
          _RowLongPress: GestureRecognizerFactoryWithHandlers<_RowLongPress>(
            () => _RowLongPress(_handleKey),
            (r) =>
                r.onLongPressStart = (d) => _openMenu(info, d.globalPosition),
          ),
        },
        // The default delegate looks the long press up by its exact type, so
        // the subclass needs its own screen-reader action.
        semantics: _LongPressSemantics(() {
          final box = context.findRenderObject();
          if (box is! RenderBox || !box.attached) return;
          _openMenu(info, box.localToGlobal(box.size.center(Offset.zero)));
        }),
        child: row,
      );
    } else {
      row = CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.delete): widget.onRemove,
        },
        child: row,
      );
    }
    return KContextRegion(
      longPressOpens: false,
      onOpen: (at) => _openMenu(info, at, viaKeyboard: at == null),
      child: row,
    );
  }
}

/// Long press of a mobile row that ignores presses starting on the drag
/// handle, so holding the handle then moving drags instead of opening the
/// menu.
class _RowLongPress extends LongPressGestureRecognizer {
  _RowLongPress(this.excluded);

  final GlobalKey excluded;

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    final box = excluded.currentContext?.findRenderObject();
    if (box is RenderBox && box.attached && box.hasSize) {
      if (box.size.contains(box.globalToLocal(event.position))) return false;
    }
    return super.isPointerAllowed(event);
  }
}

/// Adds the long-press semantics action that [RawGestureDetector] would only
/// add for a plain `LongPressGestureRecognizer`.
class _LongPressSemantics extends SemanticsGestureDelegate {
  const _LongPressSemantics(this.onLongPress);

  final VoidCallback onLongPress;

  @override
  void assignSemantics(RenderSemanticsGestureHandler renderObject) {
    renderObject.onLongPress = onLongPress;
  }
}

/// Drag handle: starts a reorder on drag; a tap is swallowed so it does not
/// play the row. Takes the colour of the card's icons.
class _Handle extends StatelessWidget {
  const _Handle({super.key, required this.index, required this.dimension});

  final int index;
  final double dimension;

  @override
  Widget build(BuildContext context) {
    return ReorderableDragStartListener(
      index: index,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Swallows the tap without a do-nothing semantics action.
        excludeFromSemantics: true,
        onTap: () {},
        child: Semantics(
          label: AppLocalizations.of(context).playbackQueueReorder,
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: SizedBox.square(
              dimension: dimension,
              child: const Icon(KIcons.dragHandle),
            ),
          ),
        ),
      ),
    );
  }
}

class _Cover extends ConsumerWidget {
  const _Cover({required this.info, required this.current});

  final TrackInfo? info;
  final bool current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = BorderRadius.circular(10);
    final cover = TrackCover(
      coverKey: info?.coverKey,
      seed: info?.albumKey?.encode() ?? info?.title ?? '',
      size: CoverSize.thumb,
      dimension: KMediaCard.coverSize,
      radius: radius,
    );
    if (!current) return cover;
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        cover,
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.scrim.withValues(alpha: 0.45),
              borderRadius: radius,
            ),
          ),
        ),
        KEqualizerIcon(
          playing: ref.watch(isPlayingProvider),
          color: scheme.onPrimary,
        ),
      ],
    );
  }
}
