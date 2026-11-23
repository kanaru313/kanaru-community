import '../../../database/tables.dart';
import '../../domain/online/online_rows.dart';
import '../../domain/online/online_text.dart';
import '../lyrics_parse_jobs.dart';

OnlineText? _parse(String? synced, String? plain) =>
    parseOnlineText(synced: synced, plain: plain);

/// Parses the text of a row; text above [lyricsIsolateThreshold] is parsed
/// through [run], off the calling isolate.
Future<OnlineText?> _parseRow(
  String? synced,
  String? plain,
  IsolateRunner run,
) {
  final size = (synced?.length ?? 0) + (plain?.length ?? 0);
  return size > lyricsIsolateThreshold
      ? run(() => _parse(synced, plain))
      : Future.value(_parse(synced, plain));
}

/// The kept copy as the resolver reads it, text parsed off the UI isolate
/// when it is large.
Future<OnlinePick> pickOfRow(
  LyricsPinRow row, [
  IsolateRunner run = runInIsolate,
]) async => OnlinePick(
  providerId: row.providerId,
  providerName: row.providerName,
  remoteId: row.remoteId,
  text: await _parseRow(row.syncedText, row.plainText, run),
  instrumental: row.instrumental,
  remoteDurationMs: row.remoteDurationMs,
);

/// A cache row as the resolver reads it, text parsed off the UI isolate when
/// it is large.
Future<OnlineCacheEntry> entryOfRow(
  OnlineLyricsRow row, [
  IsolateRunner run = runInIsolate,
]) async => OnlineCacheEntry(
  providerId: row.providerId,
  fetchedAt: DateTime.fromMillisecondsSinceEpoch(row.fetchedAt),
  found: row.status == OnlineLyricsStatus.found,
  remoteId: row.remoteId,
  text: await _parseRow(row.syncedText, row.plainText, run),
  instrumental: row.instrumental,
  remoteDurationMs: row.remoteDurationMs,
);
