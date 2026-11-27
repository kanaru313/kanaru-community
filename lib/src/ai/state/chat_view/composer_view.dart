import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/conversation/ai_message.dart';
import '../../domain/conversation/parts.dart';
import '../../domain/loop/loop_state.dart';
import '../../domain/output/chat_readiness.dart';
import '../../domain/permission.dart';
import '../../domain/variables/variable_catalog.dart';
import '../chat_attachments.dart';
import '../chat_conversation_providers.dart';
import '../chat_messages_provider.dart';
import '../chat_providers.dart';
import '../chat_session.dart';
import 'composer_inputs.dart';

/// What the send button is for right now.
enum ComposerAction { send, stop }

/// The one note shown above the composer (the mockup shows one at a time).
sealed class ComposerNotice {
  const ComposerNotice();
}

/// The plugin has no API key. [installId] opens its settings page.
final class NoticeNeedsKey extends ComposerNotice {
  const NoticeNeedsKey(this.plugin, this.installId);

  final String plugin;
  final String installId;
}

final class NoticeNeedsModel extends ComposerNotice {
  const NoticeNeedsModel(this.plugin);

  final String plugin;
}

/// Other required settings of the plugin are empty ([titles] are their names).
final class NoticeNeedsConfig extends ComposerNotice {
  const NoticeNeedsConfig(this.plugin, this.installId, this.titles);

  final String plugin;
  final String installId;
  final List<String> titles;
}

/// The chat's plugin was uninstalled; the composer is locked.
final class NoticeRemoved extends ComposerNotice {
  const NoticeRemoved([this.plugin]);

  /// The plugin's name when the conversation recorded it (a plugin switch),
  /// else null.
  final String? plugin;
}

/// The chat's plugin was removed and installed again; the composer is locked.
final class NoticeReinstalled extends ComposerNotice {
  const NoticeReinstalled(this.plugin);

  final String? plugin;
}

/// An attached chip whose tool group is off: nothing can be sent.
final class NoticeStruckChip extends ComposerNotice {
  const NoticeStruckChip(this.chip);

  final ChipPart chip;
}

/// A send was refused because [issues] have no data. Nothing was sent and
/// the text stays.
final class NoticeMissingData extends ComposerNotice {
  const NoticeMissingData(this.issues);

  final List<SendIssue> issues;
}

/// A value is over the model's limit; the short version can be sent.
final class NoticeOversize extends ComposerNotice {
  const NoticeOversize(this.variables);

  final List<AiVariable> variables;
}

/// The message could not be stored; the text stays.
final class NoticeSendFailed extends ComposerNotice {
  const NoticeSendFailed();
}

/// A gentle note: the model gets no tools (never blocks).
final class NoticeNoTools extends ComposerNotice {
  const NoticeNoTools(this.model);

  final String model;
}

/// The notice a refused send leaves (missing data, oversize, failure); null
/// while there is none. Lives outside the widget so a panel swap keeps it.
class ComposerSendNotice extends Notifier<ComposerNotice?> {
  @override
  ComposerNotice? build() => null;

  void set(ComposerNotice notice) => state = notice;

  void clear() {
    if (state != null) state = null;
  }
}

final composerSendNoticeProvider =
    NotifierProvider<ComposerSendNotice, ComposerNotice?>(
      ComposerSendNotice.new,
    );

/// What the composer shows and which controls work, from the turn state, the
/// plugin's readiness and the chips.
///
/// Lock table: while the model streams or a tool runs, the button is Stop and
/// the pickers and prompt chips are locked; the field stays editable. While a
/// card waits for the user, everything stays on (a new message denies the
/// card). Sending needs a ready plugin and no struck chip.
class ComposerView {
  const ComposerView({
    required this.action,
    required this.canSend,
    required this.toolsRunning,
    required this.fieldEditable,
    required this.pluginPickerEnabled,
    required this.modelPickerEnabled,
    required this.permissionPickerEnabled,
    required this.promptChipsEnabled,
    required this.modelNeeded,
    required this.permission,
    this.notice,
    this.model,
    this.plugin,
    this.struckChips = const [],
  });

  final ComposerAction action;
  final bool canSend;

  /// A tool is running: Stop says the later calls will not run.
  final bool toolsRunning;
  final bool fieldEditable;
  final bool pluginPickerEnabled;
  final bool modelPickerEnabled;
  final bool permissionPickerEnabled;
  final bool promptChipsEnabled;

  /// No model is chosen: the model button reads "Chọn model".
  final bool modelNeeded;
  final AiPermission permission;
  final ComposerNotice? notice;

  /// The chat's own model, else its plugin's default; null when none.
  final String? model;
  final ChatPluginInfo? plugin;
  final List<ChipPart> struckChips;
}

/// The lock table and the notice of the composer, as a pure function.
///
/// [readiness] is null while it loads (nothing can be sent yet, no notice).
ComposerView deriveComposerView({
  required TurnState turn,
  required ChatReadiness? readiness,
  required AiPermission permission,
  ChatPluginInfo? plugin,
  String? model,
  List<ChipPart> struckChips = const [],
  ComposerNotice? sendNotice,
  String? removedPluginName,
}) {
  final locked = turn == TurnState.streaming || turn == TurnState.runningTools;
  final gone =
      readiness is ChatPluginRemoved || readiness is ChatPluginReinstalled;
  final canSend = !locked && readiness is ChatReady && struckChips.isEmpty;
  final tools = plugin != null && model != null
      ? plugin.spec.capabilitiesOf(model).tools
      : true;
  final notice =
      _readinessNotice(readiness, plugin, removedPluginName) ??
      (struckChips.isEmpty ? null : NoticeStruckChip(struckChips.first)) ??
      sendNotice ??
      (readiness is ChatReady && !tools ? NoticeNoTools(model) : null);
  return ComposerView(
    action: locked ? ComposerAction.stop : ComposerAction.send,
    canSend: canSend,
    toolsRunning: turn == TurnState.runningTools,
    fieldEditable: !gone,
    pluginPickerEnabled: !locked,
    modelPickerEnabled: !locked && !gone,
    permissionPickerEnabled: !locked,
    promptChipsEnabled: !locked,
    modelNeeded: readiness is ChatNeedsModel,
    permission: permission,
    notice: notice,
    model: model,
    plugin: plugin,
    struckChips: struckChips,
  );
}

ComposerNotice? _readinessNotice(
  ChatReadiness? readiness,
  ChatPluginInfo? plugin,
  String? removedPluginName,
) => switch (readiness) {
  ChatNeedsKey() when plugin != null => NoticeNeedsKey(
    plugin.name,
    plugin.installId,
  ),
  ChatNeedsModel() when plugin != null => NoticeNeedsModel(plugin.name),
  ChatNeedsConfig(:final titles) when plugin != null => NoticeNeedsConfig(
    plugin.name,
    plugin.installId,
    titles,
  ),
  ChatPluginRemoved() => NoticeRemoved(removedPluginName),
  ChatPluginReinstalled() => NoticeReinstalled(plugin?.name),
  _ => null,
};

/// [deriveComposerView] on the live session, conversation and settings.
final composerViewProvider = Provider<ComposerView>((ref) {
  final session = ref.watch(chatSessionProvider);
  final id = session.conversationId;
  final conversation = id == null
      ? null
      : ref.watch(chatConversationProvider(id)).value;
  final readiness = id == null
      ? null
      : ref.watch(chatReadinessProvider(id)).value;
  final plugins = ref.watch(chatPluginsProvider).value ?? const [];
  final installId = conversation?.installId;
  ChatPluginInfo? plugin;
  for (final p in plugins) {
    if (p.installId == installId) plugin = p;
  }
  // The name of a removed plugin is only known from the plugin switches the
  // conversation recorded.
  final removedName = id == null || readiness is! ChatPluginRemoved
      ? null
      : ref.watch(
          chatMessagesProvider(id)
              .select((m) => lastSwitchTarget(m.value?.messages)),
        );
  final settings = ref.watch(composerSettingsProvider);
  // Only the attached chips: the suggestions are written from a listener of
  // the page providers, and rebuilding on them rebuilt this provider twice in
  // one refresh pass.
  final attached = ref.watch(chatAttachmentsProvider.select((a) => a.attached));
  return deriveComposerView(
    turn: session.turnState,
    readiness: readiness,
    permission: conversation?.permission ?? AiPermission.ask,
    plugin: plugin,
    model: conversation?.model ?? plugin?.defaultModel,
    struckChips: [
      for (final c in attached)
        if (settings.isStruck(c)) c,
    ],
    sendNotice: ref.watch(composerSendNoticeProvider),
    removedPluginName: removedName,
  );
});

/// The plugin the conversation last switched to (from its switch dividers);
/// null when it never switched.
String? lastSwitchTarget(List<AiMessage>? messages) {
  if (messages == null) return null;
  for (final m in messages.reversed) {
    for (final p in m.parts) {
      if (p is EventPart) return p.toName;
    }
  }
  return null;
}
