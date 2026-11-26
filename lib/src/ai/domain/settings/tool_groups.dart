/// The privacy groups of the assistant's tools. The user turns each group on
/// or off in Settings; a tool of a group that is off is not offered to the
/// model and is refused if called.
///
/// Reads come first, then writes. [settingKey] is the suffix of
/// `ai.tools.<suffix>`.
enum AiToolGroup {
  // Reads.
  nowPlaying('now_playing', isWrite: false),
  queue('queue', isWrite: false),
  librarySearch('library_search', isWrite: false),
  lyrics('lyrics', isWrite: false),
  trackInfo('track_info', isWrite: false),
  listeningStats('listening_stats', isWrite: false),
  playlists('playlists', isWrite: false),
  // Writes.
  playControl('play_control', isWrite: true),
  queueEdit('queue_edit', isWrite: true),
  playlistCreate('playlist_create', isWrite: true),
  playlistEdit('playlist_edit', isWrite: true);

  const AiToolGroup(this.settingKey, {required this.isWrite});

  final String settingKey;

  /// Whether the tools of this group change something.
  final bool isWrite;

  /// The full settings key (`ai.tools.now_playing`).
  String get fullKey => 'ai.tools.$settingKey';
}
