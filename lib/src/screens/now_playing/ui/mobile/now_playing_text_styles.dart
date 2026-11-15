import 'package:material_ui/material_ui.dart';

/// Text styles of the track title and artist on Now Playing and in the queue
/// strip: M3 text roles, a bold weight for titles. The strip text flies
/// between the two pairs, so both come from here.

/// Title under the cover (Now Playing).
TextStyle? coverTitleStyle(TextTheme text) =>
    text.titleLarge?.copyWith(fontWeight: FontWeight.w700);

/// Artist under the cover (Now Playing).
TextStyle? coverArtistStyle(TextTheme text) => text.bodyLarge;

/// Title in the queue strip (the mini player's place).
TextStyle? stripTitleStyle(TextTheme text) =>
    text.titleMedium?.copyWith(fontWeight: FontWeight.w700);

/// Artist in the queue strip.
TextStyle? stripArtistStyle(TextTheme text) => text.bodyMedium;
