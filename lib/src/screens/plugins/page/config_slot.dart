import 'package:flutter/scheduler.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Where the "Cài đặt của plugin" form sits on the page: between Chi tiết
/// and Kết nối. It scrolls into view and pulses the form's one section when
/// the error band's [Mở cấu hình] asks. Hidden (a plugin with no `config`
/// builds none) by the page, not here.
class ConfigSlot extends StatefulWidget {
  const ConfigSlot({super.key, required this.child});

  /// The settings form: exactly one section.
  final Widget child;

  @override
  State<ConfigSlot> createState() => ConfigSlotState();
}

class ConfigSlotState extends State<ConfigSlot> {
  final _pulse = GlobalKey<SetupSectionPulseState>();

  /// Scrolls the slot into view and plays one pulse. [animate] false jumps.
  Future<void> reveal({required bool animate}) async {
    await Scrollable.ensureVisible(
      context,
      duration: animate ? KMotion.normal : Duration.zero,
      alignment: 0.1,
    );
    if (!mounted) return;
    // Layout has moved on: pulse once the frame is drawn.
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => _pulse.currentState?.pulse(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SetupSectionPulse(key: _pulse, child: widget.child);
  }
}
