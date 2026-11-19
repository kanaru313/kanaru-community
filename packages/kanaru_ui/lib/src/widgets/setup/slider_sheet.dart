import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../layout/form_factor.dart';
import '../../tokens/k_layout.dart';
import '../../tokens/k_motion.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../anchored_panel_layout.dart';
import '../k_focus_ring.dart';
import '../k_gap.dart';
import '../k_sheet.dart';

/// One slider of [showSliderSheet], over a fixed list of [stops].
///
/// The thumb snaps to the stops by index, so the stops may be unevenly spaced
/// (1 MB, 1.5 MB, 2 MB, ...). [value] must be one of [stops]. [liveLabel]
/// names a stop ("45 s", "Off") and is shown bold above the slider while
/// dragging; [minLabel] and [maxLabel] sit under its two ends. [onCommitted]
/// runs once when the user lets go (or after a keyboard step), never while
/// dragging.
class KStopSliderSpec<T> implements KSliderSpec {
  KStopSliderSpec({
    required this.stops,
    required this.value,
    required this.liveLabel,
    required this.minLabel,
    required this.maxLabel,
    required this.onCommitted,
  }) : assert(stops.length >= 2, 'a slider needs at least two stops'),
       assert(stops.contains(value), 'value must be one of the stops');

  final List<T> stops;
  final T value;
  final String Function(T stop) liveLabel;
  final String minLabel;
  final String maxLabel;
  final ValueChanged<T> onCommitted;

  @override
  Widget build({bool autofocus = false}) =>
      _StopSlider<T>(spec: this, autofocus: autofocus);
}

/// Type-erased view of a [KStopSliderSpec], so one sheet can hold sliders of
/// different value types (seconds and percent).
abstract interface class KSliderSpec {
  /// [autofocus] puts keyboard focus on the slider as soon as it shows.
  Widget build({bool autofocus = false});
}

/// Sheet (mobile) or anchored panel (desktop, under [anchor]; a centred
/// dialog without one) with a [title], an optional [caption] and one or two
/// stop sliders. There is no button: letting go of a slider saves.
/// Completes when the sheet closes.
Future<void> showSliderSheet(
  BuildContext context, {
  required Widget title,
  Widget? caption,
  required List<KSliderSpec> sliders,
  GlobalKey? anchor,
  KAnchorAlign anchorAlign = KAnchorAlign.start,
}) {
  assert(
    sliders.isNotEmpty && sliders.length <= 2,
    'a slider sheet holds one or two sliders',
  );
  Widget body(BuildContext _) =>
      _SliderSheetBody(title: title, caption: caption, sliders: sliders);
  if (FormFactor.of(context) == FormFactor.mobile) {
    return showKSheet<void>(context, builder: body);
  }
  final rect = AnchoredPanelLayout.rectOf(anchor);
  if (rect == null) {
    return showDialog<void>(
      context: context,
      animationStyle: KMotion.routeAnimationStyle(context),
      builder: (context) => Dialog(
        shape: KShape.of(KRadius.xl, continuous: true),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: KLayout.dialog),
          child: body(context),
        ),
      ),
    );
  }
  return showDialog<void>(
    context: context,
    animationStyle: KMotion.routeAnimationStyle(context),
    useSafeArea: false,
    barrierColor: const Color(0x00000000),
    builder: (context) => CustomSingleChildLayout(
      delegate: AnchoredPanelLayout(rect, align: anchorAlign),
      child: Material(
        elevation: 3,
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        shape: KShape.of(KRadius.lg, continuous: true),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: KLayout.dialog),
          child: body(context),
        ),
      ),
    ),
  );
}

class _SliderSheetBody extends StatelessWidget {
  const _SliderSheetBody({
    required this.title,
    required this.caption,
    required this.sliders,
  });

  final Widget title;
  final Widget? caption;
  final List<KSliderSpec> sliders;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        KSpace.x6,
        KSpace.x4,
        KSpace.x6,
        KSpace.x4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DefaultTextStyle.merge(
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            child: title,
          ),
          if (caption != null) ...[
            const KGap(KSpace.x1),
            DefaultTextStyle.merge(
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              child: caption!,
            ),
          ],
          for (var i = 0; i < sliders.length; i++) ...[
            const KGap(KSpace.x4),
            sliders[i].build(autofocus: i == 0),
          ],
        ],
      ),
    );
  }
}

class _StopSlider<T> extends StatefulWidget {
  const _StopSlider({required this.spec, required this.autofocus});

  final KStopSliderSpec<T> spec;
  final bool autofocus;

  @override
  State<_StopSlider<T>> createState() => _StopSliderState<T>();
}

class _StopSliderState<T> extends State<_StopSlider<T>> {
  late int _index = widget.spec.stops.indexOf(widget.spec.value);
  bool _focused = false;

  int get _last => widget.spec.stops.length - 1;

  /// Moves to [index] and saves it (a keyboard jump).
  void _jump(int index) {
    setState(() => _index = index);
    widget.spec.onCommitted(widget.spec.stops[index]);
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final small = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          spec.liveLabel(spec.stops[_index]),
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onFocusChange: (v) => setState(() => _focused = v),
          child: KFocusRing(
            focused: _focused,
            radius: KRadius.sm,
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.home): () => _jump(0),
                const SingleActivator(LogicalKeyboardKey.end): () =>
                    _jump(_last),
              },
              child: Slider(
                autofocus: widget.autofocus,
                value: _index.toDouble(),
                max: _last.toDouble(),
                divisions: _last,
                semanticFormatterCallback: (v) =>
                    spec.liveLabel(spec.stops[v.round()]),
                onChanged: (v) => setState(() => _index = v.round()),
                onChangeEnd: (v) => spec.onCommitted(spec.stops[v.round()]),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(spec.minLabel, style: small)),
            const KGap(KSpace.x2),
            Flexible(
              child: Text(
                spec.maxLabel,
                style: small,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
