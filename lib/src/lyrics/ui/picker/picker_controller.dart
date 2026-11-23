import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../media/domain/track_id.dart';
import '../../domain/lyrics_facts.dart';
import '../../domain/online/online_search_state.dart';
import '../../state/online/online_search_provider.dart';
import '../../state/track_lyrics_providers.dart';

final _log = Logger('lyrics_picker');

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
  const PickerState({
    this.filter,
    this.selected,
    this.booted = false,
    this.text = '',
  });

  /// Install id of the one source shown; null shows every source.
  final String? filter;

  /// The result chosen on the desktop list.
  final ResultRef? selected;

  /// The first search was started (before that the picker only waits).
  final bool booted;

  /// What the search field holds. Kept here so it survives a change of
  /// layout (the window crossing the desktop breakpoint rebuilds the picker).
  final String text;

  PickerState copyWith({
    String? Function()? filter,
    ResultRef? Function()? selected,
    bool? booted,
    String? text,
  }) => PickerState(
    filter: filter == null ? this.filter : filter(),
    selected: selected == null ? this.selected : selected(),
    booted: booted ?? this.booted,
    text: text ?? this.text,
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

  /// Starts the first search from the song's tags and returns the text the
  /// field holds. Does nothing twice, and never replaces a search the user
  /// already made (a `submit` while the song's facts were loading). A failed
  /// facts read searches with nothing: the picker leaves its loading state
  /// and the user types the query.
  Future<String> boot() async {
    if (state.booted) return state.text;
    LyricsFacts? facts;
    try {
      facts = await ref.read(lyricsFactsProvider(trackId).future);
    } on Object catch (e) {
      _log.warning('picker facts read failed: ${e.runtimeType}');
    }
    if (!ref.mounted || state.booted) return state.text;
    final text = defaultQueryText(facts);
    state = state.copyWith(booted: true, text: text);
    unawaited(_search.search(text));
    return text;
  }

  /// Remembers what the field holds.
  void setText(String text) {
    if (text != state.text) state = state.copyWith(text: text);
  }

  /// Searches [text] (a newer search replaces the older one).
  Future<void> submit(String text) {
    state = state.copyWith(booted: true, text: text, selected: () => null);
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
