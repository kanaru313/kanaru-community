import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// The quick choices of the custom screen on one line that never wraps: a
/// horizontal scroll whose edges fade where more chips are hidden, opened
/// scrolled to the chosen chip. The chosen chip is tinted (no tick).
class SleepTimerPresetChips extends StatefulWidget {
  const SleepTimerPresetChips({
    super.key,
    required this.presets,
    required this.selected,
    required this.label,
    required this.tooltip,
    required this.onSelected,
  });

  final List<int> presets;

  /// The preset equal to the draft's value, if any.
  final int? selected;

  /// Text of a chip ("15 ph") and its tooltip ("15 phút").
  final String Function(int preset) label;
  final String Function(int preset) tooltip;
  final ValueChanged<int> onSelected;

  @override
  State<SleepTimerPresetChips> createState() => _SleepTimerPresetChipsState();
}

class _SleepTimerPresetChipsState extends State<SleepTimerPresetChips> {
  final _scroll = ScrollController();
  final _selectedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final chip = _selectedKey.currentContext;
      if (chip != null) {
        // Jump, not animate: it is the state the screen opens in.
        Scrollable.ensureVisible(chip, alignment: 0.5);
      }
      // The fades need to know whether the row overflows.
      setState(() {});
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _scroll,
      builder: (context, _) {
        final position = _scroll.hasClients ? _scroll.position : null;
        final more = position != null && position.maxScrollExtent > 0;
        final atStart = !more || position.pixels <= 0;
        final atEnd = !more || position.pixels >= position.maxScrollExtent;
        final fade = more ? KSpace.x4 / position.viewportDimension : 0.0;
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
          child: SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final p in widget.presets) ...[
                  if (p != widget.presets.first)
                    const SizedBox(width: KSpace.x2),
                  Tooltip(
                    message: widget.tooltip(p),
                    excludeFromSemantics: true,
                    child: KChip(
                      semanticLabel: widget.tooltip(p),
                      key: p == widget.selected ? _selectedKey : null,
                      dense: true,
                      selected: p == widget.selected,
                      label: Text(widget.label(p)),
                      onTap: () => widget.onSelected(p),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
