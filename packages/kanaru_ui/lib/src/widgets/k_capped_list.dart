import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_motion.dart';

/// A list inside a long page (a chat) that never takes more than
/// [maxVisible] rows of height. Up to [maxVisible] rows it is a plain column
/// at full height. Longer, it is a box exactly [maxVisible] rows tall that
/// scrolls on its own and builds only the rows in view (fixed [rowExtent], so
/// the box height and the offsets need no measuring).
///
/// Cues: a [fadeExtent] fade at the bottom while rows remain below and at the
/// top once scrolled; a thin scrollbar on the desktop shell. At either end of
/// the box a drag or a wheel turn goes on to the surrounding scrollable.
class KCappedList extends StatefulWidget {
  const KCappedList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.rowExtent,
    this.gap = 2,
    this.maxVisible = 8,
    this.semanticLabel,
  }) : assert(itemCount >= 0),
       assert(rowExtent > 0),
       assert(gap >= 0),
       assert(maxVisible > 0);

  final int itemCount;

  /// Builds row [index]; it is laid out [rowExtent] tall.
  final IndexedWidgetBuilder itemBuilder;

  /// Height of every row. Callers scale it with the text size.
  final double rowExtent;

  /// Space between two rows.
  final double gap;

  /// Rows shown before the list gets its own box and scroll.
  final int maxVisible;

  /// Read by screen readers for the whole list.
  final String? semanticLabel;

  /// Height of the fade at an edge of the box.
  static const double fadeExtent = 24;

  /// Present in the tree while the top fade is on (the list has been scrolled).
  static const Key topFadeKey = ValueKey('KCappedList.topFade');

  /// Present in the tree while the bottom fade is on (rows remain below).
  static const Key bottomFadeKey = ValueKey('KCappedList.bottomFade');

  /// Height of the box for [rows] rows: the rows and the gaps between them.
  static double heightFor(int rows, double rowExtent, double gap) =>
      rows * rowExtent + (rows > 0 ? rows - 1 : 0) * gap;

  @override
  State<KCappedList> createState() => _KCappedListState();
}

class _KCappedListState extends State<KCappedList> {
  final _controller = ScrollController();
  bool _before = false;
  bool _after = true;

  bool get _capped => widget.itemCount > widget.maxVisible;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncFades);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_syncFades)
      ..dispose();
    super.dispose();
  }

  void _syncFades() {
    if (!_controller.hasClients) return;
    final p = _controller.position;
    final before = p.pixels > 0.5;
    final after = p.extentAfter > 0.5;
    if (before != _before || after != _after) {
      setState(() {
        _before = before;
        _after = after;
      });
    }
  }

  /// A drag that runs past an end of the box moves the surrounding
  /// scrollable by the same amount (the wheel already falls through: a
  /// scrollable that cannot move does not claim the event).
  bool _handOff(OverscrollNotification n, ScrollableState? outer) {
    if (outer == null || n.dragDetails == null || n.depth != 0) return false;
    final o = outer.position;
    final target = (o.pixels + n.overscroll).clamp(
      o.minScrollExtent,
      o.maxScrollExtent,
    );
    if (target != o.pixels) o.jumpTo(target);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.rowExtent;
    final gap = widget.gap;
    if (!_capped) {
      return Semantics(
        container: true,
        label: widget.semanticLabel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: gap,
          children: [
            for (var i = 0; i < widget.itemCount; i++)
              SizedBox(height: row, child: widget.itemBuilder(context, i)),
          ],
        ),
      );
    }
    final height = KCappedList.heightFor(widget.maxVisible, row, gap);
    final outer = Scrollable.maybeOf(context);
    final instant = MediaQuery.disableAnimationsOf(context);
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    // No platform scrollbar: the desktop one is placed here, mobile has none.
    final behavior = ScrollConfiguration.of(
      context,
    ).copyWith(scrollbars: false, dragDevices: {...PointerDeviceKind.values});
    Widget list = ScrollConfiguration(
      behavior: behavior,
      child: ListView.builder(
        controller: _controller,
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemExtent: row + gap,
        cacheExtent: (row + gap) * 2,
        itemCount: widget.itemCount,
        itemBuilder: (context, i) => Padding(
          padding: EdgeInsets.only(bottom: gap),
          child: SizedBox(height: row, child: widget.itemBuilder(context, i)),
        ),
      ),
    );
    if (desktop) {
      list = Scrollbar(
        controller: _controller,
        thickness: 4,
        radius: const Radius.circular(2),
        child: list,
      );
    }
    final fadeTop = _before ? 1.0 : 0.0;
    final fadeBottom = _after ? 1.0 : 0.0;
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: NotificationListener<OverscrollNotification>(
          onNotification: (n) => _handOff(n, outer),
          child: Stack(
            children: [
              Positioned.fill(
                child: TweenAnimationBuilder<(double, double)>(
                  tween: _PairTween(end: (fadeTop, fadeBottom)),
                  duration: instant ? Duration.zero : KMotion.fast,
                  curve: KMotion.emphasized,
                  child: list,
                  builder: (context, v, child) => ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (rect) {
                      final f = KCappedList.fadeExtent / rect.height;
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0, f, 1 - f, 1],
                        colors: [
                          Color.fromRGBO(0, 0, 0, 1 - v.$1),
                          const Color(0xFF000000),
                          const Color(0xFF000000),
                          Color.fromRGBO(0, 0, 0, 1 - v.$2),
                        ],
                      ).createShader(rect);
                    },
                    child: child,
                  ),
                ),
              ),
              if (_before) const SizedBox.shrink(key: KCappedList.topFadeKey),
              if (_after) const SizedBox.shrink(key: KCappedList.bottomFadeKey),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tweens the two fade amounts together.
class _PairTween extends Tween<(double, double)> {
  _PairTween({required (double, double) end}) : super(end: end);

  @override
  (double, double) lerp(double t) {
    final a = begin ?? end!;
    final b = end!;
    return (a.$1 + (b.$1 - a.$1) * t, a.$2 + (b.$2 - a.$2) * t);
  }
}
