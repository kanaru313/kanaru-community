import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../media/domain/track_id.dart';
import '../state/favorites_providers.dart';

final _log = Logger('library.favorite_toggle');

/// The write behind a ♥ button, shared by every one of them: toggles the
/// favorite of a track through the favorites controller, ignores a press while
/// a write of the same button runs, and shows (and logs) a failure.
mixin FavoriteToggle<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Number of the write in flight; 0 when none. A write only clears the
  /// flag it set, so a write of the previous track cannot free the next one.
  int _writeNo = 0;
  int _lastNo = 0;

  /// Call from `didUpdateWidget` when the button now shows another track: a
  /// write in flight belongs to the previous one.
  void forgetFavoriteWrite() => _writeNo = 0;

  Future<void> toggleFavorite(TrackId id) async {
    if (_writeNo != 0) return;
    // Taken before the await: the failure is shown even if the button was
    // rebuilt or removed while the write ran.
    final messenger = ScaffoldMessenger.maybeOf(context);
    final message = AppLocalizations.of(context).libraryFavoriteFailed;
    final controller = ref.read(favoritesControllerProvider);
    final mine = _writeNo = ++_lastNo;
    try {
      await controller.toggle(id);
    } on Object catch (e, s) {
      _log.warning('toggling favorite of $id failed', e, s);
      // A messenger whose page was popped during the write is gone: skip.
      if (messenger != null && messenger.mounted) {
        showAppSnackBarOn(messenger, message);
      }
    } finally {
      if (_writeNo == mine) _writeNo = 0;
    }
  }
}
