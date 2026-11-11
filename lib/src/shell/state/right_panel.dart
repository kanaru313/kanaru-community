import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../extension/state/extension_providers.dart';
import '../../extension/state/registry_entries.dart';
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

/// The AI chat content of the right panel: the extension registry's panel
/// surface with id `chat`. The public build registers none (the chat is a Pro
/// surface), so this is null there and the AI button is dimmed.
final chatPanelSurfaceProvider = Provider<PanelSurface?>(
  (ref) => ref.watch(extensionRegistryProvider).panelSurface('chat'),
);

/// Opens and closes the right panel and remembers the state.
class RightPanel extends Notifier<RightPanelKind> {
  @override
  RightPanelKind build() {
    final saved = ref.read(rightPanelSettingProvider);
    // The chat was open last time but this build has no chat: start closed.
    if (saved == RightPanelKind.chat &&
        ref.read(chatPanelSurfaceProvider) == null) {
      return RightPanelKind.closed;
    }
    return saved;
  }

  /// Shows [kind]; a chat request is ignored when there is no chat.
  void show(RightPanelKind kind) {
    if (kind == RightPanelKind.chat &&
        ref.read(chatPanelSurfaceProvider) == null) {
      return;
    }
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
