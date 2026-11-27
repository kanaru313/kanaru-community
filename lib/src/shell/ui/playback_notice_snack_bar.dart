import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// Monotonic time source; a test passes its own to move time in big jumps.
typedef MonotonicNow = Duration Function();

final Stopwatch _monotonic = Stopwatch()..start();

/// Time since the first use of the countdown clock; never goes back.
Duration systemMonotonicNow() => _monotonic.elapsed;

/// Floating snack bar with a sentence that changes every second and an action
/// that is disabled while [remaining] is above zero. Used by the rate-limit
/// pause notice: the bar stays until the count ends plus [lingerAfterEnd]
/// instead of the usual 4 s. The count follows a deadline on a monotonic
/// clock, so a delayed timer never leaves the text or the button behind real
/// time. It replaces the snack bar on screen and never shows a close button or
/// an icon, like the other notices.
void showCountdownSnackBar(
  BuildContext context, {
  required String Function(Duration remaining) sentence,
  required Duration remaining,
  required String actionLabel,
  required VoidCallback onAction,
  Duration lingerAfterEnd = const Duration(seconds: 4),
  MonotonicNow now = systemMonotonicNow,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: _CountdownContent(
        sentence: sentence,
        remaining: remaining,
        actionLabel: actionLabel,
        now: now,
        onAction: () {
          messenger.hideCurrentSnackBar();
          onAction();
        },
      ),
      duration: remaining + lingerAfterEnd,
      persist: false,
      behavior: SnackBarBehavior.floating,
      // Start padding only: the action sits flush at the end like SnackBarAction.
      padding: const EdgeInsetsDirectional.only(start: 16),
    ),
  );
}

class _CountdownContent extends StatefulWidget {
  const _CountdownContent({
    required this.sentence,
    required this.remaining,
    required this.actionLabel,
    required this.onAction,
    required this.now,
  });

  final MonotonicNow now;
  final String Function(Duration remaining) sentence;
  final Duration remaining;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  State<_CountdownContent> createState() => _CountdownContentState();
}

class _CountdownContentState extends State<_CountdownContent> {
  static const _tick = Duration(seconds: 1);
  // SnackBar's floating metrics.
  static const _barPadding = 16.0;
  static const _actionMargin = 8.0;
  static const _verticalPadding = 14.0;
  static const _defaultThreshold = 0.25;
  late final Duration _deadline;
  late Duration _remaining = widget.remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _deadline = widget.now() + widget.remaining;
    if (_remaining > Duration.zero) {
      _timer = Timer.periodic(_tick, (_) {
        if (!mounted) return;
        setState(() {
          _remaining = _deadline - widget.now();
          if (_remaining <= Duration.zero) {
            _remaining = Duration.zero;
            _timer?.cancel();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.inversePrimary;
    final enabled = _remaining <= Duration.zero;
    // The ended sentence is announced once, when the count reaches zero.
    final text = Semantics(
      liveRegion: enabled,
      child: Text(widget.sentence(_remaining)),
    );
    final button = Padding(
      padding: const EdgeInsets.symmetric(horizontal: _actionMargin),
      child: TextButton(
        onPressed: enabled ? widget.onAction : null,
        style: TextButton.styleFrom(
          foregroundColor: color,
          disabledForegroundColor: color.withValues(alpha: 0.38),
          padding: const EdgeInsets.symmetric(horizontal: _barPadding),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
        child: Text(widget.actionLabel),
      ),
    );
    final threshold =
        SnackBarTheme.of(context).actionOverflowThreshold ?? _defaultThreshold;
    // Material's own rule (SnackBar): the action goes below the sentence only
    // when its width is above [threshold] of the bar's width, so a wrapped
    // sentence keeps the action on its right. The bar has start padding only;
    // the end of the bar is the end of this content.
    return LayoutBuilder(
      builder: (context, box) {
        final label = TextPainter(
          text: TextSpan(
            text: widget.actionLabel,
            style: theme.textTheme.labelLarge,
          ),
          maxLines: 1,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        final actionWidth = label.width + _actionMargin;
        label.dispose();
        final barWidth = box.maxWidth + _barPadding;
        final below = actionWidth / barWidth > threshold;
        const vertical = EdgeInsets.symmetric(vertical: _verticalPadding);
        if (!below) {
          return Row(
            children: [
              Expanded(
                child: Padding(padding: vertical, child: text),
              ),
              button,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: vertical.copyWith(bottom: 0), child: text),
            Padding(
              padding: const EdgeInsets.only(bottom: _verticalPadding),
              child: Align(alignment: Alignment.centerRight, child: button),
            ),
          ],
        );
      },
    );
  }
}
