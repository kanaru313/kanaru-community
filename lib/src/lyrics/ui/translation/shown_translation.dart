import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../media/domain/track_id.dart';
import '../../state/translation/translation_providers.dart';
import '../../state/translation/translation_view.dart';

/// The translation each mounted lyrics view shows, by track: a passive board.
/// Only a lyrics view (through [TranslationPresence]) writes to it, and
/// reading it never asks for a translation. The entry points (pill, button,
/// ⋮ item) read it, so they never start, or bill, a run of their own.
class ShownTranslations extends Notifier<Map<TrackId, TranslationView>> {
  final _holders = <TrackId, Set<Object>>{};

  @override
  Map<TrackId, TranslationView> build() => const {};

  /// [holder] (a mounted view) shows [view] for [id].
  void publish(Object holder, TrackId id, TranslationView view) {
    (_holders[id] ??= {}).add(holder);
    if (state[id] == view) return;
    state = {...state, id: view};
  }

  /// [holder] unmounted; the last holder of [id] clears its entry.
  void release(Object holder, TrackId id) {
    final holders = _holders[id];
    if (holders == null) return;
    holders.remove(holder);
    if (holders.isNotEmpty) return;
    _holders.remove(id);
    if (state.containsKey(id)) state = {...state}..remove(id);
  }
}

final shownTranslationProvider =
    NotifierProvider<ShownTranslations, Map<TrackId, TranslationView>>(
      ShownTranslations.new,
    );

/// Wraps a lyrics view: while [active] (translation is on) and mounted it
/// publishes the translation of [trackId] on [shownTranslationProvider]. It
/// is always in the tree, so turning translation on or off never rebuilds the
/// view's state. Its `ref.listen` is what keeps the view's translation
/// requested, like the lyrics lines under it.
class TranslationPresence extends ConsumerStatefulWidget {
  const TranslationPresence({
    super.key,
    required this.trackId,
    required this.active,
    required this.child,
  });

  final TrackId? trackId;
  final bool active;
  final Widget child;

  @override
  ConsumerState<TranslationPresence> createState() =>
      _TranslationPresenceState();
}

class _TranslationPresenceState extends ConsumerState<TranslationPresence> {
  late final ProviderContainer _container;
  TrackId? _published;

  @override
  void initState() {
    super.initState();
    // Taken now: dispose cannot look an ancestor up.
    _container = ProviderScope.containerOf(context, listen: false);
  }

  Object get _holder => this;

  /// Publishes [view] of [id] unless the widget moved on: a publish queued
  /// before `didUpdateWidget` changed the track or switched [active] off must
  /// not land after it (it would leave a holder nobody releases).
  void _publish(TrackId id, TranslationView view) {
    if (!mounted || widget.trackId != id || !widget.active) return;
    _published = id;
    ref.read(shownTranslationProvider.notifier).publish(_holder, id, view);
  }

  /// Gives the board entry back. Never touches `ref` (it may be gone) and
  /// waits a microtask: the tree may be building.
  void _release() {
    final id = _published;
    if (id == null) return;
    _published = null;
    final container = _container;
    scheduleMicrotask(() {
      try {
        container.read(shownTranslationProvider.notifier).release(_holder, id);
      } on StateError {
        // The whole scope is gone: nothing left to clear.
      }
    });
  }

  @override
  void didUpdateWidget(TranslationPresence old) {
    super.didUpdateWidget(old);
    if (old.trackId != widget.trackId || !widget.active) _release();
  }

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.trackId;
    if (widget.active && id != null) {
      ref.listen(trackTranslationProvider(id), (_, view) => _publish(id, view));
      final now = ref.read(trackTranslationProvider(id));
      // Not in build: a provider must not change while the tree builds.
      scheduleMicrotask(() => _publish(id, now));
    }
    return widget.child;
  }
}
