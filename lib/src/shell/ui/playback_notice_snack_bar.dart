import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// Floating snack bar with a sentence that changes every second and an action
/// that is disabled while [remaining] is above zero. Used by the rate-limit
/// pause notice: the bar stays until the count ends (plus [lingerAfterEnd]),
/// not the usual 4 s. It replaces the snack bar on screen and
/// never shows a close button or an icon,, like the other notices.
void showCountdownSnackBar(
  BuildContext context, {
  required String Function(Duration remaining) sentence,
  required Duration remaining,
  required String actionLabel,
  required VoidCallback onAction,
  Duration lingerAfterEnd = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: _CountdownContent(
        sentence: sentence,
        remaining: remaining,
        actionLabel: actionLabel,
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
  });

  final String Function(Duration remaining) sentence;
  final Duration remaining;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  State<_CountdownContent> createState() => _CountdownContentState();
}

class _CountdownContentState extends State<_CountdownContent> {
  static const _tick = Duration(seconds: 1);
  late Duration _remaining = widget.remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (_remaining > Duration.zero) {
      _timer = Timer.periodic(_tick, (_) {
        if (!mounted) return;
        setState(() {
          _remaining -= _tick;
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
    final text = widget.sentence(_remaining);
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
          text: TextSpan(text: text, style: style),
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
              Expanded(child: Text(text)),
              button,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text),
            Align(alignment: Alignment.centerRight, child: button),
          ],
        );
      },
    );
  }
}
