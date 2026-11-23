import 'package:flutter/foundation.dart' show ValueChanged, VoidCallback;

import 'song_info_spec.dart';

/// What a row can make happen, handed down by the page that owns the route.
class SongInfoRowActions {
  const SongInfoRowActions({
    required this.openLink,
    required this.copied,
    required this.copyPath,
    required this.goFolder,
    required this.reveal,
    required this.toggleFavorite,
  });

  /// A link was chosen: the page closes and the library page opens.
  final ValueChanged<InfoLink> openLink;

  /// A value was copied: say so.
  final ValueChanged<String> copied;
  final VoidCallback copyPath;
  final VoidCallback goFolder;
  final VoidCallback reveal;

  /// Sets the favorite mark to the given value.
  final ValueChanged<bool> toggleFavorite;
}
