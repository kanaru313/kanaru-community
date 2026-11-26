import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/domain/setting.dart';
import '../../platform/state/settings_providers.dart';

/// What the desktop shell's right panel shows. One at a time.
enum RightPanelKind { closed, queue, chat }

/// Last state of the right panel, restored at the next launch.
final Setting<RightPanelKind> rightPanelSetting = Setting<RightPanelKind>(
  'shell.right_panel',
  RightPanelKind.closed,
  decode: (json) {
    if (json is String) {
      for (final k in RightPanelKind.values) {
        if (k.name == json) return k;
      }
    }
    throw FormatException('Unknown right panel: $json');
  },
  encode: (v) => v.name,
);

final rightPanelSettingProvider = settingNotifierProvider(rightPanelSetting);

/// Opens and closes the right panel and remembers the state.
class RightPanel extends Notifier<RightPanelKind> {
  @override
  RightPanelKind build() => ref.read(rightPanelSettingProvider);

  /// Shows [kind].
  void show(RightPanelKind kind) {
    if (state == kind) return;
    state = kind;
    unawaited(ref.read(rightPanelSettingProvider.notifier).set(kind));
  }

  /// Opens [kind], or closes the panel when [kind] is already showing.
  void toggle(RightPanelKind kind) =>
      show(state == kind ? RightPanelKind.closed : kind);

  void close() => show(RightPanelKind.closed);
}

final rightPanelProvider = NotifierProvider<RightPanel, RightPanelKind>(
  RightPanel.new,
);
