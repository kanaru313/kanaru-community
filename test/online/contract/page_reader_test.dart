import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/online/data/contract/page_reader.dart';
import 'package:kanaru/src/online/domain/contract/online_output_exception.dart';
import 'package:kanaru/src/online/domain/contract/online_page.dart';

Map<String, Object?> c(Object id, [String title = 'T']) => {
  'id': '$id',
  'title': title,
};

PageRead read(Object? v, {String? inputNext}) =>
    readSearchOutput(jsonEncode(v), inputNext: inputNext);

void main() {
  test('sections win over items (Audius shape)', () {
    final r = read({
      'filters': [
        {'title': 'Tracks', 'input': 'f1'},
      ],
      'sections': [
        {
          'title': 'Top',
          'layout': 'top',
          'items': [c(1), c(2)],
          'more': {'filter': 'f1'},
        },
      ],
      'items': [c(1), c(2), c(3)],
      'next': 'n2',
    });
    expect(r.page.sections, hasLength(1));
    final s = r.page.sections.single;
    expect(s.title, 'Top');
    expect(s.layout, SectionLayout.top);
    expect(s.cards, hasLength(2));
    expect(s.moreFilter, 'f1');
    expect(r.page.filters.single.input, 'f1');
    expect(r.page.next, 'n2');
    expect(r.notes, isEmpty);
    expect(r.rejectionSummary, isNull);
  });

  test('items only: one untitled list section; empty sections ignored', () {
    for (final v in [
      {
        'items': [c(1)],
      },
      {
        'sections': [],
        'items': [c(1)],
      },
    ]) {
      final r = read(v);
      expect(r.page.sections.single.title, isNull);
      expect(r.page.sections.single.layout, SectionLayout.list);
      expect(r.page.sections.single.cards, hasLength(1));
    }
  });

  test('unknown layout reads as list', () {
    final r = read({
      'sections': [
        {
          'layout': 'carousel',
          'items': [c(1)],
        },
        {
          'layout': 5,
          'items': [c(2)],
        },
        {
          'layout': 'shelf',
          'items': [c(3)],
        },
      ],
    });
    expect(r.page.sections.map((s) => s.layout), [
      SectionLayout.list,
      SectionLayout.list,
      SectionLayout.shelf,
    ]);
  });

  test('lazy section dropped with a note', () {
    final r = read({
      'sections': [
        {'title': 'Lazy', 'script': 'home'},
        {
          'items': [c(1)],
        },
      ],
    });
    expect(r.page.sections, hasLength(1));
    expect(r.notes, ['section #1: lazy sections are not read']);
  });

  test('more.script is noted, more without filter is none', () {
    final r = read({
      'sections': [
        {
          'items': [c(1)],
          'more': {'script': 'x', 'filter': 'f'},
        },
        {
          'items': [c(2)],
          'more': {'script': 'x'},
        },
        {
          'items': [c(3)],
          'more': {'filter': ''},
        },
      ],
    });
    expect(r.page.sections.map((s) => s.moreFilter), ['f', null, null]);
    expect(r.notes, hasLength(2));
    expect(r.notes.first, contains('more.script'));
  });

  test('title is cut to 100 runes; empty becomes null', () {
    final r = read({
      'sections': [
        {
          'title': 'a' * 150,
          'items': [c(1)],
        },
        {
          'title': '​',
          'items': [c(2)],
        },
      ],
    });
    expect(r.page.sections[0].title, 'a' * 100);
    expect(r.page.sections[1].title, isNull);
  });

  test('cards are capped at 200 over the whole page', () {
    final r = read({
      'sections': [
        for (var s = 0; s < 3; s++)
          {
            'items': [for (var i = 0; i < 67; i++) c('$s-$i')],
          },
      ],
    });
    final kept = r.page.sections.fold<int>(0, (n, s) => n + s.cards.length);
    expect(kept, 200);
    expect(r.notes, ['1 cards over the limit of 200']);
  });

  test('repeated id inside a section drops the later card', () {
    final r = read({
      'sections': [
        {
          'items': [c(1, 'first'), c(1, 'second'), c(2)],
        },
        {
          'items': [c(1)],
        },
      ],
    });
    expect(r.page.sections[0].cards.map((e) => e.title), ['first', 'T']);
    expect(r.page.sections[1].cards, hasLength(1));
    expect(r.notes, ['section #1 item #2: repeated id']);
  });

  test('a section left empty is dropped silently', () {
    final r = read({
      'sections': [
        {'items': []},
        {
          'items': [c(1)],
        },
      ],
    });
    expect(r.page.sections, hasLength(1));
    expect(r.notes, isEmpty);
  });

  test('sections over 20 are dropped with a note', () {
    final r = read({
      'sections': [
        for (var i = 0; i < 22; i++)
          {
            'items': [c(i)],
          },
      ],
    });
    expect(r.page.sections, hasLength(20));
    expect(r.notes, ['2 sections over the limit of 20']);
  });

  test('bad filters are dropped', () {
    final r = read({
      'items': [c(1)],
      'filters': [
        {'title': 'ok', 'input': 'i'},
        {'title': '', 'input': 'i'},
        {'title': 'a' * 51, 'input': 'i'},
        {'title': 'x', 'input': ''},
        {'title': 'x', 'input': 'a' * (8 * 1024 + 1)},
        {'title': 'x'},
        'str',
      ],
    });
    expect(r.page.filters.map((f) => f.title), ['ok']);
    expect(r.notes, hasLength(6));
    expect(read({'items': [], 'filters': 'x'}).page.filters, isEmpty);
    final many = read({
      'items': [],
      'filters': [
        for (var i = 0; i < 25; i++) {'title': 't$i', 'input': 'i'},
      ],
    });
    expect(many.page.filters, hasLength(20));
  });

  test('next: loop, empty and oversize read as none', () {
    String? next(Object? n, {String? input}) => read({
      'items': [c(1)],
      'next': n,
    }, inputNext: input).page.next;
    expect(next('p2', input: 'p2'), isNull);
    expect(next('p3', input: 'p2'), 'p3');
    expect(next(''), isNull);
    expect(next(null), isNull);
    expect(next('a' * (8 * 1024)), isNotNull);
    expect(next('a' * (8 * 1024 + 1)), isNull);
    expect(next('é' * (4 * 1024 + 1)), isNull);
  });

  test('wrong shapes throw', () {
    for (final v in [
      [1],
      'x',
      {'sections': {}},
      {'items': 'x'},
      <String, Object?>{},
      {'sections': []},
      {'items': [], 'next': 5},
    ]) {
      expect(
        () => read(v),
        throwsA(isA<OnlineOutputException>()),
        reason: '$v',
      );
    }
    expect(
      () => readSearchOutput('{nope'),
      throwsA(isA<OnlineOutputException>()),
    );
  });

  test('notes never hold plugin text', () {
    const hostile = 'EVIL-<script>-TITLE';
    final r = read({
      'sections': [
        {
          'title': hostile,
          'items': [
            {'id': 'https://$hostile.example/', 'title': hostile},
            {'id': '..', 'title': hostile},
            {'id': 'ok', 'title': ''},
            {'id': 'dup', 'title': hostile},
            {'id': 'dup', 'title': hostile},
          ],
          'more': {'script': hostile},
        },
        {'title': hostile, 'script': hostile},
      ],
      'filters': [
        {'title': hostile, 'input': ''},
      ],
    });
    expect(r.notes, isNotEmpty);
    expect(r.rejectionSummary, isNot(contains('EVIL')));
    expect(r.notes.join(), isNot(contains('EVIL')));
    expect(r.rejectionSummary, startsWith('${r.notes.length} dropped: '));
    expect('; '.allMatches(r.rejectionSummary!).length, lessThanOrEqualTo(4));
  });
}
