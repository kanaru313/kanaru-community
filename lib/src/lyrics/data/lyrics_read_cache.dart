import '../../media/domain/track_id.dart';
import 'local_lyrics_read.dart';

/// Memory cache of finished reads: least recently used out first, bounded by
/// entry count and by the characters of lyrics text held.
class LyricsReadCache {
  LyricsReadCache({this.maxEntries = 8, this.maxTextChars = 4 << 20});

  final int maxEntries;
  final int maxTextChars;

  /// Insertion order = recency (oldest first).
  final _entries = <LyricsCacheKey, LocalLyricsRead>{};
  int _chars = 0;

  int get length => _entries.length;
  int get textChars => _chars;

  LocalLyricsRead? get(LyricsCacheKey key) {
    final hit = _entries.remove(key);
    if (hit != null) _entries[key] = hit;
    return hit;
  }

  void put(LyricsCacheKey key, LocalLyricsRead read) {
    final old = _entries.remove(key);
    if (old != null) _chars -= old.textLength;
    _entries[key] = read;
    _chars += read.textLength;
    while (_entries.length > maxEntries ||
        (_chars > maxTextChars && _entries.length > 1)) {
      final oldest = _entries.keys.first;
      _chars -= _entries.remove(oldest)!.textLength;
    }
  }

  /// The newest cached read of [id], without touching the recency; null when
  /// none (menus: "read this session").
  LocalLyricsRead? peek(TrackId id) {
    for (final key in _entries.keys.toList().reversed) {
      if (key.$1 == id) return _entries[key];
    }
    return null;
  }
}
