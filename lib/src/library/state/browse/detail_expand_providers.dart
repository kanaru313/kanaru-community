import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Detail pages whose description the user opened with "Show more", keyed by
/// the page id (`'${kind}:${id}'`, as the page's songs host does). Kept for
/// the session only, so leaving a page and coming back finds it still open.
class DetailDescriptionExpanded extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void set(String page, bool expanded) {
    if (state.contains(page) == expanded) return;
    state = expanded ? {...state, page} : ({...state}..remove(page));
  }
}

final detailDescriptionExpandedProvider =
    NotifierProvider<DetailDescriptionExpanded, Set<String>>(
      DetailDescriptionExpanded.new,
    );
