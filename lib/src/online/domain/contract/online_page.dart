import 'online_card.dart';

/// How a section shows its cards.
enum SectionLayout { top, list, shelf }

/// A filter the plugin offers; [input] is handed back to `search` as given.
class PageFilter {
  const PageFilter({required this.title, required this.input});

  final String title;
  final String input;
}

class PageSection {
  const PageSection({
    this.title,
    required this.layout,
    required this.cards,
    this.moreFilter,
  });

  final String? title;
  final SectionLayout layout;
  final List<OnlineCard> cards;

  /// The `input` of a filter that shows the whole section, or null.
  final String? moreFilter;
}

/// One page of a search, after the reader's checks.
class OnlinePage {
  const OnlinePage({
    this.sections = const [],
    this.filters = const [],
    this.next,
  });

  final List<PageSection> sections;
  final List<PageFilter> filters;

  /// Token of the following page, or null at the end.
  final String? next;
}

/// A read page with what the reader dropped. [notes] hold item positions and
/// fixed reasons only, never plugin text.
class PageRead {
  const PageRead(this.page, [this.notes = const []]);

  final OnlinePage page;
  final List<String> notes;

  /// A short line for the app log, or null when nothing was dropped.
  String? get rejectionSummary => notes.isEmpty
      ? null
      : '${notes.length} dropped: ${notes.take(5).join('; ')}';
}
