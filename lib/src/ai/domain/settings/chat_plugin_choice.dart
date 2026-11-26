/// The plugin a new conversation uses: [stored] (the last one used) when it
/// is still installed, else the first of [installedIds] (install order), else
/// null when no chat plugin is installed.
String? resolveChatPlugin({
  required String? stored,
  required List<String> installedIds,
}) {
  if (stored != null && installedIds.contains(stored)) return stored;
  return installedIds.isEmpty ? null : installedIds.first;
}
