/// How far the assistant may act without asking. The names are the stored
/// values of `ai_conversations.permission` (`AiPermissionValues`).
enum AiPermission {
  /// Reads only; every write tool is refused.
  readOnly,

  /// Every write waits for the user's confirmation.
  ask,

  /// Writes run without a card (item caps still apply).
  auto;

  /// The stored text.
  String get wire => name;

  /// The permission stored as [raw]. Throws [FormatException] for any other
  /// value, so a caller never guesses a level.
  static AiPermission parse(Object? raw) {
    if (raw is String) {
      for (final v in values) {
        if (v.name == raw) return v;
      }
    }
    throw FormatException('unknown permission: $raw');
  }
}
