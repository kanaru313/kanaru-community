import 'package:flutter/scheduler.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../settings/ui/library/settings_focus_pulse.dart';

/// Where the "Cài đặt của plugin" form sits on the page: between Chi tiết
/// and Kết nối. It holds nothing yet (the form fills [child] later); the
/// error band's [Mở cấu hình] scrolls here and pulses it. Hidden (a plugin
/// with no `config` builds none) by the page, not here.
class ConfigSlot extends StatefulWidget {
  const ConfigSlot({super.key, this.child = const SizedBox.shrink()});

  final Widget child;

  @override
  State<ConfigSlot> createState() => ConfigSlotState();
}

class ConfigSlotState extends State<ConfigSlot> {
  final _pulse = GlobalKey<SettingsFocusPulseState>();

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
  Widget build(BuildContext context) =>
      SettingsFocusPulse(key: _pulse, child: widget.child);
}
