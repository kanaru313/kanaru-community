/// Size of the translation line (setting `lyrics.translation.size`), one
/// value for every song. Each member holds the exact sizes of its level;
/// [medium] is what the app drew before the setting existed.
enum TranslationSize {
  small(
    translation: 0.52,
    replacedOriginal: 0.42,
    plainTranslation: 0.672,
    plainReplacedOriginal: 0.588,
    card: 11,
  ),
  medium(
    translation: 0.62,
    replacedOriginal: 0.5,
    plainTranslation: 0.8,
    plainReplacedOriginal: 0.7,
    card: 13,
  ),
  large(
    translation: 0.75,
    replacedOriginal: 0.6,
    plainTranslation: 0.968,
    plainReplacedOriginal: 0.847,
    card: 15,
  );

  const TranslationSize({
    required this.translation,
    required this.replacedOriginal,
    required this.plainTranslation,
    required this.plainReplacedOriginal,
    required this.card,
  });

  /// Translation under a synced line: fraction of the line's size.
  final double translation;

  /// The original of a replaced synced line: fraction of the line's size.
  final double replacedOriginal;

  /// The same two for plain lyrics, as fractions of the plain text size.
  final double plainTranslation;
  final double plainReplacedOriginal;

  /// Font size (logical pixels) of the translation of the sung line on the
  /// Now Playing card.
  final double card;

  /// Its line height: the 18 / 13 of the medium size at every size.
  double get cardLineHeight => card * 18 / 13;
}
