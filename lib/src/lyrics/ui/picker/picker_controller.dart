import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../media/domain/track_id.dart';
import '../../domain/lyrics_facts.dart';
import '../../domain/online/online_search_state.dart';
import '../../state/online/online_search_provider.dart';
import '../../state/track_lyrics_providers.dart';

/// The text the picker starts from: "title artist" of the song, empty when it
/// has neither.
String defaultQueryText(LyricsFacts? facts) {
  final parts = [
    facts?.title?.trim() ?? '',
    facts?.artist?.trim() ?? '',
  ].where((p) => p.isNotEmpty);
  return parts.join(' ');
}

/// What the user chose in the picker. The results themselves are the
/// `onlineSearchProvider` state; a choice that no longer matches a result
/// (a newer search, a removed plugin) reads as none.
class PickerState {
  const PickerState({this.filter, this.selected, this.booted = false});

  /// Install id of the one source shown; null shows every source.
  final String? filter;

  /// The result chosen on the desktop list.
  final ResultRef? selected;

  /// The first search was started (before that the picker only waits).
  final bool booted;

  PickerState copyWith({
    String? Function()? filter,
    ResultRef? Function()? selected,
    bool? booted,
  }) => PickerState(
    filter: filter == null ? this.filter : filter(),
    selected: selected == null ? this.selected : selected(),
    booted: booted ?? this.booted,
  );
}

/// Filter, selection and the first search of one track's picker.
class PickerController extends Notifier<PickerState> {
  PickerController(this.trackId);

  final TrackId trackId;

  @override
  PickerState build() => const PickerState();

  OnlineSearchNotifier get _search =>
      ref.read(onlineSearchProvider(trackId).notifier);

  /// Starts the first search from the song's tags and returns the text it
  /// searched (to fill the field). Does nothing twice.
  Future<String> boot() async {
    final facts = await ref.read(lyricsFactsProvider(trackId).future);
    final text = defaultQueryText(facts);
    if (!ref.mounted) return text;
    if (state.booted) return text;
    state = state.copyWith(booted: true);
    unawaited(_search.search(text));
    return text;
  }

  /// Searches [text] (a newer search replaces the older one).
  Future<void> submit(String text) {
    state = state.copyWith(selected: () => null);
    return _search.search(text);
  }

  void setFilter(String? sourceId) =>
      state = state.copyWith(filter: () => sourceId, selected: () => null);

  void select(ResultRef? ref) => state = state.copyWith(selected: () => ref);

  /// Asks the disabled sources [ids] (all of them when null), only now.
  Future<void> searchDisabled({Set<String>? ids}) =>
      _search.searchDisabled(ids: ids);
}

final pickerControllerProvider = NotifierProvider.autoDispose
    .family<PickerController, PickerState, TrackId>(PickerController.new);
