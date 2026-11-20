import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_space.dart';
import 'k_clock_bar_painter.dart';

export 'k_clock_bar_painter.dart' show ClockBarPainter, KClockSegments;

const double _kHeldNumberAlpha = 0.55;

/// The big number grows with the text scale only up to this factor (the
/// board's 57 -> 78); past it the number is scaled down to fit instead.
const double _kMaxNumberScale = 1.4;

/// What the big number shows; decides its size and weight.
enum _NumberKind {
  /// "23:41", "3": one big figure group.
  figure,

  /// "2:05:09", "12:00:00": hours, minutes and seconds.
  longClock,

  /// "album này", "bài này": words, bold and smaller.
  words,
}

/// Kind by what the text is, not by its length: no digit = words, two or more
/// colons = long clock, anything else = figure.
_NumberKind _kindOf(String text) {
  if (!text.contains(RegExp(r'\d'))) return _NumberKind.words;
  return ':'.allMatches(text).length >= 2
      ? _NumberKind.longClock
      : _NumberKind.figure;
}

/// Size of the big number by kind and shell: 57 / 45 / 36 on touch shells,
/// 45 / 36 / 28 on desktop (figure, long clock, words).
double _numberSize(_NumberKind kind, {required bool desktop}) {
  final sizes = desktop ? const [45.0, 36.0, 28.0] : const [57.0, 45.0, 36.0];
  return sizes[kind.index];
}

/// Big thin number with a small label above, a progress bar under it and a
/// start / end text row (the sleep timer's running screen).
///
/// The bar shows [fraction] (0..1, clamped, NaN = 0) or, when [segments] is
/// set, one segment per track. [held] dims the number to 55 % and draws the
/// bar in `outline` (the count is paused). The number's size follows what
/// [bigText] is (a figure like `23:41`, a long clock like `2:05:09`, or words
/// like `album này`, which are bold) and it never clips: past 1.4 x text
/// scale, or on a narrow window, it shrinks to fit one line. The big number
/// is excluded from semantics; [statusLabel] is a hidden node with the
/// spoken state (minute precision from the caller). It is not a live region:
/// announcing changes is the caller's job.
///
/// [leading] and [trailing] (usually [KStepButton]s) sit on one line with the
/// big number, 16 dp from it; the number shrinks, the buttons never do.
class KClockProgress extends StatelessWidget {
  const KClockProgress({
    super.key,
    required this.label,
    required this.bigText,
    required this.statusLabel,
    this.fraction = 0,
    this.segments,
    this.startText,
    this.endText,
    this.held = false,
    this.leading,
    this.trailing,
  });

  final String label;
  final String bigText;
  final String statusLabel;
  final double fraction;
  final KClockSegments? segments;
  final String? startText;
  final String? endText;
  final bool held;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final kind = _kindOf(bigText);
    final numberStyle = theme.textTheme.displayLarge?.copyWith(
      fontSize: _numberSize(kind, desktop: desktop),
      fontWeight: kind == _NumberKind.words ? FontWeight.w700 : FontWeight.w400,
      height: 1.1,
      color: held
          ? scheme.onSurface.withValues(alpha: _kHeldNumberAlpha)
          : scheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final small = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final number = ExcludeSemantics(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          bigText,
          textAlign: TextAlign.center,
          maxLines: 1,
          textScaler: MediaQuery.textScalerOf(context)
              .clamp(maxScaleFactor: _kMaxNumberScale),
          style: numberStyle,
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        if (leading == null && trailing == null)
          number
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: KSpace.x4),
              ],
              Flexible(child: number),
              if (trailing != null) ...[
                const SizedBox(width: KSpace.x4),
                trailing!,
              ],
            ],
          ),
        Semantics(
          container: true,
          liveRegion: false,
          label: statusLabel,
          child: const SizedBox.shrink(),
        ),
        const SizedBox(height: KSpace.x3),
        ExcludeSemantics(
          child: SizedBox(
            height: desktop ? 6 : 8,
            child: CustomPaint(
              painter: ClockBarPainter(
                fraction: fraction,
                segments: segments,
                fill: held ? scheme.outline : scheme.primary,
                track: scheme.primary.withValues(alpha: 0.24),
              ),
            ),
          ),
        ),
        if (startText != null || endText != null) ...[
          const SizedBox(height: KSpace.x2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(startText ?? '', style: small)),
              const SizedBox(width: KSpace.x3),
              Flexible(
                child: Text(
                  endText ?? '',
                  textAlign: TextAlign.end,
                  style: small,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
