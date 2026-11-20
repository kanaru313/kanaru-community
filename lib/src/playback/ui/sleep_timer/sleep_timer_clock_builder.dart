import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// How often the wall-clock texts ("đến 23:40") look at the clock again.
const sleepTimerClockRefresh = Duration(seconds: 15);

/// Builds with the current wall-clock time and again every
/// [sleepTimerClockRefresh], so a modal left open does not show a stale
/// "đến …". The timer stops with the widget. [clock] is for tests.
class SleepTimerClockBuilder extends StatefulWidget {
  const SleepTimerClockBuilder({super.key, required this.builder, this.clock});

  final Widget Function(BuildContext context, DateTime now) builder;
  final DateTime Function()? clock;

  @override
  State<SleepTimerClockBuilder> createState() => _SleepTimerClockBuilderState();
}

class _SleepTimerClockBuilderState extends State<SleepTimerClockBuilder> {
  Timer? _timer;

  DateTime _now() => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(sleepTimerClockRefresh, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _now());
}
