/// The codes a chat plugin reports in `Response.error("ai:<code>")`
/// (chat contract, Errors table). The plugin never puts provider text in the
/// message; anything after the code is dropped here anyway.
enum AiErrorCode {
  key('key'),
  quota('quota'),
  rateLimit('rate_limit'),
  config('config'),
  badRequest('bad_request'),
  modelNotFound('model_not_found'),
  contextLength('context_length'),
  tooLarge('too_large'),
  blocked('blocked'),
  empty('empty'),
  server('server');

  const AiErrorCode(this.wire);

  /// The text after `ai:`.
  final String wire;

  /// The code of a script error [message] (`ai:<code>` plus anything). A
  /// message without the prefix, an unknown code (`no_key` included, which is
  /// never a plugin code) and a missing message are [server].
  static AiErrorCode parse(String? message) {
    if (message == null) return server;
    final m = RegExp(r'^ai:([a-z_]+)').firstMatch(message);
    if (m == null) return server;
    for (final code in values) {
      if (code.wire == m.group(1)) return code;
    }
    return server;
  }
}

/// Codes the app itself stores with a failed message, next to the contract
/// codes of [AiErrorCode] (the stored data stays `{code, kind,
/// retryAfterSec?}`; no host, no provider text). They exist so a card that the
/// contract code cannot tell apart is rebuilt the same after a reload:
///
/// - `network`: the request never got an answer (stored kind `server`).
/// - `host_not_allowed`: the host is blocked or not consented to.
/// - `limit_reached`: the turn hit its item or call limit.
///
/// Every other card is stored under the snake-case name of its kind
/// (`timeout`, `plugin_error`, ...). A plugin can never produce these codes:
/// `AiErrorCode.parse` only knows the contract.
const appErrorCodes = {'network', 'host_not_allowed', 'limit_reached'};
