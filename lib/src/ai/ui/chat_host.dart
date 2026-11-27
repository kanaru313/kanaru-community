import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Path of the phone's chat page.
const String chatPath = '/chat';

/// What the chat needs from the app around it. The shell implements it (the
/// chat never imports `shell/` or `screens/`): on desktop the chat is the
/// shell's right panel, on the phone it is a page on the root navigator.
abstract interface class ChatHost {
  /// The chat is shown in the desktop right panel (else as the phone page).
  bool get isPanel;

  /// Closes the panel, or pops the page.
  void close();

  /// Shows the queue. Desktop swaps the shared right panel to the queue (the
  /// chat keeps its state); the phone opens the queue sheet over the chat.
  void openQueue();

  /// Goes to [location] (a settings page, the plugin store). The phone page
  /// closes first so the destination is not hidden under it.
  void openSettings(String location);
}

/// The app's [ChatHost]; the app overrides it (`lib/kanaru.dart`).
final chatHostProvider = Provider<ChatHost>(
  (ref) => throw StateError('chatHostProvider must be overridden by the app'),
);
