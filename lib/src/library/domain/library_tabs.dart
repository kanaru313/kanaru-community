/// The sub-lists of the Library page.
enum LibraryTab { songs, albums, artists, genres, languages, folders }

/// Order and visibility of the library tabs. Immutable; [order] holds every
/// tab exactly once and at least one tab is enabled. The constructor is not
/// `const` because it validates those rules.
class LibraryTabsConfig {
  LibraryTabsConfig(List<LibraryTab> order, Set<LibraryTab> enabled)
    : order = List.unmodifiable(order),
      enabled = Set.unmodifiable(enabled) {
    if (order.length != LibraryTab.values.length ||
        order.toSet().length != LibraryTab.values.length) {
      throw ArgumentError.value(order, 'order', 'must list every tab once');
    }
    if (enabled.isEmpty) {
      throw ArgumentError.value(enabled, 'enabled', 'is empty');
    }
  }

  /// Every tab on, in declaration order.
  static final LibraryTabsConfig defaults = LibraryTabsConfig(
    LibraryTab.values,
    LibraryTab.values.toSet(),
  );

  final List<LibraryTab> order;
  final Set<LibraryTab> enabled;

  /// Enabled tabs in display order.
  List<LibraryTab> get visible => [
    for (final t in order)
      if (enabled.contains(t)) t,
  ];

  /// Moves the tab at [from] so that it ends at index [to] of the new order
  /// (the index after removal; a `ReorderableListView` caller subtracts one
  /// when it moves down). Throws [RangeError] for an index outside the list.
  LibraryTabsConfig reorder(int from, int to) {
    RangeError.checkValidIndex(from, order, 'from');
    RangeError.checkValidIndex(to, order, 'to');
    final next = [...order];
    next.insert(to, next.removeAt(from));
    return LibraryTabsConfig(next, enabled);
  }

  /// Throws [StateError] when it would leave no tab enabled.
  LibraryTabsConfig withEnabled(LibraryTab tab, bool on) {
    final next = {...enabled};
    on ? next.add(tab) : next.remove(tab);
    if (next.isEmpty) {
      throw StateError('at least one library tab must stay enabled');
    }
    return LibraryTabsConfig(order, next);
  }

  /// JSON form: `{"order": [names], "disabled": [names]}`.
  Object toJson() => {
    'order': [for (final t in order) t.name],
    // Disabled names, so a tab added in a later version starts enabled.
    'disabled': [
      for (final t in order)
        if (!enabled.contains(t)) t.name,
    ],
  };

  /// Reads [toJson] output. Unknown tab names are ignored; tabs missing from
  /// `order` are appended in default order; an empty result
  /// enables every tab. The older `enabled` key is still read. Throws
  /// [FormatException] when [json] is not a map.
  static LibraryTabsConfig fromJson(Object? json) {
    if (json is! Map) throw const FormatException('library tabs: not a map');
    final order = <LibraryTab>[];
    for (final name in _names(json['order'])) {
      final tab = _byName(name);
      if (tab != null && !order.contains(tab)) order.add(tab);
    }
    final appended = [
      for (final t in LibraryTab.values)
        if (!order.contains(t)) t,
    ];
    order.addAll(appended);
    final Set<LibraryTab> enabled;
    if (json.containsKey('disabled')) {
      enabled = LibraryTab.values.toSet()
        ..removeAll({for (final n in _names(json['disabled'])) ?_byName(n)});
    } else {
      // Older form: the enabled names.
      enabled = {for (final n in _names(json['enabled'])) ?_byName(n)};
    }
    return LibraryTabsConfig(
      order,
      enabled.isEmpty ? LibraryTab.values.toSet() : enabled,
    );
  }

  static Iterable<String> _names(Object? list) =>
      list is List ? list.whereType<String>() : const [];

  static LibraryTab? _byName(String name) =>
      LibraryTab.values.where((t) => t.name == name).firstOrNull;

  @override
  bool operator ==(Object other) =>
      other is LibraryTabsConfig &&
      _sameList(other.order, order) &&
      other.enabled.length == enabled.length &&
      other.enabled.containsAll(enabled);

  @override
  int get hashCode => Object.hash(Object.hashAll(order), enabled.length);

  @override
  String toString() => 'LibraryTabsConfig($visible)';
}

bool _sameList(List<LibraryTab> a, List<LibraryTab> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
