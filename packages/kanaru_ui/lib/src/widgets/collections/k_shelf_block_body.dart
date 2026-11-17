part of 'k_shelf_block.dart';

/// Item row of a [KShelfBlock]: scrolls by mouse drag too, shows a grab
/// cursor (grabbing while a mouse button is held). Cards keep their own cursors.
class _BodyRow extends StatefulWidget {
  const _BodyRow({
    required this.itemCount,
    required this.itemBuilder,
    required this.itemWidth,
    required this.padding,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double itemWidth;
  final EdgeInsets padding;

  @override
  State<_BodyRow> createState() => _BodyRowState();
}

class _BodyRowState extends State<_BodyRow> {
  bool _dragging = false;

  void _setDragging(bool value) {
    if (mounted && _dragging != value) setState(() => _dragging = value);
  }

  @override
  Widget build(BuildContext context) {
    final base = ScrollConfiguration.of(context);
    final behavior = base.copyWith(
      scrollbars: false,
      dragDevices: {...base.dragDevices, PointerDeviceKind.mouse},
    );
    return MouseRegion(
      cursor: _dragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
      child: Listener(
        onPointerDown: (e) => _setDragging(e.kind == PointerDeviceKind.mouse),
        onPointerUp: (_) => _setDragging(false),
        onPointerCancel: (_) => _setDragging(false),
        child: ScrollConfiguration(
          behavior: behavior,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: widget.padding,
            itemCount: widget.itemCount,
            separatorBuilder: (_, _) => const KGap(KSpace.x3),
            itemBuilder: (context, i) => SizedBox(
              width: widget.itemWidth,
              child: widget.itemBuilder(context, i),
            ),
          ),
        ),
      ),
    );
  }
}
