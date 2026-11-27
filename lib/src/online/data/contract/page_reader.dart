import '../../../plugins/domain/package/text_clean.dart';
import '../../domain/contract/contract_limits.dart';
import '../../domain/contract/online_card.dart';
import '../../domain/contract/online_output_exception.dart';
import '../../domain/contract/online_page.dart';
import 'card_reader.dart';
import 'output_json.dart';

/// Reads the output of `search`: `{filters?, sections?, items?, next?}`.
/// `sections` win when non-empty; otherwise `items` become one untitled list
/// section. Dropped parts are counted in the notes by position and a fixed
/// reason, never by plugin text. A `next` equal to [inputNext] (the plugin
/// would loop), over 8 KiB or empty reads as none. Throws
/// [OnlineOutputException] for any other shape.
PageRead readSearchOutput(String json, {String? inputNext}) {
  final data = decodeOutput(json);
  if (data is! Map) {
    throw const OnlineOutputException('search output must be an object');
  }
  final rawSections = data['sections'];
  final rawItems = data['items'];
  if (rawSections != null && rawSections is! List) {
    throw const OnlineOutputException('sections must be an array');
  }
  if (rawItems != null && rawItems is! List) {
    throw const OnlineOutputException('items must be an array');
  }
  final hasSections = rawSections is List && rawSections.isNotEmpty;
  if (!hasSections && rawItems is! List) {
    throw const OnlineOutputException(
      'search output has neither sections nor items',
    );
  }
  final rawNext = data['next'];
  if (rawNext != null && rawNext is! String) {
    throw const OnlineOutputException('next must be a string or null');
  }

  final notes = <String>[];
  final sections = <PageSection>[];
  final budget = _CardBudget();
  if (hasSections) {
    final list = rawSections;
    for (var i = 0; i < list.length; i++) {
      if (i >= maxSections) {
        notes.add(
          '${list.length - maxSections} sections over the limit of '
          '$maxSections',
        );
        break;
      }
      final section = _readSection(list[i], i + 1, budget, notes);
      if (section != null) sections.add(section);
    }
  } else {
    final cards = _readCards(rawItems as List, 'items', budget, notes);
    if (cards.isNotEmpty) {
      sections.add(PageSection(layout: SectionLayout.list, cards: cards));
    }
  }
  if (budget.over > 0) {
    notes.add('${budget.over} cards over the limit of $maxPageCards');
  }

  String? next = rawNext as String?;
  if (next != null && tokenBytes(next) > maxTokenBytes) {
    notes.add('next is larger than $maxTokenBytes bytes');
    next = null;
  }
  if (next != null && (next.isEmpty || next == inputNext)) next = null;

  return PageRead(
    OnlinePage(
      sections: List.unmodifiable(sections),
      filters: List.unmodifiable(_readFilters(data['filters'], notes)),
      next: next,
    ),
    List.unmodifiable(notes),
  );
}

/// Cards kept so far over the whole page.
class _CardBudget {
  int kept = 0;
  int over = 0;
}

PageSection? _readSection(
  Object? raw,
  int number,
  _CardBudget budget,
  List<String> notes,
) {
  if (raw is! Map) {
    notes.add('section #$number: must be an object');
    return null;
  }
  final items = raw['items'];
  if (items is! List) {
    notes.add('section #$number: lazy sections are not read');
    return null;
  }
  final SectionLayout layout =
      SectionLayout.values.where((l) => l.name == raw['layout']).firstOrNull ??
      SectionLayout.list;
  final rawTitle = raw['title'];
  String? title;
  if (rawTitle is String) {
    final cleaned = cleanText(rawTitle);
    final cut = String.fromCharCodes(cleaned.runes.take(maxSectionTitleRunes));
    title = cut.trim().isEmpty ? null : cut.trim();
  }
  final cards = _readCards(items, 'section #$number', budget, notes);
  if (cards.isEmpty) return null;
  return PageSection(
    title: title,
    layout: layout,
    cards: List.unmodifiable(cards),
    moreFilter: _readMore(raw['more'], number, notes),
  );
}

List<OnlineCard> _readCards(
  List<Object?> raw,
  String where,
  _CardBudget budget,
  List<String> notes,
) {
  final cards = <OnlineCard>[];
  final seen = <String>{};
  for (var j = 0; j < raw.length; j++) {
    final (card, problem) = readCard(raw[j]);
    if (card == null) {
      notes.add('$where item #${j + 1}: $problem');
    } else if (!seen.add(card.id)) {
      notes.add('$where item #${j + 1}: repeated id');
    } else if (budget.kept >= maxPageCards) {
      budget.over++;
    } else {
      budget.kept++;
      cards.add(card);
    }
  }
  return cards;
}

String? _readMore(Object? more, int number, List<String> notes) {
  if (more is! Map) return null;
  if (more['script'] != null) {
    notes.add('section #$number: more.script is not read');
  }
  final filter = more['filter'];
  if (filter is String &&
      filter.isNotEmpty &&
      tokenBytes(filter) <= maxTokenBytes) {
    return filter;
  }
  return null;
}

List<PageFilter> _readFilters(Object? raw, List<String> notes) {
  if (raw is! List) return const [];
  final out = <PageFilter>[];
  for (var i = 0; i < raw.length; i++) {
    if (i >= maxFilters) {
      notes.add(
        '${raw.length - maxFilters} filters over the limit of '
        '$maxFilters',
      );
      break;
    }
    final entry = raw[i];
    final rawTitle = entry is Map ? entry['title'] : null;
    final input = entry is Map ? entry['input'] : null;
    final title = rawTitle is String ? cleanText(rawTitle) : '';
    if (title.isEmpty ||
        title.runes.length > maxFilterTitleRunes ||
        input is! String ||
        input.isEmpty ||
        tokenBytes(input) > maxTokenBytes) {
      notes.add('filter #${i + 1}: title or input is not valid');
      continue;
    }
    out.add(PageFilter(title: title, input: input));
  }
  return out;
}
