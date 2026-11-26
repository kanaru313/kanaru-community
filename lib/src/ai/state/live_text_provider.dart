import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_session.dart';

/// The text streamed so far into assistant message [messageId], or null when
/// nothing streams into it. Only the one bubble that shows it rebuilds per
/// delta; the message list does not.
class LiveTextNotifier extends Notifier<String?> {
  LiveTextNotifier(this.messageId);

  final int messageId;

  @override
  String? build() {
    final session = ref.watch(chatSessionProvider.notifier);
    final sub = session.liveText
        .where((e) => e.messageId == messageId)
        .listen((e) => state = e.text);
    ref.onDispose(() => unawaited(sub.cancel()));
    return session.liveTextOf(messageId);
  }
}

final liveTextProvider = NotifierProvider.autoDispose
    .family<LiveTextNotifier, String?, int>(LiveTextNotifier.new);
