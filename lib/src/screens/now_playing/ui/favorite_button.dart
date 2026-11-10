import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../library/state/favorites_providers.dart';
import '../../../media/domain/track_id.dart';

/// ♥ for [trackId]: filled while it is a favorite, toggled through the
/// library's favorites controller.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.trackId, this.iconSize});

  final TrackId trackId;
  final double? iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final favorite = ref.watch(isFavoriteProvider(trackId));
    return IconButton(
      icon: Icon(favorite ? KIcons.heartFilled : KIcons.heart),
      iconSize: iconSize,
      color: favorite ? Theme.of(context).colorScheme.primary : null,
      isSelected: favorite,
      selectedIcon: Icon(KIcons.heartFilled),
      tooltip: favorite
          ? l10n.playbackFavoriteRemove
          : l10n.playbackFavoriteAdd,
      onPressed: () => ref.read(favoritesControllerProvider).toggle(trackId),
    );
  }
}
