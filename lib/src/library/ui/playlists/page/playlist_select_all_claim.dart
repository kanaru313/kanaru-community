import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../media/domain/track_id.dart';
import '../../../state/browse/selection_providers.dart';
import '../../selection/selection_shortcuts.dart';

/// Makes a page the target of "select all" (Ctrl+A) while it is the one on
/// screen: registers its playable ids in `activeTrackListProvider` (after the
/// frame, only while still current) and releases them when another page
/// covers it or it goes. Owned by a State above the wide / narrow layout
/// switch, so a resize never drops the claim.
class SelectAllClaim {
  SelectAllClaim(BuildContext context, WidgetRef ref)
    : _active = ref.read(activeTrackListProvider.notifier),
      _shortcut = SelectAllShortcut(
        context,
        ProviderScope.containerOf(context, listen: false),
      );

  final ActiveTrackList _active;
  final SelectAllShortcut _shortcut;
  List<TrackId>? _registered;

  /// Call on every build: [current] is whether the page is on screen now.
  /// [ids] must keep its identity while its content does not change.
  void sync(bool current, List<TrackId> ids, bool Function() mounted) {
    if (current) {
      _shortcut.attach();
      if (!identical(_registered, ids)) {
        _registered = ids;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted() && identical(_registered, ids)) _active.set(ids);
        });
      }
    } else {
      _shortcut.detach();
      final old = _registered;
      if (old != null) {
        _registered = null;
        WidgetsBinding.instance.addPostFrameCallback((_) => _active.clear(old));
      }
    }
  }

  void dispose() {
    final registered = _registered;
    _shortcut.detach();
    if (registered != null) {
      // Not while the tree is being torn down: listeners rebuild widgets.
      Future.microtask(() => _active.clear(registered));
    }
  }
}
