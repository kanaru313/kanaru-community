import 'package:flutter/widgets.dart';

/// Key of the history area, which replaces the conversation while the
/// history flag of `chatViewProvider` is set.
const ValueKey<String> chatHistorySlotKey = ValueKey('chat history slot');

/// Where the history list is drawn. Empty until the history page is built.
class ChatHistorySlot extends StatelessWidget {
  const ChatHistorySlot({super.key = chatHistorySlotKey});

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
