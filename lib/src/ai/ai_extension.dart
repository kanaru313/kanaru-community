import '../extension/kanaru_extension.dart';
import '../extension/state/extension_registry.dart';
import 'state/chat_flush.dart';

/// The AI module's entries in the app's extension points: today the flush
/// hook that writes the text streamed so far when the app pauses or exits.
/// The chat UI plan adds its routes and nav entry here and registers the
/// extension in the built-in list.
class AiExtension implements KanaruExtension {
  const AiExtension();

  @override
  String get id => 'ai';

  @override
  void register(ExtensionRegistry registry) {
    registry.addFlushHook(flushChat);
  }
}
