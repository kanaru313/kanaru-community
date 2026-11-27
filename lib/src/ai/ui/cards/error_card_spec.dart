import 'package:flutter/widgets.dart' show IconData;
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/output/chat_outcome.dart';

/// What an error card says and offers, for one [ChatCardKind]. Pure: no
/// widgets, so every row of the outcome table is tested by reading it.
class ErrorCardSpec {
  const ErrorCardSpec({
    required this.icon,
    required this.title,
    required this.body,
    this.action = ChatCardAction.none,
  });

  final IconData icon;
  final String title;
  final String body;

  /// The one button the card offers ([ChatCardAction.none]: no button).
  final ChatCardAction action;
}

/// The words around an error card: the plugin and model it names.
class ErrorCardNames {
  const ErrorCardNames({
    required this.plugin,
    this.host,
    this.model,
    this.code = 'server',
  });

  /// The chat plugin's name, or the generic "Plugin" when it is gone.
  final String plugin;

  /// The host a network or permission card names, when known.
  final String? host;

  /// The model of the failed message.
  final String? model;

  /// The contract code shown on the generic card ("mã: server").
  final String code;
}

/// The card of [kind], or null for a kind that draws no error card
/// ([ChatCardKind.stopped], and [ChatCardKind.limitReached], which has its own
/// card). [countdown]: the card counts down to a retry, so its body speaks of
/// the countdown.
ErrorCardSpec? errorCardSpec(
  AppLocalizations l10n,
  ChatCardKind kind,
  ErrorCardNames names, {
  bool countdown = false,
}) {
  final plugin = names.plugin;
  final model = names.model ?? plugin;
  const retry = ChatCardAction.retry;
  switch (kind) {
    case ChatCardKind.stopped:
    case ChatCardKind.limitReached:
      return null;
    case ChatCardKind.network:
      final host = names.host;
      return ErrorCardSpec(
        icon: KIcons.offline,
        title: host == null
            ? l10n.aiChatErrNetworkTitleNoHost
            : l10n.aiChatErrNetworkTitle(host),
        body: l10n.aiChatErrNetworkBody,
        action: retry,
      );
    case ChatCardKind.rateLimited:
      return ErrorCardSpec(
        icon: KIcons.duration,
        title: l10n.aiChatErrRateTitle(plugin),
        body: countdown
            ? l10n.aiChatErrRateBody
            : l10n.aiChatErrRateBodyNoClock,
        action: retry,
      );
    case ChatCardKind.previousTurnBusy:
      return ErrorCardSpec(
        icon: KIcons.duration,
        title: l10n.aiChatErrBusyTitle,
        body: l10n.aiChatErrBusyBody,
        action: retry,
      );
    case ChatCardKind.previousTurnStuck:
      return ErrorCardSpec(
        icon: KIcons.refresh,
        title: l10n.aiChatErrBusyStuckTitle,
        body: l10n.aiChatErrBusyStuckBody,
        action: retry,
      );
    case ChatCardKind.badKey:
      return ErrorCardSpec(
        icon: KIcons.permission,
        title: l10n.aiChatErrKeyTitle(plugin),
        body: l10n.aiChatErrKeyBody,
        action: ChatCardAction.openPluginSettings,
      );
    case ChatCardKind.quota:
      return ErrorCardSpec(
        icon: KIcons.warning,
        title: l10n.aiChatErrQuotaTitle(plugin),
        body: l10n.aiChatErrQuotaBody,
        action: retry,
      );
    case ChatCardKind.config:
    case ChatCardKind.needsConfig:
      return ErrorCardSpec(
        icon: KIcons.settings,
        title: l10n.aiChatErrConfigTitle(plugin),
        body: l10n.aiChatErrConfigBody,
        action: ChatCardAction.openPluginSettings,
      );
    case ChatCardKind.modelNotFound:
      final named = names.model;
      return ErrorCardSpec(
        icon: KIcons.warning,
        title: named == null
            ? l10n.aiChatErrModelGoneTitleNoModel
            : l10n.aiChatErrModelGoneTitle(named),
        body: l10n.aiChatErrModelGoneBody(plugin),
        action: ChatCardAction.changeModel,
      );
    case ChatCardKind.contextLength:
      return ErrorCardSpec(
        icon: KIcons.warning,
        title: l10n.aiChatErrContextTitle,
        body: l10n.aiChatErrContextBody(model),
        action: ChatCardAction.newConversation,
      );
    case ChatCardKind.tooLarge:
      return ErrorCardSpec(
        icon: KIcons.warning,
        title: l10n.aiChatErrTooLargeTitle,
        body: l10n.aiChatErrTooLargeBody,
        action: ChatCardAction.newConversation,
      );
    case ChatCardKind.blocked:
      return ErrorCardSpec(
        icon: KIcons.cancel,
        title: l10n.aiChatErrBlockedTitle,
        body: l10n.aiChatErrBlockedBody(model),
        action: retry,
      );
    case ChatCardKind.empty:
      return ErrorCardSpec(
        icon: KIcons.warning,
        title: l10n.aiChatErrEmptyTitle,
        body: l10n.aiChatErrEmptyBody(model),
        action: retry,
      );
    case ChatCardKind.hostNotAllowed:
      final host = names.host;
      return ErrorCardSpec(
        icon: KIcons.online,
        title: host == null
            ? l10n.aiChatErrHostTitleNoHost
            : l10n.aiChatErrHostTitle(host),
        body: l10n.aiChatErrHostBody,
      );
    case ChatCardKind.pluginUpdated:
      return ErrorCardSpec(
        icon: KIcons.integrations,
        title: l10n.aiChatErrUpdatedTitle,
        body: l10n.aiChatErrUpdatedBody(plugin),
        action: retry,
      );
    case ChatCardKind.pluginRemoved:
      return ErrorCardSpec(
        icon: KIcons.integrations,
        title: l10n.aiChatErrRemovedTitle,
        body: l10n.aiChatErrRemovedBody(plugin),
        action: ChatCardAction.choosePlugin,
      );
    case ChatCardKind.pluginBroken:
      return ErrorCardSpec(
        icon: KIcons.warning,
        title: l10n.aiChatErrBrokenTitle,
        body: l10n.aiChatErrBrokenBody(plugin),
        action: ChatCardAction.openPlugin,
      );
    case ChatCardKind.timeout:
      return ErrorCardSpec(
        icon: KIcons.duration,
        title: l10n.aiChatErrTimeoutTitle,
        body: l10n.aiChatErrTimeoutBody(plugin),
        action: retry,
      );
    case ChatCardKind.pluginError:
      return ErrorCardSpec(
        icon: KIcons.warning,
        title: l10n.aiChatErrCrashTitle,
        body: l10n.aiChatErrCrashBody(plugin),
        action: retry,
      );
    case ChatCardKind.interrupted:
      return ErrorCardSpec(
        icon: KIcons.refresh,
        title: l10n.aiChatErrCutOffTitle,
        body: l10n.aiChatErrCutOffBody,
        action: retry,
      );
    case ChatCardKind.badRequest:
    case ChatCardKind.server:
      return ErrorCardSpec(
        icon: KIcons.warning,
        title: l10n.aiChatErrGenericTitle(plugin),
        body: l10n.aiChatErrGenericBody(names.code),
        action: retry,
      );
  }
}
