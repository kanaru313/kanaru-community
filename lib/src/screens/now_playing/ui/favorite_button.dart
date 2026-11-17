import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../library/state/favorites_providers.dart';
import '../../../library/ui/songs/favorite_toggle.dart';
import '../../../media/domain/track_id.dart';

/// ♥ for [trackId]: filled while it is a favorite, toggled through the
/// library's favorites controller (see [FavoriteToggle]: a failed write is
/// shown, a tap while a write runs is ignored).
class FavoriteButton extends ConsumerStatefulWidget {
  const FavoriteButton({super.key, required this.trackId, this.iconSize});

  final TrackId trackId;
  final double? iconSize;

  @override
  ConsumerState<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<FavoriteButton>
    with FavoriteToggle {
  @override
  void didUpdateWidget(FavoriteButton old) {
    super.didUpdateWidget(old);
    if (old.trackId != widget.trackId) forgetFavoriteWrite();
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
      onPressed: () => toggleFavorite(widget.trackId),
    );
  }
}
