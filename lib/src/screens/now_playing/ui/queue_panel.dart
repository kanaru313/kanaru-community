import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../playback/ui/queue/queue_actions.dart';
import '../../../playback/ui/queue/queue_header.dart';
import '../../../playback/ui/queue/queue_list.dart';
import '../../../playback/ui/queue/queue_row_hooks.dart';
import 'queue_host.dart';
import 'queue_row_menu.dart';
import 'queue_row_trailing.dart';

/// The queue content for one host: head with counts, the list, and the
/// actions (footer on the mobile sheet, head row on the desktop panel).
///
/// The row menu and the ♥ come from here, not from `playback/`, because they
/// reach into the library.
class QueuePanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final sheet = host == QueueHost.sheet;
    final list = QueueList(
      size: sheet ? QueueRowSize.mobile : QueueRowSize.desktop,
      trailing: sheet ? null : queueRowTrailing,
      onEmptied: onEmptied,
      menu: (ctx, item, info, at, {viaKeyboard = false}) => openQueueRowMenu(
        ctx,
        item,
        info,
        at,
        host: host,
        beforeNavigate: beforeNavigate,
        onEmptied: onEmptied,
      ),
    );
    // Its own Scaffold: toasts raised here show inside the panel, above the
    // footer, not behind it.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          if (sheet)
            headWrapper?.call(_SheetHead(onClose: onClose)) ??
                _SheetHead(onClose: onClose)
          else
            const _PanelHead(),
          Expanded(child: list),
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

class _SheetHead extends StatelessWidget {
  const _SheetHead({required this.onClose});

  final VoidCallback? onClose;

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
          const QueueMoreMenu(),
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
  const _PanelHead();

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
              const QueueMoreMenu(),
            ],
          ),
        ),
      ),
    );
  }
}
