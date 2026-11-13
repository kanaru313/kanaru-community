import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../library/state/browse/selection_providers.dart';
import '../../../library/ui/selection/selection_bar.dart';
import '../../../library/ui/songs/song_tile.dart';
import '../../../playback/ui/queue/queue_actions.dart';
import '../../../playback/ui/queue/queue_header.dart';
import '../../../playback/ui/queue/queue_list.dart';
import '../../../playback/ui/queue/queue_row_hooks.dart';
import '../state/queue_selection.dart';
import 'queue_host.dart';
import 'queue_row_menu.dart';

/// The queue content for one host: head with counts, the list, and the
/// actions (footer on the mobile sheet, head row on the desktop panel).
///
/// The row menu and the ♥ come from here, not from `playback/`, because they
/// reach into the library. Rows join the app-wide selection through
/// [QueueRowSelection]. On the sheet host the selection panel floats over the
/// list's end, above the footer, while anything is selected; on the desktop
/// panel it does not (the shell hides its own panel under Now Playing).
class QueuePanel extends ConsumerWidget {
  const QueuePanel({
    super.key,
    required this.host,
    this.onEmptied,
    this.onClose,
    this.beforeNavigate,
    this.headWrapper,
  });

  final QueueHost host;

  /// The last entry was removed: the host closes.
  final VoidCallback? onEmptied;

  /// Mobile: the ⌄ button in the head.
  final VoidCallback? onClose;

  /// A row menu navigates to the library: close what covers it first.
  final VoidCallback? beforeNavigate;

  /// Mobile: wraps the head, so the sheet can make it a drag handle.
  final Widget Function(Widget head)? headWrapper;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sheet = host == QueueHost.sheet;
    final selecting = sheet && ref.watch(hasSelectionProvider);
    final queueSelection = ref.read(queueSelectionProvider.notifier);
    final list = QueueList(
      bottomInset: selecting ? _sheetPanelInset(context) : 0,
      selection: QueueRowSelection(
        isSelected: (id) => isSelectedProvider(id),
        selecting: hasSelectionProvider,
        onSelect: (item, {range = false}) =>
            range ? queueSelection.rangeTo(item) : queueSelection.toggle(item),
      ),
      size: sheet ? QueueRowSize.mobile : QueueRowSize.desktop,
      favorite: (context, item) => SongFavoriteButton(trackId: item.trackId),
      onEmptied: onEmptied,
      menu: (ctx, item, info, at, {viaKeyboard = false}) => openQueueRowMenu(
        ctx,
        item,
        info,
        at,
        host: host,
        beforeNavigate: beforeNavigate,
        onEmptied: onEmptied,
        viaKeyboard: viaKeyboard,
      ),
    );
    // Its own Scaffold: toasts raised here show inside the panel, above the
    // footer, not behind it.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          if (sheet)
            headWrapper?.call(
                  _SheetHead(
                    onClose: onClose,
                    onSelectMany: queueSelection.selectCurrent,
                  ),
                ) ??
                _SheetHead(
                  onClose: onClose,
                  onSelectMany: queueSelection.selectCurrent,
                )
          else
            _PanelHead(onSelectMany: queueSelection.selectCurrent),
          Expanded(
            child: selecting
                ? Stack(children: [list, const _FloatingBar()])
                : list,
          ),
        ],
      ),
      bottomNavigationBar: sheet
          ? const SafeArea(
              child: Align(
                heightFactor: 1,
                child: QueueActions(menuUp: true, includeSave: false),
              ),
            )
          : null,
    );
  }
}

/// The bar's own padding under the panel (see `LibrarySelectionBar`) and the
/// gap between it and the footer.
const double _barPadding = KSpace.x1;
const double _barGap = KSpace.x2;

/// Room the list leaves at its end for the collapsed selection panel and its
/// gaps. An expanded panel may cover the last rows: they cannot scroll above
/// it (accepted; the panel collapses with one tap).
double _sheetPanelInset(BuildContext context) =>
    KSelectionPanel.heightFor(context, expanded: false, bodyHeight: 0) +
    _barGap +
    _barPadding;

/// The selection panel floating at the bottom of the list area.
class _FloatingBar extends StatelessWidget {
  const _FloatingBar();

  @override
  Widget build(BuildContext context) => const Positioned(
    left: 0,
    right: 0,
    bottom: _barGap,
    child: LibrarySelectionBar(),
  );
}

class _SheetHead extends StatelessWidget {
  const _SheetHead({required this.onClose, required this.onSelectMany});

  final VoidCallback? onClose;
  final VoidCallback onSelectMany;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: KSpace.x4, right: KSpace.x2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.playbackNavQueue,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const QueueCounts(mobile: true),
              ],
            ),
          ),
          const QueueSoonButton.save(),
          QueueMoreMenu(onSelectMany: onSelectMany),
          IconButton(
            icon: const Icon(KIcons.collapse),
            tooltip: l10n.playbackMinimize,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

/// Counts on the left, actions on the right, under the panel's own header.
class _PanelHead extends StatelessWidget {
  const _PanelHead({required this.onSelectMany});

  final VoidCallback onSelectMany;

  @override
  Widget build(BuildContext context) {
    // 40 dp buttons (the desktop minimum) with 8 dp between them; the count
    // line takes the rest of the 420 dp and shows in full in its tooltip.
    return Theme(
      data: Theme.of(context).copyWith(
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: KSpace.x4, right: KSpace.x2),
        child: SizedBox(
          height: KLayout.minTarget,
          child: Row(
            children: [
              const Expanded(child: QueueCounts(mobile: false)),
              const QueueActions(gap: KSpace.x2),
              const VerticalDivider(
                width: KSpace.x2,
                indent: 12,
                endIndent: 12,
              ),
              QueueMoreMenu(onSelectMany: onSelectMany),
            ],
          ),
        ),
      ),
    );
  }
}
