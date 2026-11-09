import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Back/forward history of locations for the desktop top bar. go_router's
/// stack does not cover tab switches, so the shell keeps its own list.
class NavHistory extends ChangeNotifier {
  NavHistory(this._router) : _entries = [_locationOf(_router)] {
    _router.routerDelegate.addListener(_onRouteChanged);
  }

  static const _maxEntries = 50;

  final GoRouter _router;
  final List<String> _entries;
  int _index = 0;

  static String _locationOf(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.toString();

  bool get canGoBack => _index > 0;
  bool get canGoForward => _index < _entries.length - 1;

  void back() => _moveTo(_index - 1);
  void forward() => _moveTo(_index + 1);

  void _moveTo(int target) {
    if (target < 0 || target >= _entries.length) return;
    // Index first: the router notification for this jump then matches the
    // current entry and is not recorded as a new visit.
    _index = target;
    _router.go(_entries[target]);
    notifyListeners();
  }

  void _onRouteChanged() {
    final location = _locationOf(_router);
    if (location == _entries[_index]) return;
    _entries
      ..removeRange(_index + 1, _entries.length)
      ..add(location);
    if (_entries.length > _maxEntries) _entries.removeAt(0);
    _index = _entries.length - 1;
    notifyListeners();
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }
}
