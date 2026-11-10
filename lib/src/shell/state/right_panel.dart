import 'dart:async';

import 'package:flutter/widgets.dart';
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

/// The AI chat content of the right panel. The public build has none (the
/// chat is a Pro surface); the Pro build overrides [chatPanelSurfaceProvider].
class ChatPanelSurface {
  const ChatPanelSurface({required this.body, this.menu});

  /// The chat itself, filling the panel under its header.
  final WidgetBuilder body;

  /// The header's ⋮ button (the chat's own menu); none shows no button.
  final WidgetBuilder? menu;
}

final chatPanelSurfaceProvider = Provider<ChatPanelSurface?>((ref) => null);

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
