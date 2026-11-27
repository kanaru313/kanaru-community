import 'package:flutter/widgets.dart' show BuildContext;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/ask_ai_target.dart';

/// The "Ask AI" entry of menus and screens. `library` cannot import the AI
/// module, so the menus own this interface and the app (above both) supplies
/// the implementation through [askAiEntryProvider].
abstract interface class AskAiEntry {
  /// Attaches the chip of [target] to the chat's composer and opens the chat
  /// (a page on mobile, the right panel on desktop) with the composer focused.
  Future<void> ask(BuildContext context, AskAiTarget target);
}

/// The "Ask AI" entry; null (the rows are "coming soon") until the app
/// overrides it.
final askAiEntryProvider = Provider<AskAiEntry?>((_) => null);
