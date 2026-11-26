import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';
import 'package:kanaru/src/plugins/domain/search/store_search.dart';

void main() {
  test('a tag is case-insensitive and keeps the rest as words', () {
    final s = parseStoreSearch('  #LyRiC  net  ease ');
    expect(s.tags, {StoreTagKind.lyrics});
    expect(s.words, ['net', 'ease']);
    expect(s.kinds, {PluginKind.lyrics});
  });

  test('every alias names its kind', () {
    for (final kind in StoreTagKind.values) {
      for (final alias in kind.aliases) {
        expect(parseStoreSearch('#$alias').tags, {kind}, reason: alias);
      }
    }
  });

  test('translate covers both translation kinds', () {
    expect(parseStoreSearch('#translation').kinds, {
      PluginKind.translate,
      PluginKind.aiTranslate,
    });
  });

  test('several tags are the union of their kinds', () {
    final s = parseStoreSearch('#lyric #music');
    expect(s.kinds, {PluginKind.lyrics, PluginKind.streaming});
  });

  test('Vietnamese words and accents are not tags', () {
    for (final q in ['#lời', '#dịch', '#nhạc', '#lơi']) {
      final s = parseStoreSearch(q);
      expect(s.tags, isEmpty, reason: q);
      expect(s.words, [q], reason: q);
    }
  });

  test('an unknown tag is plain text; a bare # filters nothing', () {
    final s = parseStoreSearch('#zzz #');
    expect(s.tags, isEmpty);
    expect(s.words, ['#zzz']);
  });

  test('a tag still being typed filters nothing and is not text', () {
    for (final q in ['#ly', '#tr', '#s', '#MUS']) {
      final s = parseStoreSearch(q);
      expect(s.tags, isEmpty, reason: q);
      expect(s.words, isEmpty, reason: q);
    }
  });

  test('a lone # is ignored: neither a tag nor text', () {
    for (final q in ['#', ' # ', 'demo #']) {
      final s = parseStoreSearch(q);
      expect(s.tags, isEmpty, reason: q);
      expect(s.words, q == 'demo #' ? ['demo'] : isEmpty, reason: q);
    }
  });

  test('a route kind opens the search with its first tag and a space', () {
    expect(storeSearchForKind('lyrics'), '#lyric ');
    expect(storeSearchForKind('translate'), '#translate ');
    expect(storeSearchForKind('streaming'), '#streaming ');
    for (final k in ['skill', 'ai', 'speech', 'chat', '', null]) {
      expect(storeSearchForKind(k), '', reason: '$k');
    }
    // The text it makes is a complete tag.
    expect(parseStoreSearch(storeSearchForKind('lyrics')).tags, {
      StoreTagKind.lyrics,
    });
  });

  test('#ai tag filters ai-chat', () {
    expect(parseStoreSearch('#ai').kinds, {PluginKind.aiChat});
  });

  test('#chat alias filters ai-chat', () {
    expect(parseStoreSearch('#chat gemini').tags, {StoreTagKind.aiChat});
  });

  test('storeSearchForKind opens the AI filter', () {
    expect(storeSearchForKind('aiChat'), '#ai ');
  });
}
