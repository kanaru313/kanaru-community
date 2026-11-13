import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

/// The page with a dock (selection bar, mini player) floating over its
/// bottom edge, with no ground of its own: the page scrolls behind it.
///
/// The dock's height is measured and added to the bottom `MediaQuery`
/// padding of the page, so a list that takes its padding from the media
/// query (a `ListView` or `GridView` with no `padding`) ends above the dock
/// instead of under it.
///
/// While [hidden] (the keyboard is open: the scaffold has shrunk the body,
/// so a dock pinned to its bottom would ride on top of the keyboard) the dock
/// is kept but not shown, and the page gets no room for it.
class MobileFloatingDock extends StatefulWidget {
  const MobileFloatingDock({
    super.key,
    required this.body,
    required this.dock,
    this.hidden = false,
  });

  final Widget body;
  final bool hidden;

  /// Pieces stacked bottom-up; each paints its own surface, the gaps between
  /// and around them stay see-through.
  final Widget dock;

  @override
  State<MobileFloatingDock> createState() => _MobileFloatingDockState();
}

class _MobileFloatingDockState extends State<MobileFloatingDock> {
  final GlobalKey _dockKey = GlobalKey();
  double _height = 0;

  @override
  void initState() {
    super.initState();
    _scheduleMeasure();
  }

  void _scheduleMeasure() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _dockKey.currentContext?.findRenderObject();
      final height = box is RenderBox && box.hasSize ? box.size.height : 0.0;
      if (height != _height) setState(() => _height = height);
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final inset = widget.hidden ? 0.0 : _height;
    return Stack(
      children: [
        Positioned.fill(
          child: MediaQuery(
            data: media.copyWith(
              padding: media.padding.copyWith(
                bottom: media.padding.bottom + inset,
              ),
            ),
            child: widget.body,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: NotificationListener<SizeChangedLayoutNotification>(
            onNotification: (_) {
              _scheduleMeasure();
              return false;
            },
            child: Offstage(
              offstage: widget.hidden,
              child: SizeChangedLayoutNotifier(
                child: KeyedSubtree(key: _dockKey, child: widget.dock),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
