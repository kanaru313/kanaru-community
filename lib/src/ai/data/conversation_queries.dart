import 'package:drift/drift.dart';

import '../../database/database.dart';
import '../domain/conversation/parts.dart';
import '../domain/conversation/parts_codec.dart';
import 'conversation_rows.dart';

/// Count and stored bytes (JSON columns and live text, in UTF-8 bytes).
Future<AiChatStats> readStats(AppDatabase db) async {
  final row = await db.customSelect('''
    SELECT
      (SELECT COUNT(*) FROM ai_conversations) AS c,
      (SELECT COALESCE(SUM(
        length(CAST(parts_json AS BLOB))
        + COALESCE(length(CAST(live_text AS BLOB)), 0)
        + COALESCE(length(CAST(provider_json AS BLOB)), 0)
        + COALESCE(length(CAST(error_json AS BLOB)), 0)
        + COALESCE(length(CAST(usage_json AS BLOB)), 0)), 0)
       FROM ai_messages) AS b
    ''').getSingle();
  return AiChatStats(
    conversations: row.read<int>('c'),
    bytes: row.read<int>('b'),
  );
}

/// Ids of the conversations whose title or message text contains [needle]
/// (already lower-cased), case-insensitive. Reads message text in pages, so
/// the cost grows with the stored text.
Future<Set<int>> conversationIdsMatching(
  AppDatabase db,
  String needle, {
  required Iterable<int> alreadyMatched,
}) async {
  final found = {...alreadyMatched};
  const page = 500;
  var afterId = 0;
  while (true) {
    final rows =
        await (db.select(db.aiMessages)
              ..where(
                (m) =>
                    m.id.isBiggerThanValue(afterId) &
                    m.role.isIn(const ['user', 'assistant']) &
                    m.conversationId.isNotIn(found),
              )
              ..orderBy([(m) => OrderingTerm.asc(m.id)])
              ..limit(page))
            .get();
    if (rows.isEmpty) return found;
    for (final r in rows) {
      afterId = r.id;
      if (found.contains(r.conversationId)) continue;
      if (_textOf(r.partsJson, r.liveText).toLowerCase().contains(needle)) {
        found.add(r.conversationId);
      }
    }
  }
}

String _textOf(String partsJson, String? liveText) {
  final b = StringBuffer(liveText ?? '');
  try {
    for (final p in decodeParts(partsJson)) {
      if (p is TextPart) b.write('\n${p.text}');
    }
  } on AiPartsException {
    b.write('\n$partsJson');
  }
  return b.toString();
}
