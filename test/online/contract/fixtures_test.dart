import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/online/data/contract/autocomplete_reader.dart';
import 'package:kanaru/src/online/data/contract/page_reader.dart';
import 'package:kanaru/src/online/data/contract/stream_reader.dart';
import 'package:kanaru/src/online/domain/contract/online_card.dart';
import 'package:kanaru/src/online/domain/contract/online_output_exception.dart';
import 'package:kanaru/src/online/domain/contract/stream_answer.dart';
import 'package:kanaru/src/online/domain/tracks/cover_rule.dart';
import 'package:kanaru/src/plugins/domain/package/host_rules.dart';

/// Hosts of each plugin's manifest, copied from
/// `kanaru-plugins/src/streaming/<slug>/plugin.json` (tests never read the
/// plugins clone). Re-copy them when a plugin changes its hosts.
const _manifestHosts = <String, List<String>>{
  // audius, plugin version 4
  'audius': [
    'api.audius.co',
    'audius.co',
    '*.audius.co',
    '*.eeba4a6ca56a0d87af802270217c2a51.r2.cloudflarestorage.com',
    'validator.eeba4a6ca56a0d87af802270217c2a51.r2.cloudflarestorage.com',
  ],
  // jamendo, plugin version 1
  'jamendo': [
    'api.jamendo.com',
    '*.jamendo.com',
    'prod-1.storage.jamendo.com',
    'usercontent.jamendo.com',
    'mp3d.jamendo.com',
    'jamen.do',
  ],
  // youtube, plugin version 3
  'youtube': ['www.youtube.com', 'i.ytimg.com', '*.googlevideo.com'],
};

const _containers = <String, Set<StreamContainer>>{
  'audius': {StreamContainer.mp3},
  'jamendo': {StreamContainer.mp3},
  'youtube': {StreamContainer.webm, StreamContainer.mp4},
};

String _read(String slug, String script) =>
    File('test/online/fixtures/$slug/$script.json').readAsStringSync();

void main() {
  for (final slug in _manifestHosts.keys) {
    group('$slug fixtures', () {
      final hosts = _manifestHosts[slug]!;

      test('search reads with sections and track cards', () {
        final read = readSearchOutput(_read(slug, 'search'));
        if (slug == 'jamendo') {
          // Jamendo's filters carry `id` instead of `input`: all six are
          // dropped with a note, the cards read fine.
          expect(read.notes, hasLength(6));
          expect(read.notes, everyElement(startsWith('filter #')));
          expect(read.page.filters, isEmpty);
        } else {
          expect(read.notes, isEmpty);
        }
        expect(read.page.sections, isNotEmpty);
        final cards = [for (final s in read.page.sections) ...s.cards];
        final tracks = cards.where((c) => c.kind == OnlineCardKind.track);
        expect(tracks, isNotEmpty);
        for (final card in cards) {
          expect(card.id, isNotEmpty);
          expect(card.id, isNot(contains('://')));
        }
      });

      test('stream reads as a playable answer on a covered host', () {
        final read = readStreamOutput(_read(slug, 'stream'));
        expect(read, isA<StreamPlayable>());
        final answer = (read as StreamPlayable).answer;
        expect(_containers[slug], contains(answer.container));
        expect(hostSetCovers(hosts, [answer.url.host]), isTrue);
        expect(answer.url.query, 'fixture=1');
      });

      test('autocomplete follows the contract', () {
        final json = _read(slug, 'autocomplete');
        if (slug == 'jamendo') {
          // Jamendo answers {suggestions: [...]} instead of an array.
          expect(
            () => readAutocompleteOutput(json),
            throwsA(isA<OnlineOutputException>()),
          );
          return;
        }
        final list = readAutocompleteOutput(json);
        expect(list.length, inInclusiveRange(1, 10));
      });

      test('covers persist only on manifest hosts', () {
        final read = readSearchOutput(_read(slug, 'search'));
        final cards = [for (final s in read.page.sections) ...s.cards];
        final persisted = [
          for (final c in cards)
            persistableCoverUrl(
              c.artworkUrl,
              manifestHosts: hosts.toSet(),
              configValues: const [],
            ),
        ];
        // Every kept link is https and on a manifest host.
        for (final url in persisted.whereType<String>()) {
          final uri = Uri.parse(url);
          expect(uri.scheme, 'https');
          expect(hostSetCovers(hosts, [uri.host]), isTrue);
        }
        // Covers on a host outside the manifest never persist.
        for (var i = 0; i < cards.length; i++) {
          final art = cards[i].artworkUrl;
          if (art != null && !hostSetCovers(hosts, [Uri.parse(art).host])) {
            expect(persisted[i], isNull);
          }
        }
        if (slug != 'audius') {
          expect(persisted.whereType<String>(), isNotEmpty);
        }
      });
    });
  }

  test('the first track card id of each search is a plain id', () {
    for (final slug in _manifestHosts.keys) {
      final read = readSearchOutput(_read(slug, 'search'));
      final first = [for (final s in read.page.sections) ...s.cards]
          .firstWhere((c) => c.kind == OnlineCardKind.track);
      expect(first.id, isNot(contains('/')));
    }
  });
}
