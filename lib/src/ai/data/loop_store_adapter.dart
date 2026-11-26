import '../domain/conversation/ai_conversation.dart';
import '../domain/conversation/ai_message.dart';
import '../domain/conversation/parts.dart';
import '../domain/input/history_turns.dart';
import '../domain/loop/loop_ports.dart';
import 'conversation_store.dart';

/// [LoopStore] on the conversation store.
class LoopStoreAdapter implements LoopStore {
  const LoopStoreAdapter(this.store);

  final ConversationStore store;

  @override
  Future<AiConversation?> conversation(int id) => store.conversation(id);

  @override
  Future<List<HistoryRow>> history(int conversationId) async {
    final rows = await store.messages(conversationId, limit: _allRows);
    return [
      for (final r in rows) HistoryRow(r.message, providerJson: r.providerJson),
    ];
  }

  @override
  Future<List<HistoryRow>> latestTurn(int conversationId) async => [
    for (final r in await store.latestTurn(conversationId))
      HistoryRow(r.message),
  ];

  @override
  Future<List<AiMessage>> openCards(int conversationId) async => [
    for (final r in await store.openToolCards(conversationId)) r.message,
  ];

  @override
  Future<CallStart> startCall(int messageId, {required bool write}) async =>
      switch (await store.startCall(messageId, write: write)) {
        StartCall.started => CallStart.started,
        StartCall.moved => CallStart.moved,
        StartCall.readOnly => CallStart.readOnly,
      };

  @override
  Future<int> appendUser(int conversationId, List<AiPart> parts) async {
    final m = await store.append(
      NewAiMessage(
        conversationId: conversationId,
        role: AiMessageRole.user,
        parts: parts,
      ),
    );
    return m.message.id;
  }

  @override
  Future<int?> beginRound(
    int conversationId, {
    required int expectedRevision,
    required ChatBinding binding,
  }) async {
    final m = await store.appendIfLatest(
      NewAiMessage(
        conversationId: conversationId,
        role: AiMessageRole.assistant,
        state: AiMessageState.streaming,
        installId: binding.installId,
        installGeneration: binding.installGeneration,
        pluginVersion: binding.pluginVersion,
        model: binding.model,
      ),
      expectedSeq: expectedRevision,
    );
    return m?.message.id;
  }

  @override
  Future<bool> updateLiveText(int messageId, String text) =>
      store.updateLiveText(messageId, text);

  @override
  Future<RoundCommit?> completeRound(
    int messageId, {
    required List<AiPart> parts,
    String? blob,
    List<CardDraft> calls = const [],
  }) async {
    try {
      final r = await store.completeRound(
        messageId: messageId,
        finalParts: parts,
        blob: blob,
        calls: [
          for (final c in calls)
            ToolCardDraft(call: c.call, needsConfirm: c.needsConfirm),
        ],
      );
      if (!r.won) return null;
      return RoundCommit(cardIds: r.cardIds, blobTooLarge: r.blobTooLarge);
    } on AiStoreTooLarge catch (e) {
      throw LoopStoreTooLarge(e.what);
    }
  }

  @override
  Future<bool> endRound(
    int messageId, {
    required AiMessageState to,
    List<AiPart> parts = const [],
    LoopError? error,
  }) => store.transition(
    messageId,
    from: AiMessageState.streaming,
    to: to,
    parts: parts.isEmpty ? null : parts,
    error: _stored(error),
  );

  @override
  Future<bool> stampPluginVersion(int messageId, int version) =>
      store.stampPluginVersion(messageId, version);

  @override
  Future<bool> transition(
    int messageId, {
    required AiMessageState from,
    required AiMessageState to,
    List<AiPart>? parts,
    LoopError? error,
  }) async {
    try {
      return await store.transition(
        messageId,
        from: from,
        to: to,
        parts: parts,
        error: _stored(error),
      );
    } on AiStoreTooLarge catch (e) {
      throw LoopStoreTooLarge(e.what);
    }
  }

  @override
  Future<bool> approve(int messageId, {required String approvalHash}) =>
      store.resolveConfirm(
        messageId,
        ConfirmStatus.allowed,
        approvalHash: approvalHash,
      );

  @override
  Future<void> endTurn(int turnId) async {
    await store.endTurn(turnId);
  }

  AiStoredError? _stored(LoopError? e) => e == null
      ? null
      : AiStoredError(
          code: e.code,
          kind: e.kind,
          retryAfterSec: e.retryAfterSec != null && e.retryAfterSec! > 0
              ? e.retryAfterSec
              : null,
        );
}

/// More rows than any conversation holds: the loop reads whole transcripts.
const _allRows = 1 << 30;
