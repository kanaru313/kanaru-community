import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/conversation/ai_message.dart';
import '../../domain/loop/card_results.dart' show callOf;
import '../../domain/loop/driver_results.dart';
import '../../state/chat_session.dart';
import '../../state/chat_view/card_view.dart';
import '../tool_text.dart';
import 'card_texts.dart';
import 'track_rows_preview.dart';

final _log = Logger('ai.confirm_card');

/// The card of a write the assistant asks to make (Ask mode): what it would
/// do, the songs it touches and [Từ chối] [Cho phép]. Only the card of the
/// latest turn answers; once the user allowed it (the call waits its turn)
/// the card shows no buttons.
class ConfirmCard extends ConsumerStatefulWidget {
  const ConfirmCard({super.key, required this.message});

  final AiMessage message;

  @override
  ConsumerState<ConfirmCard> createState() => _ConfirmCardState();
}

class _ConfirmCardState extends ConsumerState<ConfirmCard> {
  /// An answer is on its way: a second tap (double click, Allow then Deny)
  /// must not send another.
  bool _answering = false;

  @override
  void didUpdateWidget(ConfirmCard old) {
    super.didUpdateWidget(old);
    if (old.message.state != widget.message.state) _answering = false;
  }

  Future<void> _answer(Future<CardAnswer> Function() send) async {
    if (_answering) return;
    _answering = true;
    var accepted = false;
    try {
      accepted = await send() == CardAnswer.accepted;
    } on Object catch (e, s) {
      _log.warning('answer failed: ${e.runtimeType}', e, s);
    }
    // An accepted answer moves the card (the state change resets the flag);
    // any other result leaves it open for a new try.
    if (!accepted && mounted) _answering = false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = widget.message;
    final call = callOf(message);
    final pending = message.state == AiMessageState.pending;
    final live =
        pending &&
        ref.watch(
          chatCardLiveProvider((
            conversationId: message.conversationId,
            seq: message.seq,
          )),
        );
    final preview = call == null
        ? null
        : ref.watch(chatConfirmPreviewProvider(confirmCallOf(call))).value;

    var request = CardRequest.of(call);
    if (preview != null) {
      request = request.copyWith(
        count: preview.tracks.length,
        name: request.isPlaylistTool && preview.summary.isNotEmpty
            ? preview.summary
            : null,
      );
    }
    final id = call?.id;
    final controller = ref.read(chatSessionProvider.notifier);
    final tool = toolDisplayName(l10n, request.tool);
    return KActionCard(
      icon: actionIcon(request.tool),
      title: sentenceCase(actionPhrase(l10n, request)),
      subtitle: pending
          ? l10n.aiChatCardNeedsAllow(tool)
          : joinLine([
              l10n.aiChatCardAllowedByUser,
              toolGroupLabel(l10n, request.tool),
            ]),
      body: preview == null || preview.tracks.isEmpty
          ? null
          : TrackRowsPreview(tracks: preview.tracks),
      readOnly: !live,
      actions: !live || id == null
          ? const []
          : [
              KActionCardAction(
                label: l10n.aiChatCardDeny,
                onPressed: () => unawaited(_answer(() => controller.deny(id))),
              ),
              KActionCardAction(
                label: l10n.aiChatCardAllow,
                primary: true,
                onPressed: () => unawaited(_answer(() => controller.allow(id))),
              ),
            ],
    );
  }
}
