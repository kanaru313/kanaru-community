import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/conversation/ai_message.dart';
import '../../domain/conversation/parts.dart';
import '../../domain/conversation/track_ref_snapshot.dart';
import '../../domain/loop/card_results.dart' show callOf;
import '../../state/chat_session.dart';
import '../../state/chat_view/card_view.dart';
import '../chat_host.dart';
import 'card_texts.dart';
import 'playlist_link.dart';
import 'track_rows_preview.dart';

final _log = Logger('ai.done_card');

/// The card of a write that ran ("Đã làm: …"): what changed as a folded list
/// of exactly what the API returned, and the way to see it. [Mở hàng đợi] and
/// [Xem] stay on older turns; [Phát lại hàng đợi cũ] is offered only on the
/// latest turn.
class DoneCard extends ConsumerStatefulWidget {
  const DoneCard({super.key, required this.message});

  final AiMessage message;

  @override
  ConsumerState<DoneCard> createState() => _DoneCardState();
}

class _DoneCardState extends ConsumerState<DoneCard> {
  bool _replaying = false;

  Future<void> _replay() async {
    if (_replaying) return;
    _replaying = true;
    try {
      final result = await ref
          .read(chatSessionProvider.notifier)
          .replayQueue(widget.message.id);
      _log.fine('replay: ${result.name}');
    } on Object catch (e, s) {
      _log.warning('replay failed: ${e.runtimeType}', e, s);
    } finally {
      _replaying = false;
    }
  }

  Future<void> _view(int? playlistId) async {
    final host = ref.read(chatHostProvider);
    try {
      final location = await ref.read(chatPlaylistLocationProvider)(playlistId);
      host.openSettings(location);
    } on Object catch (e, s) {
      _log.warning('open playlist failed: ${e.runtimeType}', e, s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = widget.message;
    final call = callOf(message);
    final done = message.parts.whereType<DonePart>().firstOrNull;
    final result = message.parts.whereType<ToolResultPart>().firstOrNull;
    final byUser = message.parts.any((p) => p is ConfirmPart);
    final live = ref.watch(
      chatCardLiveProvider((
        conversationId: message.conversationId,
        seq: message.seq,
      )),
    );

    final asked = CardRequest.of(call);
    final changed = asked.isRemoval ? done?.removed : done?.added;
    final request = asked.copyWith(count: changed?.length);
    final replaced = done?.replacedQueue;
    final gone = asked.isRemoval
        ? asked.count - (done?.removed.length ?? 0)
        : 0;
    final absent = done?.absent.length ?? 0;

    final TrackListFold? fold;
    if (replaced != null) {
      fold = TrackListFold(
        label: l10n.aiChatCardOldQueueFold(replaced.tracks.length),
        tracks: [
          for (final id in replaced.tracks)
            TrackRefSnapshot(trackId: id, title: ''),
        ],
      );
    } else if (changed != null && changed.isNotEmpty) {
      fold = TrackListFold(
        label: asked.isRemoval
            ? l10n.aiChatCardRemovedFold(changed.length)
            : l10n.aiChatCardAddedFold(changed.length),
        tracks: changed,
      );
    } else {
      fold = null;
    }

    final host = ref.read(chatHostProvider);
    final openQueue = KActionCardAction(
      label: l10n.aiChatCardOpenQueue,
      onPressed: host.openQueue,
    );
    final List<KActionCardAction> actions;
    if (asked.isPlaylistTool) {
      final playlistId = playlistIdOfResult(result);
      actions = [
        KActionCardAction(
          label: l10n.aiChatCardView,
          onPressed: () => unawaited(_view(playlistId)),
        ),
      ];
    } else if (replaced != null && live) {
      actions = [
        KActionCardAction(
          label: l10n.aiChatCardReplayQueue,
          onPressed: () => unawaited(_replay()),
        ),
        openQueue,
      ];
    } else {
      actions = [openQueue];
    }

    return KActionCard(
      icon: actionIcon(asked.tool),
      emphasis: KActionCardEmphasis.done,
      title: l10n.aiChatCardDoneTitle(actionPhrase(l10n, request)),
      subtitle: joinLine([
        byUser ? l10n.aiChatCardAllowedByUser : l10n.aiChatCardAutomatic,
        toolGroupLabel(l10n, asked.tool),
        if (replaced != null) l10n.aiChatCardOldQueueReplaced,
        if (gone > 0)
          asked.tool == 'remove_from_playlist'
              ? l10n.aiChatCardGoneFromPlaylist(gone)
              : l10n.aiChatCardGoneFromQueue(gone),
        if (absent > 0) l10n.aiChatCardNotInLibrary(absent),
      ]),
      body: fold,
      actions: actions,
    );
  }
}
