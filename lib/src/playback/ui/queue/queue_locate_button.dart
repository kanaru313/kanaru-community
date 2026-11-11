import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// Rows kept above the current one when the list scrolls to it, so the last
/// played row shows above.
const int queueLeadRows = 1;

/// Scroll offset that puts row [index] near the top, one played row above.
double queueOffsetFor(int index, double extent) =>
    ((index - queueLeadRows) * extent).clamp(0, double.infinity);

/// Which side the current row is on, as seen from the viewport.
enum QueueLocateSide { none, above, below }

/// The round "Go to current track" button at the bottom right of the list.
/// Shown only while the current row is out of view; the arrow points the way.
/// Rebuilds only when the side changes, not on every scroll event.
class QueueLocateButton extends StatefulWidget {
  const QueueLocateButton({
    super.key,
    required this.controller,
    required this.currentIndex,
    required this.extent,
  });

  static const double size = 48;

  final ScrollController controller;
  final int? currentIndex;
  final double extent;

  @override
  State<QueueLocateButton> createState() => QueueLocateButtonState();
}

class QueueLocateButtonState extends State<QueueLocateButton> {
  QueueLocateSide _side = QueueLocateSide.none;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(recompute);
    WidgetsBinding.instance.addPostFrameCallback((_) => recompute());
  }

  @override
  void didUpdateWidget(QueueLocateButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(recompute);
      widget.controller.addListener(recompute);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => recompute());
  }

  @override
  void dispose() {
    widget.controller.removeListener(recompute);
    super.dispose();
  }

  /// Works out the side from the scroll position; called on scroll, on
  /// resize and when the current row changes.
  void recompute() {
    if (!mounted) return;
    final c = widget.controller;
    final cur = widget.currentIndex;
    var side = QueueLocateSide.none;
    if (cur != null && c.hasClients) {
      final top = cur * widget.extent;
      final bottom = top + widget.extent;
      final p = c.position;
      if (bottom <= p.pixels) {
        side = QueueLocateSide.above;
      } else if (top >= p.pixels + p.viewportDimension) {
        side = QueueLocateSide.below;
      }
    }
    if (side != _side) setState(() => _side = side);
  }

  void _go() {
    final cur = widget.currentIndex;
    if (cur == null || !widget.controller.hasClients) return;
    final max = widget.controller.position.maxScrollExtent;
    widget.controller.animateTo(
      queueOffsetFor(cur, widget.extent).clamp(0, max),
      duration: KMotion.slow,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_side == QueueLocateSide.none) return const SizedBox.shrink();
    return SizedBox.square(
      dimension: QueueLocateButton.size,
      child: IconButton.filled(
        icon: Icon(
          _side == QueueLocateSide.above ? KIcons.arrowUp : KIcons.arrowDown,
        ),
        tooltip: AppLocalizations.of(context).playbackQueueLocate,
        onPressed: _go,
      ),
    );
  }
}
