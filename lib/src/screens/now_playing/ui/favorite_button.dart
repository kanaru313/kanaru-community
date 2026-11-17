import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../library/state/favorites_providers.dart';
import '../../../media/domain/track_id.dart';

final _log = Logger('screens.now_playing.favorite_button');

/// ♥ for [trackId]: filled while it is a favorite, toggled through the
/// library's favorites controller. A failed write is logged and shown as a
/// snack bar; a tap while a write is in flight is ignored.
class FavoriteButton extends ConsumerStatefulWidget {
  const FavoriteButton({super.key, required this.trackId, this.iconSize});

  final TrackId trackId;
  final double? iconSize;

  @override
  ConsumerState<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<FavoriteButton> {
  bool _writing = false;

  @override
  void didUpdateWidget(FavoriteButton old) {
    super.didUpdateWidget(old);
    // A write in flight belongs to the previous track.
    if (old.trackId != widget.trackId) _writing = false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final favorite = ref.watch(isFavoriteProvider(widget.trackId));
    return KIconButton(
      icon: KIcons.heart,
      selectedIcon: KIcons.heartFilled,
      size: widget.iconSize ?? KIconSize.md,
      selected: favorite,
      tooltip: favorite
          ? l10n.playbackFavoriteRemove
          : l10n.playbackFavoriteAdd,
      onPressed: _toggle,
    );
  }

  Future<void> _toggle() async {
    if (_writing) return;
    // Taken before the await: the failure is shown even if the player was
    // rebuilt or closed while the write ran.
    final messenger = ScaffoldMessenger.maybeOf(context);
    final message = AppLocalizations.of(context).libraryFavoriteFailed;
    final controller = ref.read(favoritesControllerProvider);
    final id = widget.trackId;
    _writing = true;
    try {
      await controller.toggle(id);
    } on Object catch (e, s) {
      _log.warning('toggling favorite of $id failed', e, s);
      if (messenger != null && messenger.mounted) {
        showAppSnackBarOn(messenger, message);
      }
    } finally {
      _writing = false;
    }
  }
}
