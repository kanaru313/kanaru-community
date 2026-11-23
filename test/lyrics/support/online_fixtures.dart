import 'package:kanaru/src/lyrics/domain/online/lyrics_candidate.dart';

const syncedBody = LyricsBody(syncedLrc: '[00:01.00] a', plain: 'a');

/// A result of the fake plugin `lrclib` for a song of 200 s by `Artist`.
LyricsCandidate fakeCandidate({
  String title = 'Song',
  String artist = 'Artist',
  String remoteId = '1',
  String providerId = 'lrclib',
  Duration? duration = const Duration(seconds: 200),
  LyricsBody? body = syncedBody,
}) => LyricsCandidate(
  providerId: providerId,
  remoteId: remoteId,
  title: title,
  artist: artist,
  duration: duration,
  body: body,
);
