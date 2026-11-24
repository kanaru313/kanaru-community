/// Version of the tag pass written to `tracks.tags_version`. Bump it when the
/// mapping from tags to columns changes in a way old rows should pick up:
/// every present row below it is read again by the next scan.
///
/// 2: `extra_tags` (release date, description) is read from the file.
const int tagsPassVersion = 2;

/// Version of the cover pass written to `tracks.cover_scan_version`. Bump it
/// when the cover rules change (sources, sizes, key): every present row below
/// it is visited again by the next cover pass.
const int coverPassVersion = 1;
