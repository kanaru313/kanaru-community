import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../domain/history/history_models.dart';
import '../../domain/history/history_ranges.dart';
import 'history_providers.dart';
import 'local_day_provider.dart';

/// Range, and number of songs, of the Most played page. Kept for the
/// session, so coming back finds the page as it was left.
final mostPlayedRangeProvider =
    NotifierProvider<MostPlayedRangeNotifier, MostPlayedRange>(
      MostPlayedRangeNotifier.new,
    );

class MostPlayedRangeNotifier extends Notifier<MostPlayedRange> {
  @override
  MostPlayedRange build() => const MostPlayedRange();

  void set(MostPlayedRange range) => state = range;
}

final mostPlayedLimitProvider = NotifierProvider<MostPlayedLimitNotifier, int>(
  MostPlayedLimitNotifier.new,
);

class MostPlayedLimitNotifier extends Notifier<int> {
  @override
  int build() => defaultMostPlayedLimit;

  void set(int limit) => state = clampMostPlayedLimit(limit);
}

final _log = Logger('library.most_played');

/// The Most played list for the chosen range. While a new range or limit
/// loads, the previous list stays ([stale] true) so the page does not blink;
/// a retry after a failed read keeps the failed frame ([error] with [stale]).
class MostPlayedState {
  const MostPlayedState({this.data, this.stale = false, this.error});

  final MostPlayed? data;
  final bool stale;
  final Object? error;

  bool get loading => data == null && error == null;
}

final _mostPlayedReadProvider = FutureProvider.autoDispose<MostPlayed>((
  ref,
) async {
  final store = ref.read(historyStoreProvider);
  final range = ref.watch(mostPlayedRangeProvider);
  final limit = ref.watch(mostPlayedLimitProvider);
  final now = ref.watch(historyClockProvider)();
  ref.watch(localDayProvider);
  watchPlayChanges(ref, store, (_) => ref.invalidateSelf());
  var window = range.window(now);
  if (window != null) {
    final played = await store.playedRange();
    // A window that takes in every play answers like all time, cheaper.
    if (played == null || windowCoversPlays(window, played)) window = null;
  }
  try {
    return await store.top(window: window, limit: limit);
  } catch (e) {
    // The type only: the message of a database error may hold paths.
    _log.warning('Reading the most played list failed: ${e.runtimeType}');
    rethrow;
  }
});

final mostPlayedProvider = Provider.autoDispose<MostPlayedState>((ref) {
  final read = ref.watch(_mostPlayedReadProvider);
  final data = read.value;
  // A failed read is an error even when an earlier range's list is still
  // held: that list must not pass for the current one.
  if (read.hasError) {
    return MostPlayedState(error: read.error, stale: read.isLoading);
  }
  return MostPlayedState(data: data, stale: data != null && read.isLoading);
});
