import 'dart:collection';

import 'package:logging/logging.dart';

import '../../../media/domain/track_id.dart';
import '../../../media/domain/track_info.dart';

final _log = Logger('library.track_window');

/// Rows of a long ordered id list, read a page at a time for what is on
/// screen. Pure Dart.
///
/// Rows are cached **by [TrackId]**: [rowAt] returns the cached row of
/// `ids[i]` or null (a placeholder), never a row that belonged to another
/// index before the list changed, so the row painted at `i` is always the
/// track a tap at `i` plays.
///
/// The list calls [viewport] with the visible index range on every build.
/// The pages of that range are read (nothing else), at most [maxReads] at a
/// time, nearest to the range centre first; a queued page that left the range
/// is dropped without a read. A read in flight is never cancelled and its
/// answer is kept for the ids still in the list.
class TrackWindow {
  TrackWindow({
    required this.load,
    required this.onChanged,
    this.pageSize = 100,
    this.maxRows = 1200,
    this.maxReads = 2,
  });

  /// Reads the rows of one page of ids (missing and hidden rows may be
  /// absent from the answer).
  final Future<List<TrackInfo>> Function(List<TrackId> ids) load;

  /// Called after a read changed what [rowAt] returns.
  final void Function() onChanged;
  final int pageSize;
  final int maxRows;
  final int maxReads;

  List<TrackId> _ids = const [];
  Set<TrackId> _idSet = const {};

  /// Insertion order = least recently used first.
  final LinkedHashMap<TrackId, TrackInfo> _rows = LinkedHashMap();

  /// Cached ids whose row predates the last [setIds].
  final Set<TrackId> _stale = {};

  /// Ids a read found no row for (gone or hidden) since the last [setIds].
  final Set<TrackId> _absent = {};
  final Set<int> _inFlight = {};
  final Set<int> _failed = {};
  int _generation = 0;
  int _first = 0;
  int _last = -1;
  bool _disposed = false;

  /// The error of the last failed page read, until the next [setIds].
  Object? error;

  List<TrackId> get ids => _ids;
  int get length => _ids.length;

  /// Whether the page holding index [i] failed to read (until the next
  /// [setIds], [invalidate], or the page leaving the range).
  bool isFailed(int i) => _failed.contains(i ~/ pageSize);

  /// Number of cached rows (for tests and diagnostics).
  int get cachedRows => _rows.length;

  /// Replaces the id list. Cached rows of ids that are still listed stay and
  /// are re-read when their page is next in view.
  void setIds(List<TrackId> ids) {
    if (_disposed) return;
    _generation++;
    _ids = ids;
    _idSet = ids.toSet();
    _stale
      ..clear()
      ..addAll(_rows.keys);
    _absent.clear();
    _failed.clear();
    error = null;
    _pump();
  }

  /// The row of `ids[i]`, or null while it is not read (or has no row).
  TrackInfo? rowAt(int i) {
    if (i < 0 || i >= _ids.length) return null;
    final id = _ids[i];
    final row = _rows.remove(id);
    if (row == null) return null;
    _rows[id] = row; // most recently used
    return row;
  }

  /// Marks every cached row stale and reads the pages in view again, for a
  /// change to the rows' data (a cover, a title) that left the id order as it
  /// was, so no [setIds] followed. A song list calls it on each tick of
  /// `songRowsRevisionProvider`.
  void invalidate() {
    if (_disposed) return;
    // A read already in flight began before this change: its rows are
    // delivered but read again.
    _generation++;
    _stale.addAll(_rows.keys);
    _absent.clear();
    _failed.clear();
    error = null;
    // The failed rows show their retry state until this: redraw at once.
    onChanged();
    _pump();
  }

  /// Tells the window which indexes are on screen (inclusive) and starts the
  /// reads they need.
  ///
  /// Only the pages of this range are read, so a list passes the whole range
  /// it has built, cache extent included, not just the painted rows;
  /// otherwise the first row of each new page paints as a placeholder.
  void viewport(int first, int last) {
    if (_disposed) return;
    _first = first;
    _last = last;
    // A page that failed and left the range is tried again when it returns.
    if (_failed.isNotEmpty) {
      final firstPage = (first < 0 ? 0 : first) ~/ pageSize;
      final lastPage = (last < 0 ? 0 : last) ~/ pageSize;
      _failed.removeWhere((p) => p < firstPage || p > lastPage);
      if (_failed.isEmpty) error = null;
    }
    _pump();
  }

  void dispose() => _disposed = true;

  bool _pageNeedsRead(int page) {
    final end = _end(page);
    for (var i = page * pageSize; i < end; i++) {
      final id = _ids[i];
      if (_absent.contains(id)) continue;
      if (!_rows.containsKey(id) || _stale.contains(id)) return true;
    }
    return false;
  }

  int _end(int page) {
    final end = (page + 1) * pageSize;
    return end > _ids.length ? _ids.length : end;
  }

  void _pump() {
    if (_ids.isEmpty || _last < _first) return;
    final lo = _first < 0 ? 0 : _first;
    final hi = _last >= _ids.length ? _ids.length - 1 : _last;
    if (hi < lo) return;
    final firstPage = lo ~/ pageSize, lastPage = hi ~/ pageSize;
    final centre = (firstPage + lastPage) / 2;
    final wanted = [
      for (var p = firstPage; p <= lastPage; p++)
        if (!_inFlight.contains(p) && !_failed.contains(p) && _pageNeedsRead(p))
          p,
    ]..sort((a, b) => (a - centre).abs().compareTo((b - centre).abs()));
    for (final page in wanted) {
      if (_inFlight.length >= maxReads) break;
      _read(page);
    }
  }

  Future<void> _read(int page) async {
    _inFlight.add(page);
    final generation = _generation;
    final pageIds = _ids.sublist(page * pageSize, _end(page));
    List<TrackInfo>? infos;
    try {
      infos = await load(pageIds);
    } on Object catch (e, s) {
      _log.warning('page $page read failed', e, s);
      if (generation == _generation) {
        _failed.add(page);
        error = e;
      }
    }
    _inFlight.remove(page);
    if (_disposed) return;
    if (infos != null) {
      final got = <TrackId>{};
      for (final info in infos) {
        // A missing or hidden row is treated as absent, also when an earlier
        // read cached it while it was present.
        if (info.status != TrackAvailability.present) {
          _rows.remove(info.id);
          _stale.remove(info.id);
          continue;
        }
        got.add(info.id);
        if (!_idSet.contains(info.id)) continue;
        _rows.remove(info.id);
        _rows[info.id] = info;
        // A read that began before the last setIds may predate the change
        // that caused it: show the row, but read it again.
        if (generation == _generation) {
          _stale.remove(info.id);
        } else {
          _stale.add(info.id);
        }
      }
      if (generation == _generation) {
        _absent.addAll(pageIds.where((id) => !got.contains(id)));
      }
      while (_rows.length > maxRows) {
        final oldest = _rows.keys.first;
        _rows.remove(oldest);
        _stale.remove(oldest);
      }
    }
    onChanged();
    _pump();
  }
}
