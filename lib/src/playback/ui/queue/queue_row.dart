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
/// The handle sits in the accessory slot, right before ⋮, on both shells. On
/// both shells a long press on the row (not on the handle) selects it when the
/// host gives a [selection]; without one, mobile opens the menu and desktop
/// does nothing. On desktop Delete also removes the row. With a [selection], every row of a selected track shows
/// selected, and a tap toggles while something is selected.
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
    this.selection,
  });

  final QueueItem item;
  final int index;
  final QueueRowRole role;
  final QueueRowSize size;
  final VoidCallback onRemove;
  final QueueRowFavorite? favorite;
  final QueueRowMenu? menu;
  final QueueRowSelection? selection;

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

  /// A tap or click: Shift selects a range, Ctrl / ⌘ or an existing selection
  /// toggles the row, else it plays (the current row does nothing).
  void _tap() {
    final sel = widget.selection;
    final item = widget.item;
    final click = sel == null
        ? SongClick.play
        : songClick(selecting: ref.read(sel.selecting));
    switch (click) {
      case SongClick.range:
        sel!.onSelect(item, range: true);
      case SongClick.toggle:
        sel!.onSelect(item);
      case SongClick.play:
        if (widget.role == QueueRowRole.current) return;
        ref.read(playerControllerProvider).playEntry(item.entryId);
    }
  }

  /// A long press that starts on the row: selects it (toggles while
  /// selecting), with a light tick on mobile.
  void _select() {
    if (!_desktop) HapticFeedback.selectionClick();
    widget.selection?.onSelect(widget.item);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final item = widget.item;
    final sel = widget.selection;
    final selected = sel != null && ref.watch(sel.isSelected(item.trackId));
    final role = widget.role;
    final info = ref.watch(
      queueRowInfosProvider.select((m) => m[item.trackId]),
    );
    final duration = info?.durationMs;
    final handle = KDragHandle(
      key: _handleKey,
      index: widget.index,
      dimension: _desktop ? KLayout.minTargetDesktop : KLayout.minTarget,
      semanticLabel: l10n.playbackQueueReorder,
    );

    Widget row = KMediaCard(
      style: KMediaCardStyle.flat,
      title: info?.title ?? '',
      loading: info == null,
      line2: info == null ? null : trackArtistLine(info),
      line3: info == null ? null : trackAlbumLine(info),
      leading: _Cover(
        info: info,
        current: role == QueueRowRole.current && !selected,
      ),
      top: duration == null
          ? null
          : Text(formatClock(Duration(milliseconds: duration))),
      bottom: widget.favorite?.call(context, item),
      accessory: handle,
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
      selected: selected,
      onTap: _tap,
    );
    // Mobile always has a long press (select, or the menu without a selection
    // hook); desktop has one only to select.
    if (!_desktop || sel != null) {
      row = RawGestureDetector(
        behavior: HitTestBehavior.translucent,
        gestures: {
          _RowLongPress: GestureRecognizerFactoryWithHandlers<_RowLongPress>(
            () => _RowLongPress(_handleKey),
            (r) => r.onLongPressStart = sel == null
                ? (d) => _openMenu(info, d.globalPosition)
                : (_) => _select(),
          ),
        },
        // The default delegate looks the long press up by its exact type, so
        // the subclass needs its own screen-reader action (with a selection,
        // the `Semantics` below carries it instead, to name it).
        semantics: sel == null
            ? _LongPressSemantics(() {
                final box = context.findRenderObject();
                if (box is! RenderBox || !box.attached) return;
                _openMenu(
                  info,
                  box.localToGlobal(box.size.center(Offset.zero)),
                );
              })
            : null,
        child: row,
      );
      if (sel != null) {
        row = Semantics(
          onLongPress: _select,
          onLongPressHint: selected
              ? l10n.libraryMenuDeselect
              : l10n.libraryMenuSelect,
          child: row,
        );
      }
    }
    if (_desktop) {
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

/// Long press of a row that ignores presses starting on the drag
/// handle, so holding the handle then moving drags instead of selecting.
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

class _Cover extends ConsumerWidget {
  const _Cover({required this.info, required this.current});

  final TrackInfo? info;
  final bool current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const radius = KMediaCard.coverRadius;
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
