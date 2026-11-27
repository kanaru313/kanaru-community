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
    final sentence = widget.sentence(_remaining);
    final button = TextButton(
      onPressed: enabled ? widget.onAction : null,
      style: TextButton.styleFrom(
        foregroundColor: color,
        disabledForegroundColor: color.withValues(alpha: 0.38),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      child: Text(widget.actionLabel),
    );
    // Sentence and button on one line while they fit, the button below (at
    // the end) when the text is long, the window narrow or the font large.
    return LayoutBuilder(
      builder: (context, box) {
        final style = DefaultTextStyle.of(context).style;
        final scaler = MediaQuery.textScalerOf(context);
        final painter = TextPainter(
          text: TextSpan(text: sentence, style: style),
          textDirection: Directionality.of(context),
          textScaler: scaler,
        )..layout();
        final label = TextPainter(
          text: TextSpan(text: widget.actionLabel, style: style),
          textDirection: Directionality.of(context),
          textScaler: scaler,
        )..layout();
        final buttonWidth = label.width + 24 + 16;
        final fits = painter.width + buttonWidth <= box.maxWidth;
        painter.dispose();
        label.dispose();
        if (fits) {
          return Row(
            children: [
              Expanded(child: text),
              button,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            text,
            Align(alignment: Alignment.centerRight, child: button),
          ],
        );
      },
    );
  }
}
