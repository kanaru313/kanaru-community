import '../permission.dart';

/// A chat with an AI plugin.
class AiConversation {
  const AiConversation({
    required this.id,
    required this.title,
    required this.titleAuto,
    required this.permission,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessageAt,
    this.installId,
    this.installGeneration,
    this.model,
  });

  final int id;
  final String title;

  /// True while the app made the title and may replace it; false once the
  /// user renamed the chat.
  final bool titleAuto;

  /// The plugin the chat is bound to, and the `installed_at` of that plugin
  /// row at bind time: a removed and reinstalled plugin has another
  /// generation.
  final String? installId;
  final int? installGeneration;
  final String? model;
  final AiPermission permission;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastMessageAt;
}
