import 'package:flutter/scheduler.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../settings/ui/library/settings_focus_pulse.dart';
import '../../settings/ui/soon_row.dart';

/// Where the "Cài đặt của plugin" form sits on the page: between Chi tiết
/// and Kết nối. Until the form exists ([child] null) it shows the section
/// with one dimmed "Sắp có" row, so the error band's [Mở cấu hình] has
/// something visible to scroll to and pulse. Hidden (a plugin with no
/// `config` builds none) by the page, not here.
class ConfigSlot extends StatefulWidget {
  const ConfigSlot({super.key, this.child});

  /// The settings form; null shows the placeholder section.
  final Widget? child;

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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsFocusPulse(
      key: _pulse,
      child:
          widget.child ??
          SetupSection(
            title: Text(l10n.pluginsPageSettingsTitle),
            children: [
              SoonRow(
                icon: KIcons.settings,
                title: Text(l10n.pluginsPageSettingsSoon),
              ),
            ],
          ),
    );
  }
}
