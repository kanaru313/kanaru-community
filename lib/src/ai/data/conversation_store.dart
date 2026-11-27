import 'dart:async';

import 'package:drift/drift.dart';

import '../../database/database.dart';
import '../domain/conversation/ai_conversation.dart';
import '../domain/conversation/ai_message.dart';
import '../domain/conversation/parts.dart';
import '../domain/conversation/parts_codec.dart';
import '../domain/permission.dart';
import 'conversation_maintenance.dart';
import 'conversation_queries.dart';
import 'conversation_rows.dart';

export 'conversation_maintenance.dart' show SweepResult, cutOffByCloseCode;
export 'conversation_rows.dart';

/// Pages of [ConversationStore.messages] hold this many messages by default.
const defaultMessagePage = 50;

/// How [ConversationStore.startCall] ended.
enum StartCall {
  /// The call is `running` now.
  started,

  /// Another caller moved the call first.
  moved,

  /// A write while the chat is read-only: nothing was written.
  readOnly,
}

// Message states a row can leave, and where it may go. A confirm answer other
// than "allowed" (denied, deniedByNewMessage, expired) ends in `skipped`
// through [ConversationStore.resolveConfirm].
const _transitions = <AiMessageState, Set<AiMessageState>>{
  AiMessageState.streaming: {
    AiMessageState.complete,
    AiMessageState.stopped,
    AiMessageState.error,
  },
  AiMessageState.pending: {AiMessageState.allowed, AiMessageState.skipped},
  AiMessageState.allowed: {AiMessageState.running, AiMessageState.skipped},
  AiMessageState.running: {
    AiMessageState.done,
    AiMessageState.error,
    AiMessageState.unknown,
  },
};

/// Conversations and messages of the AI chat on `ai_conversations` and
/// `ai_messages`. Every multi-row write is one transaction; every state
/// change is a compare-and-set (`UPDATE … WHERE state = from`) that returns
/// false when another caller got there first. Size caps are enforced here
/// ([ConversationStoreLimits]); the tables carry no SQL CHECK.
class ConversationStore {
  ConversationStore(
    this._db, {
    this.limits = const ConversationStoreLimits(),
    int Function()? clock,
  }) : _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  final AppDatabase _db;
  final ConversationStoreLimits limits;
  final int Function() _clock;
  final _changes = StreamController<void>.broadcast();

  bool _notifyScheduled = false;

  /// Fires after any stored change a screen shows: a message appended, a
  /// card or round moved to another state, a conversation renamed, bound or
  /// deleted (not for each live-text flush). Writes of one batch fire once.
  Stream<void> get changes => _changes.stream;

  void dispose() => unawaited(_changes.close());

  /// One event per microtask: a batch of writes wakes listeners once.
  void _notify() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    scheduleMicrotask(() {
      _notifyScheduled = false;
      if (!_changes.isClosed) _changes.add(null);
    });
  }

  // ── Conversations ──────────────────────────────────────────────────────

  Future<AiConversation> create({
    required String title,
    required AiPermission permission,
    bool titleAuto = true,
    String? installId,
    int? installGeneration,
    String? model,
  }) async {
    final now = _clock();
    final id = await _db
        .into(_db.aiConversations)
        .insert(
          AiConversationsCompanion.insert(
            title: title,
            titleAuto: Value(titleAuto),
            installId: Value(installId),
            installGeneration: Value(installGeneration),
            model: Value(model),
            permission: permission.wire,
            createdAt: now,
            updatedAt: now,
            lastMessageAt: now,
          ),
        );
    _notify();
    return (await conversation(id))!;
  }

  Future<AiConversation?> conversation(int id) async {
    final r = await (_db.select(
      _db.aiConversations,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    return r == null ? null : conversationFromRow(r);
  }

  /// Newest activity first.
  Future<List<AiConversation>> list({int? limit, int offset = 0}) async {
    final q = _db.select(_db.aiConversations)
      ..orderBy([
        (c) => OrderingTerm.desc(c.lastMessageAt),
        (c) => OrderingTerm.desc(c.id),
      ]);
    if (limit != null) q.limit(limit, offset: offset);
    return [for (final r in await q.get()) conversationFromRow(r)];
  }

  /// Conversations whose title or message text contains [query]
  /// (case-insensitive), newest activity first.
  Future<List<AiConversation>> search(String query) async {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return const [];
    final all = await list();
    final byTitle = {
      for (final c in all)
        if (c.title.toLowerCase().contains(needle)) c.id,
    };
    final ids = await conversationIdsMatching(
      _db,
      needle,
      alreadyMatched: byTitle,
    );
    return [
      for (final c in all)
        if (ids.contains(c.id)) c,
    ];
  }

  /// A manual rename: the title is no longer replaced by a generated one.
  Future<void> rename(int id, String title) async {
    await (_db.update(
      _db.aiConversations,
    )..where((c) => c.id.equals(id))).write(
      AiConversationsCompanion(
        title: Value(title),
        titleAuto: const Value(false),
        updatedAt: Value(_clock()),
      ),
    );
    _notify();
  }

  /// A title made by the app; ignored once the user renamed the chat.
  Future<bool> setAutoTitle(int id, String title) async {
    final n =
        await (_db.update(
          _db.aiConversations,
        )..where((c) => c.id.equals(id) & c.titleAuto.equals(true))).write(
          AiConversationsCompanion(
            title: Value(title),
            updatedAt: Value(_clock()),
          ),
        );
    if (n > 0) _notify();
    return n > 0;
  }

  Future<void> setPermission(int id, AiPermission permission) async {
    await (_db.update(
      _db.aiConversations,
    )..where((c) => c.id.equals(id))).write(
      AiConversationsCompanion(
        permission: Value(permission.wire),
        updatedAt: Value(_clock()),
      ),
    );
    _notify();
  }

  /// Binds the chat to another plugin (or model).
  Future<void> bind(
    int id, {
    required String? installId,
    required int? installGeneration,
    String? model,
  }) async {
    await (_db.update(
      _db.aiConversations,
    )..where((c) => c.id.equals(id))).write(
      AiConversationsCompanion(
        installId: Value(installId),
        installGeneration: Value(installGeneration),
        model: Value(model),
        updatedAt: Value(_clock()),
      ),
    );
    _notify();
  }

  /// Hard delete; the messages go by cascade.
  Future<void> delete(int id) async {
    await (_db.delete(_db.aiConversations)..where((c) => c.id.equals(id))).go();
    _notify();
  }

  Future<void> deleteAll() async {
    await _db.delete(_db.aiConversations).go();
    _notify();
  }

  Future<AiChatStats> stats() => readStats(_db);

  // ── Messages ───────────────────────────────────────────────────────────

  /// One page of messages in `seq` order: the newest [limit] messages with a
  /// `seq` below [beforeSeq] (all of them when null). Pass the first `seq` of
  /// the previous page to read the page before it. With [blobs] false the
  /// provider blobs are not read (`providerJson` is null): a list on screen
  /// never needs them.
  Future<List<StoredMessage>> messages(
    int conversationId, {
    int? beforeSeq,
    int limit = defaultMessagePage,
    bool blobs = true,
  }) async {
    if (!blobs) {
      final rows = await selectMessagesNoBlob(
        _db,
        where: beforeSeq == null
            ? 'conversation_id = ?'
            : 'conversation_id = ? AND seq < ?',
        variables: [
          Variable.withInt(conversationId),
          if (beforeSeq != null) Variable.withInt(beforeSeq),
        ],
        descLimit: limit,
      );
      return [for (final r in rows.reversed) messageFromRow(r)];
    }
    final rows =
        await (_db.select(_db.aiMessages)
              ..where(
                (m) =>
                    m.conversationId.equals(conversationId) &
                    (beforeSeq == null
                        ? const Constant(true)
                        : m.seq.isSmallerThanValue(beforeSeq)),
              )
              ..orderBy([(m) => OrderingTerm.desc(m.seq)])
              ..limit(limit))
            .get();
    return [for (final r in rows.reversed) messageFromRow(r)];
  }

  /// The latest turn: its user message and every row after it, in order,
  /// without provider blobs. Empty when the chat has no user message.
  Future<List<StoredMessage>> latestTurn(int conversationId) async {
    final rows = await selectMessagesNoBlob(
      _db,
      where:
          'conversation_id = ? AND seq >= (SELECT MAX(seq) FROM ai_messages '
          "WHERE conversation_id = ? AND role = 'user')",
      variables: [
        Variable.withInt(conversationId),
        Variable.withInt(conversationId),
      ],
    );
    return [for (final r in rows) messageFromRow(r)];
  }

  /// The tool rows of the whole chat that are still `pending` or `allowed`,
  /// without provider blobs.
  Future<List<StoredMessage>> openToolCards(int conversationId) async {
    final rows = await selectMessagesNoBlob(
      _db,
      where:
          "conversation_id = ? AND role = 'tool' "
          "AND state IN ('pending', 'allowed')",
      variables: [Variable.withInt(conversationId)],
    );
    return [for (final r in rows) messageFromRow(r)];
  }

  Future<StoredMessage?> message(int id) async {
    final r = await (_db.select(
      _db.aiMessages,
    )..where((m) => m.id.equals(id))).getSingleOrNull();
    return r == null ? null : messageFromRow(r);
  }

  /// Appends [m] with `seq = max + 1`, in one transaction. Throws
  /// [AiStoreTooLarge] when its parts are over the row cap (nothing is
  /// written).
  Future<StoredMessage> append(NewAiMessage m) async {
    final parts = encodeParts(m.parts);
    _checkPartsSize(parts);
    final live = m.liveText == null
        ? null
        : capLiveText(m.liveText!, limits.liveTextBytes);
    final id = await _db.transaction(
      () => _insertRow(
        conversationId: m.conversationId,
        role: m.role.wire,
        state: m.state.wire,
        partsJson: parts,
        liveText: live,
        providerJson: m.providerJson,
        installId: m.installId,
        installGeneration: m.installGeneration,
        pluginVersion: m.pluginVersion,
        model: m.model,
      ),
    );
    _notify();
    return (await message(id))!;
  }

  /// The `seq` of the newest row of the conversation (0 when it has none):
  /// the revision of its transcript.
  Future<int> latestSeq(int conversationId) async {
    final row = await _db
        .customSelect(
          'SELECT COALESCE(MAX(seq), 0) AS m FROM ai_messages '
          'WHERE conversation_id = ?',
          variables: [Variable.withInt(conversationId)],
        )
        .getSingle();
    return row.read<int>('m');
  }

  /// Whether the conversation has a user message (switch markers and other
  /// rows do not count).
  Future<bool> hasUserMessage(int conversationId) async {
    final row = await _db
        .customSelect(
          'SELECT EXISTS(SELECT 1 FROM ai_messages WHERE conversation_id = ? '
          "AND role = 'user') AS e",
          variables: [Variable.withInt(conversationId)],
        )
        .getSingle();
    return row.read<int>('e') == 1;
  }

  /// [append] only when the newest row still has `seq == expectedSeq`; null
  /// (nothing written) when another row got in first. The check and the
  /// insert share one transaction.
  Future<StoredMessage?> appendIfLatest(
    NewAiMessage m, {
    required int expectedSeq,
  }) async {
    final parts = encodeParts(m.parts);
    _checkPartsSize(parts);
    final live = m.liveText == null
        ? null
        : capLiveText(m.liveText!, limits.liveTextBytes);
    final id = await _db.transaction<int?>(() async {
      if (await latestSeq(m.conversationId) != expectedSeq) return null;
      return _insertRow(
        conversationId: m.conversationId,
        role: m.role.wire,
        state: m.state.wire,
        partsJson: parts,
        liveText: live,
        providerJson: m.providerJson,
        installId: m.installId,
        installGeneration: m.installGeneration,
        pluginVersion: m.pluginVersion,
        model: m.model,
      );
    });
    if (id == null) return null;
    _notify();
    return message(id);
  }

  /// Records the plugin version that really ran a round (the run may have
  /// used a newer one than the message was created with).
  Future<bool> stampPluginVersion(int messageId, int version) async {
    final n =
        await (_db.update(_db.aiMessages)..where((m) => m.id.equals(messageId)))
            .write(AiMessagesCompanion(pluginVersion: Value(version)));
    return n > 0;
  }

  Future<int> _insertRow({
    required int conversationId,
    required String role,
    required String state,
    required String partsJson,
    String? liveText,
    String? providerJson,
    String? installId,
    int? installGeneration,
    int? pluginVersion,
    String? model,
  }) async {
    final now = _clock();
    final max = await _db
        .customSelect(
          'SELECT COALESCE(MAX(seq), 0) AS m FROM ai_messages '
          'WHERE conversation_id = ?',
          variables: [Variable.withInt(conversationId)],
        )
        .getSingle();
    final id = await _db
        .into(_db.aiMessages)
        .insert(
          AiMessagesCompanion.insert(
            conversationId: conversationId,
            seq: max.read<int>('m') + 1,
            role: role,
            partsJson: partsJson,
            liveText: Value(liveText),
            providerJson: Value(providerJson),
            installId: Value(installId),
            installGeneration: Value(installGeneration),
            pluginVersion: Value(pluginVersion),
            model: Value(model),
            state: state,
            createdAt: now,
          ),
        );
    await (_db.update(
      _db.aiConversations,
    )..where((c) => c.id.equals(conversationId))).write(
      AiConversationsCompanion(
        lastMessageAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    return id;
  }

  void _checkPartsSize(String partsJson) {
    final n = utf8Size(partsJson);
    if (n > limits.partsJsonBytes) {
      throw AiStoreTooLarge('parts_json', n, limits.partsJsonBytes);
    }
  }

  /// Replaces the live text of a streaming message, cut to the live-text cap
  /// (a cut text ends with [liveTextTruncationMarker]; once cut, later longer
  /// text stores the same cut text). Returns false when the message is not
  /// streaming (nothing is written).
  Future<bool> updateLiveText(int messageId, String text) async {
    final n =
        await (_db.update(_db.aiMessages)..where(
              (m) => m.id.equals(messageId) & m.state.equals('streaming'),
            ))
            .write(
              AiMessagesCompanion(
                liveText: Value(capLiveText(text, limits.liveTextBytes)),
              ),
            );
    return n > 0;
  }

  /// Moves a message from [from] to [to] if it is still in [from]; false when
  /// another caller moved it first. Legal moves: streaming → complete,
  /// stopped, error; pending → allowed, skipped; allowed → running, skipped;
  /// running → done, error, unknown (else [ArgumentError]). [parts] replaces
  /// the row's parts (a tool result); [error] is stored as `error_json`.
  /// Parts over the row cap mark the row `error(too_large)` and throw
  /// [AiStoreTooLarge].
  Future<bool> transition(
    int messageId, {
    required AiMessageState from,
    required AiMessageState to,
    List<AiPart>? parts,
    AiStoredError? error,
  }) async {
    if (!(_transitions[from]?.contains(to) ?? false)) {
      throw ArgumentError('illegal transition ${from.wire} -> ${to.wire}');
    }
    String? partsJson;
    if (parts != null) {
      partsJson = encodeParts(parts);
      try {
        _checkPartsSize(partsJson);
      } on AiStoreTooLarge {
        await _markTooLarge(messageId, from);
        rethrow;
      }
    }
    final n = await _cas(
      messageId,
      from: from,
      companion: AiMessagesCompanion(
        state: Value(to.wire),
        partsJson: partsJson == null ? const Value.absent() : Value(partsJson),
        errorJson: error == null
            ? const Value.absent()
            : Value(error.toJsonText()),
      ),
    );
    if (n > 0) _notify();
    return n > 0;
  }

  /// Moves an `allowed` call to `running` and, for a [write], only while the
  /// chat is not read-only: the permission is read in the same transaction as
  /// the move, so a switch to read-only that commits first always wins.
  Future<StartCall> startCall(int messageId, {required bool write}) async {
    final result = await _db.transaction(() async {
      final row = await (_db.select(
        _db.aiMessages,
      )..where((m) => m.id.equals(messageId))).getSingleOrNull();
      if (row == null || row.state != 'allowed') return StartCall.moved;
      if (write) {
        final c = await conversation(row.conversationId);
        if (c?.permission == AiPermission.readOnly) return StartCall.readOnly;
      }
      final n = await _cas(
        messageId,
        from: AiMessageState.allowed,
        companion: const AiMessagesCompanion(state: Value('running')),
      );
      return n > 0 ? StartCall.started : StartCall.moved;
    });
    if (result == StartCall.started) _notify();
    return result;
  }

  Future<int> _cas(
    int messageId, {
    required AiMessageState from,
    required AiMessagesCompanion companion,
  }) =>
      (_db.update(_db.aiMessages)
            ..where((m) => m.id.equals(messageId) & m.state.equals(from.wire)))
          .write(companion);

  Future<bool> _markTooLarge(int messageId, AiMessageState from) async {
    final n = await _cas(
      messageId,
      from: from,
      companion: AiMessagesCompanion(
        state: const Value('error'),
        errorJson: Value(const AiStoredError.local('too_large').toJsonText()),
      ),
    );
    if (n > 0) _notify();
    return n > 0;
  }

  /// Answers a pending confirmation card. `allowed` moves the row to
  /// `allowed`; denied, deniedByNewMessage and expired move it to `skipped`.
  /// The row's confirm part takes the new status. False when the row is no
  /// longer pending.
  Future<bool> resolveConfirm(
    int messageId,
    ConfirmStatus status, {
    String? reason,
    String? approvalHash,
  }) async {
    if (status == ConfirmStatus.pending) {
      throw ArgumentError('pending is not an answer');
    }
    final won = await _db.transaction(() async {
      final row = await (_db.select(
        _db.aiMessages,
      )..where((m) => m.id.equals(messageId))).getSingleOrNull();
      if (row == null || row.state != 'pending') return false;
      final parts = [
        for (final p in decodeParts(row.partsJson))
          p is ConfirmPart
              ? ConfirmPart(
                  callId: p.callId,
                  status: status,
                  reason: reason,
                  approvalHash: status == ConfirmStatus.allowed
                      ? approvalHash
                      : null,
                )
              : p,
      ];
      final to = status == ConfirmStatus.allowed
          ? AiMessageState.allowed
          : AiMessageState.skipped;
      final n = await _cas(
        messageId,
        from: AiMessageState.pending,
        companion: AiMessagesCompanion(
          state: Value(to.wire),
          partsJson: Value(encodeParts(parts)),
        ),
      );
      return n > 0;
    });
    if (won) _notify();
    return won;
  }

  /// Ends a streaming round in one transaction: `streaming → complete` with
  /// [finalParts] and the provider [blob] (live text cleared), and one `tool`
  /// row per draft in [calls] (`pending` with a confirm part for ask-mode
  /// writes, `allowed` for the rest). When the message is no longer
  /// streaming nothing is written and the result is lost.
  ///
  /// A [blob] over its cap is replaced by [oversizeBlobMarker]; call
  /// [endTurn] when the turn ends. Past the per-conversation blob cap the
  /// oldest turns are flattened in the same transaction. Parts over the row
  /// cap, or blobs that still do not fit, mark the message `error(too_large)`
  /// and throw [AiStoreTooLarge] with nothing else written.
  Future<CompleteRoundResult> completeRound({
    required int messageId,
    required List<AiPart> finalParts,
    String? blob,
    List<ToolCardDraft> calls = const [],
  }) async {
    final partsJson = encodeParts(finalParts);
    final cards = [
      for (final c in calls)
        encodeParts([
          c.call,
          if (c.needsConfirm)
            ConfirmPart(callId: c.call.id, status: ConfirmStatus.pending),
        ]),
    ];
    final tooLargeBlob = blob != null && utf8Size(blob) > limits.blobBytes;
    try {
      _checkPartsSize(partsJson);
      cards.forEach(_checkPartsSize);
      final result = await _db.transaction(() async {
        final row = await (_db.select(
          _db.aiMessages,
        )..where((m) => m.id.equals(messageId))).getSingleOrNull();
        final n = await _cas(
          messageId,
          from: AiMessageState.streaming,
          companion: AiMessagesCompanion(
            state: const Value('complete'),
            partsJson: Value(partsJson),
            liveText: const Value(null),
            providerJson: Value(tooLargeBlob ? oversizeBlobMarker : blob),
          ),
        );
        if (n == 0 || row == null) return const CompleteRoundResult.lost();
        final ids = <int>[];
        for (var i = 0; i < calls.length; i++) {
          ids.add(
            await _insertRow(
              conversationId: row.conversationId,
              role: 'tool',
              state: calls[i].needsConfirm ? 'pending' : 'allowed',
              partsJson: cards[i],
            ),
          );
        }
        final turn = await turnIdOfIn(_db, messageId);
        final fits = await enforceBlobCapIn(
          _db,
          row.conversationId,
          limits.conversationBlobBytes,
          protectedTurnId: turn,
        );
        if (!fits) {
          throw AiStoreTooLarge(
            'provider blobs of the conversation',
            limits.conversationBlobBytes + 1,
            limits.conversationBlobBytes,
          );
        }
        return CompleteRoundResult(cardIds: ids, blobTooLarge: tooLargeBlob);
      });
      if (result.won) _notify();
      return result;
    } on AiStoreTooLarge {
      await _markTooLarge(messageId, AiMessageState.streaming);
      rethrow;
    }
  }

  // ── Turns ──────────────────────────────────────────────────────────────

  /// The id of the turn (its user message) that [messageId] belongs to.
  Future<int?> turnIdOf(int messageId) => turnIdOfIn(_db, messageId);

  /// Stores the turn as text only (see `flattenTurnIn`), atomically. False
  /// when the turn is still running.
  Future<bool> flattenTurn(int turnId) async {
    final done = await _db.transaction(() => flattenTurnIn(_db, turnId));
    if (done) _notify();
    return done;
  }

  /// Call when a turn ends: flattens it if a blob of it was over its cap.
  Future<bool> endTurn(int turnId) async {
    final done = await _db.transaction(() => endTurnIn(_db, turnId));
    if (done) _notify();
    return done;
  }

  /// Plugin removed or reinstalled: drops its blobs, flattening each turn
  /// that held one. A version or model switch flattens at send time instead.
  Future<int> clearProviderBlobs({required String installId}) async {
    final n = await _db.transaction(() => clearProviderBlobsIn(_db, installId));
    if (n > 0) _notify();
    return n;
  }

  /// Run once at startup, before any chat opens. See `sweepIn`.
  Future<SweepResult> sweepAfterCrash() async {
    final r = await _db.transaction(() => sweepIn(_db, limits.liveTextBytes));
    if (r.stopped > 0 || r.unknown > 0) _notify();
    return r;
  }
}
