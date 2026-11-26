/// Longest label of a prompt template, in characters (code points).
const int promptLabelMaxChars = 40;

/// Longest body of a prompt template, in characters (code points).
const int promptBodyMaxChars = 2000;

/// Longest custom instruction text, in characters (code points).
const int instructionsMaxChars = 2000;

int _chars(String s) => s.runes.length;

/// A saved prompt the user can send with one tap.
///
/// - A **builtin** has a [key]. Its label and body are display strings of the
///   settings part's l10n (stored as keys only), so [label] and [body] stay
///   null until the user edits it ([edited]).
/// - A **custom** template has no [key] and always has a label and a body.
/// - An **unknown** item is one a stored list held that this app version
///   could not read; [raw] keeps it so a later version (or a repair) still
///   sees it.
class PromptTemplate {
  const PromptTemplate({
    this.key,
    this.label,
    this.body,
    this.enabled = true,
    this.edited = false,
  }) : raw = null;

  /// An item of a stored list that could not be read.
  const PromptTemplate.unknown(Object this.raw)
    : key = null,
      label = null,
      body = null,
      enabled = true,
      edited = false;

  final String? key;
  final String? label;
  final String? body;
  final bool enabled;
  final bool edited;
  final Object? raw;

  bool get isUnknown => raw != null;
  bool get isBuiltin => key != null;

  PromptTemplate copyWith({
    String? label,
    String? body,
    bool? enabled,
    bool? edited,
  }) => PromptTemplate(
    key: key,
    label: label ?? this.label,
    body: body ?? this.body,
    enabled: enabled ?? this.enabled,
    edited: edited ?? this.edited,
  );

  /// Throws [ArgumentError] when the template breaks a limit or a rule above.
  void validate() {
    if (isUnknown) return;
    if (key == null && (label == null || body == null)) {
      throw ArgumentError('a custom template needs a label and a body');
    }
    final l = label;
    if (l != null) {
      if (l.trim().isEmpty) throw ArgumentError.value(l, 'label', 'is empty');
      if (_chars(l) > promptLabelMaxChars) {
        throw ArgumentError.value(l, 'label', 'over $promptLabelMaxChars');
      }
    }
    final b = body;
    if (b != null) {
      if (b.trim().isEmpty) throw ArgumentError.value(b, 'body', 'is empty');
      if (_chars(b) > promptBodyMaxChars) {
        throw ArgumentError.value(b, 'body', 'over $promptBodyMaxChars');
      }
    }
  }

  /// The stored JSON. Throws [ArgumentError] when [validate] fails.
  Object? toJson() {
    if (isUnknown) return raw;
    validate();
    return {
      if (key != null) 'key': key,
      if (label != null) 'label': label,
      if (body != null) 'body': body,
      'enabled': enabled,
      'edited': edited,
    };
  }

  /// Throws [FormatException] for anything that is not a valid template.
  factory PromptTemplate.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw FormatException('template is not an object: $json');
    }
    final key = json['key'];
    final label = json['label'];
    final body = json['body'];
    final enabled = json['enabled'] ?? true;
    final edited = json['edited'] ?? false;
    if ((key != null && key is! String) ||
        (label != null && label is! String) ||
        (body != null && body is! String) ||
        enabled is! bool ||
        edited is! bool) {
      throw FormatException('bad template: $json');
    }
    final t = PromptTemplate(
      key: key as String?,
      label: label as String?,
      body: body as String?,
      enabled: enabled,
      edited: edited,
    );
    try {
      t.validate();
    } on ArgumentError catch (e) {
      throw FormatException('bad template: ${e.message}');
    }
    return t;
  }

  @override
  bool operator ==(Object other) =>
      other is PromptTemplate &&
      other.key == key &&
      other.label == label &&
      other.body == body &&
      other.enabled == enabled &&
      other.edited == edited &&
      other.raw == raw;

  @override
  int get hashCode => Object.hash(key, label, body, enabled, edited, raw);

  @override
  String toString() => 'PromptTemplate($key, $label, enabled: $enabled)';
}
