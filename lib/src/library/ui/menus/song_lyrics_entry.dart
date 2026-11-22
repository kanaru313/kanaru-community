import 'package:flutter/widgets.dart' show BuildContext;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../database/app_database.dart';
import '../../../media/domain/track_id.dart';

/// The lyrics entry of a song menu. `library` cannot import `lyrics`, so the
/// menu owns this interface and the app (above both) supplies the
/// implementation through [songLyricsEntryProvider].
abstract interface class SongLyricsEntry {
  /// The subtitle of the "Lyrics source" row for [id]: what shows ("Lyrics in
  /// tag · Synced", "Lyrics off"), or null when it is not known without
  /// reading the file. Does no file I/O and holds no provider subscription:
  /// a menu loads once.
  Future<String?> label(
    AppDatabase db,
    ProviderContainer container,
    TrackId id,
    AppLocalizations l10n,
  );

  /// Opens "Lyrics for this song" for [id]; it stays on that song whatever
  /// plays.
  Future<void> open(BuildContext context, TrackId id);
}

/// The lyrics entry of song menus; null (no row action) until the app
/// overrides it.
final songLyricsEntryProvider = Provider<SongLyricsEntry?>((_) => null);
