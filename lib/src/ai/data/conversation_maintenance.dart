import 'package:drift/drift.dart';

import '../../database/database.dart';
import '../domain/conversation/parts.dart';
import '../domain/conversation/parts_codec.dart';
import 'conversation_rows.dart';

// Turns, flattening, blob caps and the startup sweep of the conversation
// store. Every function expects to run inside the caller's transaction.
//
// A turn is a user message (role `user`) and every row after it (assistant,
// tool, event) up to the next user message. Its id is the id of the user
// message. Rows before a conversation's first user message belong to no turn.

const _liveStates = {'streaming', 'pending', 'allowed', 'running'};

/// The id of the user message that opens the turn of [messageId], or null
/// when the row is before the first user message or does not exist.
Future<int?> turnIdOfIn(AppDatabase db, int messageId) async {
  final row = await _row(db, messageId);
  if (row == null) return null;
  if (row.role == 'user') return row.id;
  final q = db.select(db.aiMessages)
    ..where(
      (m) =>
          m.conversationId.equals(row.conversationId) &
          m.role.equals('user') &
          m.seq.isSmallerThanValue(row.seq),
    )
    ..orderBy([(m) => OrderingTerm.desc(m.seq)])
    ..limit(1);
  return (await q.getSingleOrNull())?.id;
}

Future<AiMessageRow?> _row(AppDatabase db, int id) =>
    (db.select(db.aiMessages)..where((m) => m.id.equals(id))).getSingleOrNull();

/// The rows of the turn of [userMessage] after the user message, in order.
Future<List<AiMessageRow>> _turnRows(
  AppDatabase db,
  AiMessageRow userMessage,
) async {
  final next =
      await (db.select(db.aiMessages)
            ..where(
              (m) =>
                  m.conversationId.equals(userMessage.conversationId) &
                  m.role.equals('user') &
                  m.seq.isBiggerThanValue(userMessage.seq),
            )
            ..orderBy([(m) => OrderingTerm.asc(m.seq)])
            ..limit(1))
          .getSingleOrNull();
  return (db.select(db.aiMessages)
        ..where(
          (m) =>
              m.conversationId.equals(userMessage.conversationId) &
              m.seq.isBiggerThanValue(userMessage.seq) &
              (next == null
                  ? const Constant(true)
                  : m.seq.isSmallerThanValue(next.seq)),
        )
        ..orderBy([(m) => OrderingTerm.asc(m.seq)]))
      .get();
}

/// Stores the turn of user message [turnId] as text only: tool call and
/// result parts and provider blobs go together, so no tool call is left
/// without its blob. What the user sees of the turn stays: tool rows keep
/// their done, confirm and error parts (a tool row left with nothing is
/// deleted), so the turn's item usage (`TurnItemUsage` counts done parts, and
/// retry or restart never reset it) and its "what the AI changed" cards
/// survive. An assistant row left without parts or text is deleted.
/// Returns false (and changes nothing) when the turn is still running or
/// [turnId] is not a user message.
Future<bool> flattenTurnIn(AppDatabase db, int turnId) async {
  final user = await _row(db, turnId);
  if (user == null || user.role != 'user') return false;
  final rows = await _turnRows(db, user);
  if (rows.any((r) => _liveStates.contains(r.state))) return false;
  for (final r in rows) {
    if (r.role == 'tool') {
      await _flattenTool(db, r);
    } else if (r.role == 'assistant') {
      await _flattenAssistant(db, r);
    }
  }
  return true;
}

Future<void> _flattenTool(AppDatabase db, AiMessageRow r) async {
  List<AiPart> kept;
  try {
    kept = [
      for (final p in decodeParts(r.partsJson))
        if (p is! ToolCallPart && p is! ToolResultPart) p,
    ];
  } on AiPartsException {
    // Nothing readable to keep.
    kept = const [];
  }
  if (kept.isEmpty) {
    await (db.delete(db.aiMessages)..where((m) => m.id.equals(r.id))).go();
    return;
  }
  await (db.update(db.aiMessages)..where((m) => m.id.equals(r.id))).write(
    AiMessagesCompanion(partsJson: Value(encodeParts(kept))),
  );
}

Future<void> _flattenAssistant(AppDatabase db, AiMessageRow r) async {
  List<AiPart> kept;
  try {
    kept = [
      for (final p in decodeParts(r.partsJson))
        if (p is! ToolCallPart && p is! ToolResultPart) p,
    ];
  } on AiPartsException {
    // Unreadable parts stay as they are; only the blob goes.
    await (db.update(db.aiMessages)..where((m) => m.id.equals(r.id))).write(
      const AiMessagesCompanion(providerJson: Value(null)),
    );
    return;
  }
  final hasText = (r.liveText ?? '').isNotEmpty;
  if (kept.isEmpty && !hasText && r.state == 'complete') {
    await (db.delete(db.aiMessages)..where((m) => m.id.equals(r.id))).go();
    return;
  }
  await (db.update(db.aiMessages)..where((m) => m.id.equals(r.id))).write(
    AiMessagesCompanion(
      partsJson: Value(encodeParts(kept)),
      providerJson: const Value(null),
    ),
  );
}

/// Ends the turn of [turnId]: a turn that kept an [oversizeBlobMarker] is
/// stored flattened. Returns whether it was flattened.
Future<bool> endTurnIn(AppDatabase db, int turnId) async {
  final user = await _row(db, turnId);
  if (user == null || user.role != 'user') return false;
  final rows = await _turnRows(db, user);
  if (!rows.any((r) => r.providerJson == oversizeBlobMarker)) return false;
  return flattenTurnIn(db, turnId);
}

/// Flattens the oldest turns of [conversationId] until its provider blobs
/// fit in [limit] bytes. The turn of [protectedTurnId] (the one running) is
/// never touched. Returns whether the blobs fit afterwards.
Future<bool> enforceBlobCapIn(
  AppDatabase db,
  int conversationId,
  int limit, {
  int? protectedTurnId,
}) async {
  final rows = await db
      .customSelect(
        'SELECT id, role, length(CAST(provider_json AS BLOB)) AS n '
        'FROM ai_messages WHERE conversation_id = ? ORDER BY seq',
        variables: [Variable.withInt(conversationId)],
      )
      .get();
  // Blob bytes per turn, oldest first.
  final turns = <int, int>{};
  var total = 0;
  int? turn;
  for (final r in rows) {
    final n = r.read<int?>('n') ?? 0;
    total += n;
    if (r.read<String>('role') == 'user') turn = r.read<int>('id');
    if (turn != null) turns[turn] = (turns[turn] ?? 0) + n;
  }
  if (total <= limit) return true;
  for (final e in turns.entries) {
    if (total <= limit) break;
    if (e.key == protectedTurnId || e.value == 0) continue;
    if (await flattenTurnIn(db, e.key)) total -= e.value;
  }
  return total <= limit;
}

/// Drops the blobs of [installId] (plugin removed or reinstalled). Each turn
/// that held one is flattened with it, so a tool call never outlives its
/// blob. A turn that is still running is left alone. Returns the number of
/// turns flattened.
Future<int> clearProviderBlobsIn(AppDatabase db, String installId) async {
  final holders =
      await (db.select(db.aiMessages)..where(
            (m) => m.installId.equals(installId) & m.providerJson.isNotNull(),
          ))
          .get();
  final turnIds = <int>{};
  for (final r in holders) {
    final t = await turnIdOfIn(db, r.id);
    if (t != null) {
      turnIds.add(t);
    } else {
      await (db.update(db.aiMessages)..where((m) => m.id.equals(r.id))).write(
        const AiMessagesCompanion(providerJson: Value(null)),
      );
    }
  }
  var flattened = 0;
  for (final t in turnIds) {
    if (await flattenTurnIn(db, t)) flattened++;
  }
  return flattened;
}

/// What a startup sweep changed.
class SweepResult {
  const SweepResult({required this.stopped, required this.unknown});

  /// Streaming messages turned into `stopped`.
  final int stopped;

  /// Running tool rows turned into `unknown`.
  final int unknown;
}

/// Code of the [ErrorPart] added to a reply the app cut off by closing.
const cutOffByCloseCode = 'cutOffByClose';

/// Startup sweep: `streaming` becomes `stopped` (live text kept, cut to
/// [liveTextBytes], plus an [ErrorPart] with [cutOffByCloseCode]) and
/// `running` becomes `unknown`. Provider blobs stay. Nothing calls the model.
Future<SweepResult> sweepIn(AppDatabase db, int liveTextBytes) async {
  final streaming = await (db.select(
    db.aiMessages,
  )..where((m) => m.state.equals('streaming'))).get();
  for (final r in streaming) {
    List<AiPart> parts;
    try {
      parts = decodeParts(r.partsJson);
    } on AiPartsException {
      parts = const [];
    }
    final live = r.liveText;
    await (db.update(db.aiMessages)..where((m) => m.id.equals(r.id))).write(
      AiMessagesCompanion(
        state: const Value('stopped'),
        liveText: Value(live == null ? null : capLiveText(live, liveTextBytes)),
        partsJson: Value(
          encodeParts([
            ...parts,
            const ErrorPart(code: cutOffByCloseCode, kind: 'closed'),
          ]),
        ),
      ),
    );
  }
  final unknown =
      await (db.update(db.aiMessages)..where((m) => m.state.equals('running')))
          .write(const AiMessagesCompanion(state: Value('unknown')));
  return SweepResult(stopped: streaming.length, unknown: unknown);
}
