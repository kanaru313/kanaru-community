import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_space.dart';

/// Chips on one line that never wraps: centred while they fit, a sideways
/// scroll when the parent is narrower, with the edges fading where more chips
/// are hidden. Gap 8 on touch shells, 6 on desktop. Chips are [KChip]s
/// (usually `dense`). Needs a bounded width (a Column with stretch, a sized
/// box); under an unbounded parent it asserts.
class KChipLine extends StatefulWidget {
  const KChipLine({super.key, required this.children, this.revealIndex});

  final List<Widget> children;

  /// Child to bring into view (centred) once, when the line first lays out and
  /// overflows (the chosen chip). Ignored while everything fits.
  final int? revealIndex;

  @override
  State<KChipLine> createState() => _KChipLineState();
}

/// Width of each edge fade (CSS `.smchips.over` mask, 28 px).
const double _fadeWidth = 28;

class _KChipLineState extends State<KChipLine> {
  final _scroll = ScrollController();
  final _revealKey = GlobalKey();

  // Keeps the scroll state when the fade mask is added or removed around it.
  final _scrollKey = GlobalKey();
  bool _more = false;

  @override
  void initState() {
    super.initState();
    if (widget.revealIndex == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final chip = _revealKey.currentContext;
      // Jump, not animate: it is the state the line opens in.
      if (chip != null && _scroll.hasClients) {
        Scrollable.ensureVisible(chip, alignment: 0.5);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // Runs after layout: overflow is only known once the extents are.
  bool _onMetrics(ScrollMetricsNotification n) {
    final more = n.metrics.maxScrollExtent > 0;
    if (more != _more) setState(() => _more = more);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final gap = FormFactor.of(context) == FormFactor.desktop
        ? KSpace.x1 + 2
        : KSpace.x2;
    return LayoutBuilder(
      builder: (context, box) =>
          NotificationListener<ScrollMetricsNotification>(
            onNotification: _onMetrics,
            child: ListenableBuilder(
              listenable: _scroll,
              builder: (context, child) {
                if (!_more || !_scroll.hasClients) return child!;
                final position = _scroll.position;
                final atStart = position.pixels <= 0;
                final atEnd = position.pixels >= position.maxScrollExtent;
                final fade = _fadeWidth / position.viewportDimension;
                const opaque = Color(0xFFFFFFFF);
                const clear = Color(0x00FFFFFF);
                return ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) => LinearGradient(
                    colors: [
                      atStart ? opaque : clear,
                      opaque,
                      opaque,
                      atEnd ? opaque : clear,
                    ],
                    stops: [0, fade, 1 - fade, 1],
                  ).createShader(rect),
                  child: child,
                );
              },
              child: SingleChildScrollView(
                key: _scrollKey,
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: box.maxWidth),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < widget.children.length; i++) ...[
                        if (i > 0) SizedBox(width: gap),
                        i == widget.revealIndex
                            ? KeyedSubtree(
                                key: _revealKey,
                                child: widget.children[i],
                              )
                            : widget.children[i],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }
}
