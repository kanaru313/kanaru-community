import 'package:flutter/painting.dart';

/// Named text styles for the sizes the M3 `TextTheme` scale does not cover
/// (cover title and artist on Now Playing, mini player, queue strip).
///
/// Each style holds size and weight only: merge it over an M3 base style
/// (`textTheme.headlineSmall?.merge(KText.coverTitle)`) so colour, family and
/// line height stay with the site. The queue strip interpolates between a
/// `strip*` style and the matching `cover*` style with [TextStyle.lerp].
abstract final class KText {
  /// Track title on mobile Now Playing.
  static const TextStyle coverTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  /// Track title on the desktop Now Playing column.
  static const TextStyle coverTitleLarge = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
  );

  /// Artist line under the cover title.
  static const TextStyle coverArtist = TextStyle(fontSize: 15);

  /// Title in the collapsed queue strip (the flight end of [coverTitle]).
  static const TextStyle stripTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  /// Artist in the collapsed queue strip (the flight end of [coverArtist]).
  static const TextStyle stripArtist = TextStyle(fontSize: 13);

  /// Track title in the mini player.
  static const TextStyle miniTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  /// Artist in the mini player.
  static const TextStyle miniArtist = TextStyle(fontSize: 12);
}
