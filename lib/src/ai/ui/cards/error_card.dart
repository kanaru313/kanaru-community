import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/conversation/ai_message.dart';
import '../../domain/conversation/parts.dart';
import '../../domain/loop/driver_results.dart';
import '../../domain/output/ai_error_code.dart';
import '../../domain/output/chat_outcome.dart';
import '../../state/chat_session.dart';
import '../../state/chat_view/card_view.dart';
import '../../state/chat_view/chat_view_state.dart';
import '../../state/chat_view/composer_inputs.dart';
import '../../state/chat_view/message_view.dart';
import '../../state/chat_view/time_format.dart';
import '../../state/stored_error_card.dart';
import '../chat_host.dart';
import '../ai_settings_link.dart';
import '../composer/plugin_picker.dart';
import 'error_card_spec.dart';

final _log = Logger('ai.error_card');

/// The card under a failed or cut-off answer. One card per outcome of the
/// engine's table; the words never come from the provider. Only the newest
/// card of the latest turn is live (retry, countdown, settings, pickers); an
/// older one is read-only and counts nothing.
class ErrorCard extends ConsumerStatefulWidget {
  const ErrorCard({super.key, required this.message});

  final AiMessage message;

  @override
  ConsumerState<ErrorCard> createState() => _ErrorCardState();
}

class _ErrorCardState extends ConsumerState<ErrorCard> {
  /// A retry is on its way: a second tap must not start another.
  bool _retrying = false;

  Future<void> _retry() async {
    if (_retrying) return;
    _retrying = true;
    var started = false;
    try {
      started =
          await ref.read(chatSessionProvider.notifier).retry() is DriverStarted;
    } on Object catch (e, s) {
      _log.warning('retry failed: ${e.runtimeType}', e, s);
    }
    // A started turn adds a newer message, which makes this card read-only.
    if (!started && mounted) _retrying = false;
  }

  String _countdownLabel(AppLocalizations l10n, KCountdownLeft left) =>
      switch (left) {
        KCountdownSeconds(:final seconds) => l10n.aiChatCardRetryIn(seconds),
        KCountdownMinutes(:final minutes, :final seconds) =>
          seconds == 0
              ? l10n.aiChatCardRetryInMinutes(minutes)
              : l10n.aiChatCardRetryInMinutesSeconds(minutes, seconds),
        KCountdownAt(:final until) => l10n.aiChatCardRetryAt(chatClock(until)),
      };

  KActionCardAction? _action(
    BuildContext context,
    AppLocalizations l10n,
    ChatCardAction action,
  ) {
    final installId = widget.message.installId;
    final host = ref.read(chatHostProvider);
    return switch (action) {
      ChatCardAction.none => null,
      ChatCardAction.retry => KActionCardAction(
        label: l10n.aiChatMessagesRetry,
        onPressed: () => unawaited(_retry()),
      ),
      ChatCardAction.openPluginSettings => KActionCardAction(
        label: l10n.aiChatActionOpenPluginSettings,
        onPressed: () => host.openSettings(_pluginPage(installId)),
      ),
      ChatCardAction.openPlugin => KActionCardAction(
        label: l10n.aiChatActionOpenPlugin,
        onPressed: () => host.openSettings(_pluginPage(installId)),
      ),
      ChatCardAction.choosePlugin => KActionCardAction(
        label: l10n.aiChatActionPickPlugin,
        onPressed: () => unawaited(showPluginPicker(context, ref)),
      ),
      ChatCardAction.newConversation => KActionCardAction(
        label: l10n.aiChatNewTitle,
        onPressed: () => unawaited(
          ref.read(chatViewProvider.notifier).startNewConversation(),
        ),
      ),
      ChatCardAction.changeModel => KActionCardAction(
        label: l10n.aiChatActionChangeModel,
        onPressed: () =>
            ref.read(modelPickerRequestProvider.notifier).request(),
      ),
    };
  }

  String _pluginPage(String? installId) =>
      installId == null ? aiSettingsLocation : aiPluginPageLocation(installId);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = widget.message;
    final position = (conversationId: message.conversationId, seq: message.seq);
    final edges = ref.watch(chatTurnEdgesProvider(message.conversationId));
    final live =
        message.seq > edges.latestUserSeq && message.seq == edges.newestSeq;
    final liveView = ref.watch(chatLiveOutcomeProvider(position));
    final part = message.parts.whereType<ErrorPart>().firstOrNull;

    final stored = cardOfStoredError(
      code: part?.code ?? 'server',
      kind: part?.kind ?? 'server',
    );
    final kind = liveView?.card ?? stored.card;
    final installId = message.installId;
    final needsHost =
        kind == ChatCardKind.network || kind == ChatCardKind.hostNotAllowed;
    final host =
        liveView?.host ??
        (needsHost && installId != null
            ? ref.watch(chatCardHostProvider(installId)).value
            : null);
    final until = kind == ChatCardKind.rateLimited
        ? (part?.retryAt ?? liveView?.retryAt)
        : null;
    final counting = until != null && live;

    final spec = errorCardSpec(
      l10n,
      kind,
      ErrorCardNames(
        plugin:
            ref.watch(chatCardPluginNameProvider(installId)) ??
            l10n.aiChatErrPluginFallback,
        host: host,
        model: message.model,
        code: AiErrorCode.parse('ai:${part?.code ?? 'server'}').wire,
      ),
      countdown: counting,
      hasText: displayText(message).isNotEmpty,
    );
    if (spec == null) return const SizedBox.shrink();

    final action = _action(context, l10n, spec.action);
    final clock = ref.watch(chatCardClockProvider);
    return KActionCard(
      tone: KActionCardTone.error,
      icon: spec.icon,
      title: spec.title,
      subtitle: spec.body,
      readOnly: !live,
      actions: action == null ? const [] : [action],
      countdown:
          until != null && counting && spec.action == ChatCardAction.retry
          ? KActionCardCountdown(
              until: until,
              labelOf: (left) => _countdownLabel(l10n, left),
              readyAnnouncement: l10n.aiChatCardCanRetry,
              now: clock,
            )
          : null,
    );
  }
}
