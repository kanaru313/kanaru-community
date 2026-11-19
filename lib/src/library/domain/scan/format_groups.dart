/// A set of file extensions the user switches on or off together.
class FormatGroup {
  const FormatGroup(this.id, this.extensions);

  /// Stable string stored in `library.format_groups`; never rename one.
  final String id;

  /// Lower-case extensions without the dot.
  final Set<String> extensions;
}

/// The scan format groups, in the order the settings sheet lists them.
/// Their union is exactly `audioExtensions` (a test enforces it, so a new
/// extension cannot be forgotten here).
const List<FormatGroup> formatGroups = [
  FormatGroup('mp3', {'mp3'}),
  FormatGroup('flac', {'flac'}),
  FormatGroup('m4a', {'m4a', 'aac', 'alac'}),
  FormatGroup('ogg', {'ogg', 'oga', 'opus'}),
  FormatGroup('wav', {'wav'}),
  FormatGroup('aiff', {'aif', 'aiff'}),
  FormatGroup('ape', {'ape'}),
  FormatGroup('wavpack', {'wv'}),
  FormatGroup('dsd', {'dsf', 'dff'}),
];

/// Every group id, in list order.
final List<String> allFormatGroupIds = [for (final g in formatGroups) g.id];

/// The extensions of the groups named in [ids]; unknown ids are ignored.
Set<String> extensionsOfGroups(Iterable<String> ids) {
  final wanted = ids.toSet();
  return {
    for (final g in formatGroups)
      if (wanted.contains(g.id)) ...g.extensions,
  };
}

/// Every extension of every group.
final Set<String> allGroupExtensions = extensionsOfGroups(allFormatGroupIds);

/// Extensions that always hold lossless audio: FLAC, ALAC, WAV, AIFF, APE,
/// WavPack, DSD. `.m4a` is left out on purpose: it holds either AAC or ALAC,
/// so where the codec is known (tags) it decides; the extension alone cannot.
/// Meant for features that sort files by losslessness.
const Set<String> losslessExtensions = {
  'flac', 'alac', 'wav', 'aif', 'aiff', 'ape', 'wv', 'dsf', 'dff', //
};
