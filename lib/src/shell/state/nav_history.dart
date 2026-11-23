import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Back/forward history for the desktop top bar. go_router's stack does not
/// cover tab switches, so the shell keeps its own list.
///
/// Entries are snapshots of the router's match list, not locations: a page
/// opened with `push` keeps the base `uri` of the match list, so a location
/// would never see it. Going back or forward restores a snapshot.
class NavHistory extends ChangeNotifier {
  NavHistory(this._router)
    : _entries = [_router.routerDelegate.currentConfiguration] {
    _router.routerDelegate.addListener(_onRouteChanged);
  }

  static const _maxEntries = 50;

  final GoRouter _router;
  final List<RouteMatchList> _entries;
  int _index = 0;

  bool get canGoBack => _index > 0;
  bool get canGoForward => _index < _entries.length - 1;

  void back() => _moveTo(_index - 1);
  void forward() => _moveTo(_index + 1);

  void _moveTo(int target) {
    if (target < 0 || target >= _entries.length) return;
    // Index first: the router notification for this jump then matches the
    // current entry and is not recorded as a new visit.
    _index = target;
    final restored = _withLiveCompleters(_entries[target]);
    _entries[target] = restored;
    _router.restore(restored);
    notifyListeners();
  }

  void _onRouteChanged() {
    final current = _router.routerDelegate.currentConfiguration;
    final parts = _partsOf(current);
    final key = parts.join('|');
    final here = _partsOf(_entries[_index]);
    if (key == here.join('|')) {
      // Same place: keep the newest snapshot (its completers are the live ones).
      _entries[_index] = current;
      return;
    }
    if (_index > 0 &&
        here.length == parts.length + 1 &&
        key == _keyOf(_entries[_index - 1]) &&
        _isPrefix(parts, here) &&
        _sameBase(current, _entries[_index])) {
      // A real pop: the new place is the current one minus its last pushed
      // page and equals the previous entry. One step back, forward stays.
      // Anything else that lands on the previous place (tab ping-pong,
      // X -> A -> B -> A, `go` to the list from its pushed detail) is a new
      // visit.
      _index--;
      _entries[_index] = current;
      notifyListeners();
      return;
    }
    _entries
      ..removeRange(_index + 1, _entries.length)
      ..add(current);
    if (_entries.length > _maxEntries) _entries.removeAt(0);
    _index = _entries.length - 1;
    notifyListeners();
  }

  /// Identity of a place: the base location plus every pushed page (its key
  /// and location), outermost first. Completers are left out on purpose: a
  /// restored entry gets new ones.
  static String _keyOf(RouteMatchList list) => _partsOf(list).join('|');

  static bool _isPrefix(List<String> prefix, List<String> full) {
    for (var i = 0; i < prefix.length; i++) {
      if (prefix[i] != full[i]) return false;
    }
    return true;
  }

  /// Whether [a] and [b] share their base route matches object for object.
  /// A pop removes the last pushed page from the router's list and keeps the
  /// other matches; `go` parses a new list, so the same places reached by a
  /// navigation come with new objects.
  static bool _sameBase(RouteMatchList a, RouteMatchList b) {
    List<RouteMatch> base(List<RouteMatchBase> matches) => [
      for (final m in matches)
        if (m is ShellRouteMatch)
          ...base(m.matches)
        else if (m is RouteMatch && m is! ImperativeRouteMatch)
          m,
    ];
    final x = base(a.matches);
    final y = base(b.matches);
    if (x.length != y.length) return false;
    for (var i = 0; i < x.length; i++) {
      if (!identical(x[i], y[i])) return false;
    }
    return true;
  }

  static List<String> _partsOf(RouteMatchList list) {
    final parts = <String>[list.uri.toString()];
    void walk(List<RouteMatchBase> matches) {
      for (final m in matches) {
        if (m is ImperativeRouteMatch) {
          parts.add('${m.pageKey.value}@${m.matches.uri}');
        } else if (m is ShellRouteMatch) {
          walk(m.matches);
        }
      }
    }

    walk(list.matches);
    return parts;
  }

  /// [list] with a fresh [Completer] in every pushed page whose completer
  /// already completed (the page was popped): completing it again on the next
  /// pop would throw "Future already completed". Page keys are kept.
  static RouteMatchList _withLiveCompleters(RouteMatchList list) {
    List<RouteMatchBase> fix(List<RouteMatchBase> matches) => [
      for (final m in matches)
        if (m is ImperativeRouteMatch && m.completer.isCompleted)
          ImperativeRouteMatch(
            pageKey: m.pageKey,
            matches: m.matches,
            completer: Completer<Object?>(),
          )
        else if (m is ShellRouteMatch)
          ShellRouteMatch(
            route: m.route,
            matches: fix(m.matches),
            matchedLocation: m.matchedLocation,
            pageKey: m.pageKey,
            navigatorKey: m.navigatorKey,
          )
        else
          m,
    ];
    return RouteMatchList(
      matches: fix(list.matches),
      uri: list.uri,
      extra: list.extra,
      error: list.error,
      pathParameters: list.pathParameters,
    );
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }
}
