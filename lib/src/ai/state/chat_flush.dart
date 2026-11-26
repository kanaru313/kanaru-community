import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'chat_session.dart';

final _log = Logger('ai.flush');

/// Flush hook: writes the text streamed so far into the open chat's running
/// message. Does nothing when the chat session was never created (a launch
/// that did not open the chat must not build it).
Future<void> flushChat(ProviderContainer container) async {
  if (!container.read(chatSessionProvider.exists)) return;
  try {
    await container.read(chatSessionProvider.notifier).flush();
  } on Object catch (e, s) {
    _log.warning('chat flush failed: ${e.runtimeType}', e, s);
  }
}
