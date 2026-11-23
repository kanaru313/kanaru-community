/// The one INFO line of the app log for a failed plugin run: plugin name, id,
/// script, failure kind, and the host (only) of a blocked address. No song
/// data, path, console line or stack.
String failureLogLine({
  required String pluginName,
  required String installId,
  required String script,
  required String kind,
  String? blockedHost,
}) {
  final name = pluginName.replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), ' ');
  final host = blockedHost == null ? '' : ' host=$blockedHost';
  return 'Plugin "$name" ($installId) $script failed: $kind$host';
}
