import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../layout/form_factor.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../k_gap.dart';
import '../k_icon_button.dart';
import '../k_modal_button.dart';
import '../k_segmented.dart';

/// Max width of a segmented control in a [KCustomiseSheetFrame] on desktop.
const double _segmentedMaxWidth = 420;

/// Content of a customise sheet (bottom or side, see `showKAdaptiveSheet`): a
/// [title] with a close button, a [preview] slot on the `surface` colour, an
/// optional [caption] under it, the option [children] (usually
/// [KSegmentedRow]s) and a "reset" button at the end.
///
/// Changes apply as they are made, so there is no confirm button. The reset
/// button is disabled while nothing differs from the default
/// ([resetEnabled] false) and does not ask first. The body scrolls when the
/// content (200 % text) is taller than the sheet.
class KCustomiseSheetFrame extends StatelessWidget {
  const KCustomiseSheetFrame({
    super.key,
    required this.title,
    required this.closeTooltip,
    required this.onClose,
    required this.preview,
    required this.children,
    required this.resetLabel,
    required this.resetEnabled,
    required this.onReset,
    this.caption,
  });

  final String title;

  /// Tooltip and spoken name of the ✕ button.
  final String closeTooltip;
  final VoidCallback onClose;

  /// Live preview of the option being changed.
  final Widget preview;

  /// Note under the preview (for example a behaviour of the chosen option).
  final String? caption;
  final List<Widget> children;
  final String resetLabel;
  final bool resetEnabled;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(
            start: KSpace.x6,
            end: KSpace.x2,
            top: desktop ? KSpace.x4 : KSpace.x1,
            bottom: KSpace.x1,
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              KIconButton(
                icon: KIcons.close,
                tooltip: closeTooltip,
                padding: const EdgeInsets.all(KSpace.x2),
                onPressed: onClose,
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              KSpace.x6,
              KSpace.x1,
              KSpace.x6,
              KSpace.x6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: KRadius.lg,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      KSpace.x3,
                      KSpace.x3,
                      KSpace.x3,
                      KSpace.x2,
                    ),
                    child: preview,
                  ),
                ),
                if (caption != null) ...[
                  const KGap(KSpace.x2),
                  Text(
                    caption!,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                ...children,
                const KGap(KSpace.x3),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: KModalButton(
                    label: resetLabel,
                    emphasis: KModalEmphasis.secondary,
                    onPressed: resetEnabled ? onReset : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// One option row of a customise sheet: its [title] over a [KSegmented] (48 dp
/// on touch shells, 40 on desktop, up to 420 wide). Tonal chosen segment, no
/// tick.
class KSegmentedRow<T> extends StatelessWidget {
  const KSegmentedRow({
    super.key,
    required this.title,
    required this.segments,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final List<KSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KSpace.x2 + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodyLarge),
          const KGap(KSpace.x2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _segmentedMaxWidth),
            child: KSegmented<T>(
              segments: segments,
              value: value,
              onChanged: onChanged,
              semanticLabel: title,
              comfortable: true,
            ),
          ),
        ],
      ),
    );
  }
}
