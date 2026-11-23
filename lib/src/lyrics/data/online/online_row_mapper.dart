import '../../../database/tables.dart';
import '../../domain/online/online_rows.dart';
import '../../domain/online/online_text.dart';

/// The kept copy as the resolver reads it, text parsed.
OnlinePick pickOfRow(LyricsPinRow row) => OnlinePick(
  providerId: row.providerId,
  providerName: row.providerName,
  remoteId: row.remoteId,
  text: parseOnlineText(synced: row.syncedText, plain: row.plainText),
  instrumental: row.instrumental,
  remoteDurationMs: row.remoteDurationMs,
);

/// A cache row as the resolver reads it, text parsed.
OnlineCacheEntry entryOfRow(OnlineLyricsRow row) => OnlineCacheEntry(
  providerId: row.providerId,
  fetchedAt: DateTime.fromMillisecondsSinceEpoch(row.fetchedAt),
  found: row.status == OnlineLyricsStatus.found,
  remoteId: row.remoteId,
  text: parseOnlineText(synced: row.syncedText, plain: row.plainText),
  instrumental: row.instrumental,
  remoteDurationMs: row.remoteDurationMs,
);
