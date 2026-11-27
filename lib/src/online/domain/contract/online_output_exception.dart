/// A streaming script's output broke the contract. [reason] is fixed text
/// written by this app, never content from the plugin.
class OnlineOutputException implements Exception {
  const OnlineOutputException(this.reason);

  final String reason;

  @override
  String toString() => 'OnlineOutputException: $reason';
}
