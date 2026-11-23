import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../media/domain/track_id.dart';
import '../../domain/online/lyrics_match.dart';
import '../../domain/online/lyrics_source.dart';
import '../../domain/online/online_search_state.dart';
import '../../state/online/lyrics_sources_provider.dart';
import '../../state/online/online_search_provider.dart';
import '../../state/track_lyrics_providers.dart';
import 'picker_controller.dart';

/// One source's part of the picker, with the source it came from.
class PickerGroup {
  const PickerGroup(this.source, this.part);

  final LyricsSource source;
  final SourceSearch part;

  /// Switched off for the automatic search; asked only on request.
  bool get off => !source.enabled;
}

/// Everything the picker draws, from the search, the sources and the song.
class PickerView {
  const PickerView({
    required this.waiting,
    required this.text,
    required this.groups,
    required this.pending,
    required this.enabledCount,
    required this.songDuration,
    required this.filter,
    required this.askedOff,
  });

  /// The sources or the first search are not there yet.
  final bool waiting;

  /// The text last searched.
  final String text;

  /// Every source that was asked, enabled ones first, then the disabled ones
  /// asked on request.
  final List<PickerGroup> groups;

  /// Disabled sources not asked yet.
  final List<LyricsSource> pending;
  final int enabledCount;
  final Duration? songDuration;

  /// The source shown alone, or null for all of them.
  final String? filter;

  /// A disabled source was asked on request in this search.
  final bool askedOff;

  /// The groups the filter lets through.
  List<PickerGroup> get visible => filter == null
      ? groups
      : [
          for (final g in groups)
            if (g.source.id == filter) g,
        ];

  bool get searching =>
      groups.any((g) => g.part.phase == SourceSearchPhase.loading);

  /// The visible results in list order.
  Iterable<LyricsMatch> get visibleMatches sync* {
    for (final g in visible) {
      if (g.part.phase == SourceSearchPhase.results) yield* g.part.matches;
    }
  }

  /// The group and match of [ref] among the visible results, or null.
  ({PickerGroup group, LyricsMatch match})? find(ResultRef? ref) {
    if (ref == null) return null;
    for (final g in visible) {
      if (g.part.phase != SourceSearchPhase.results) continue;
      for (final m in g.part.matches) {
        if (m.candidate.ref == ref) return (group: g, match: m);
      }
    }
    return null;
  }

  /// The first visible result: what the desktop list starts on.
  ({PickerGroup group, LyricsMatch match})? get first {
    for (final g in visible) {
      if (g.part.phase == SourceSearchPhase.results &&
          g.part.matches.isNotEmpty) {
        return (group: g, match: g.part.matches.first);
      }
    }
    return null;
  }
}

final pickerViewProvider = Provider.autoDispose.family<PickerView, TrackId>((
  ref,
  id,
) {
  final loaded = ref.watch(lyricsSourcesLoadedProvider);
  final sources = ref.watch(lyricsSourcesProvider);
  final search = ref.watch(onlineSearchProvider(id));
  final picker = ref.watch(pickerControllerProvider(id));
  final duration = ref.watch(
    lyricsFactsProvider(id).select((f) => f.value?.duration),
  );
  final asked = <PickerGroup>[
    for (final s in sources)
      if (search.bySource[s.id] case final part?) PickerGroup(s, part),
  ];
  // Enabled sources first, the ones asked on request after them.
  final groups = [...asked.where((g) => !g.off), ...asked.where((g) => g.off)];
  final filter = groups.any((g) => g.source.id == picker.filter)
      ? picker.filter
      : null;
  return PickerView(
    waiting: !loaded || !picker.booted,
    text: search.text,
    groups: groups,
    pending: [
      for (final s in sources)
        if (!s.enabled && !search.bySource.containsKey(s.id)) s,
    ],
    enabledCount: sources.where((s) => s.enabled).length,
    songDuration: duration,
    filter: filter,
    askedOff: search.onDemand.isNotEmpty,
  );
});
