/// Icon sizes by role. Every icon in the app takes one of these (or a size
/// derived from the box it sits in), never a number.
///
/// - [xs] 16: decorative glyphs (chip, permission check, inline language, scan
///   banner) and small glyphs (sort, breadcrumb chevron, filter bar).
/// - [sm] 20: pressable icons next to text (row heart and more button,
///   selection bar, menu row icons, queue row menu, count stepper, top bar).
/// - [md] 24: the default icon button, the repeat glyphs, the mini player
///   Next button.
/// - [lg] 32: Previous/Next on Now Playing, player-bar Play/Pause, the mini
///   player Play button at the end of the flight, the setup next button.
/// - [xl] 40: mobile Now Playing Play/Pause (inside its 72 dp disc), the
///   first-run logo.
/// - [hero] 48: empty states.
abstract final class KIconSize {
  static const double xs = 16;
  static const double sm = 20;
  static const double md = 24;
  static const double lg = 32;
  static const double xl = 40;
  static const double hero = 48;
}
