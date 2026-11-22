/// What one generated fixture file must give back (see
/// `tool/make_fixtures.sh`; keep both in step).
class FixtureTrack {
  const FixtureTrack({
    required this.title,
    required this.tag,
    required this.lrc,
  });

  /// The tag title, which is what the library lists.
  final String title;

  /// Expected tag lyrics, or null when the file has none.
  final ExpectedLyrics? tag;

  /// Expected `.lrc` sidecar lyrics, or null when there is none.
  final ExpectedLyrics? lrc;
}

/// The first line of a lyrics result and whether it is synced.
class ExpectedLyrics {
  const ExpectedLyrics({
    required this.synced,
    required this.firstText,
    required this.firstTime,
    this.secondText,
  });

  final bool synced;
  final String firstText;
  final Duration firstTime;
  final String? secondText;
}

const _syncedAt500 = Duration(milliseconds: 500);

/// Every fixture track, by tag title.
const List<FixtureTrack> fixtureTracks = [
  FixtureTrack(
    title: 'IT Sylt Tag',
    tag: ExpectedLyrics(
      synced: true,
      firstText: 'Sylt first line',
      firstTime: _syncedAt500,
      secondText: 'Sylt second line',
    ),
    lrc: null,
  ),
  FixtureTrack(
    title: 'IT Uslt Tag',
    tag: ExpectedLyrics(
      synced: false,
      firstText: 'Uslt first line',
      firstTime: Duration.zero,
      secondText: 'Uslt second line',
    ),
    lrc: null,
  ),
  FixtureTrack(
    title: 'IT Flac Lrc Tag',
    tag: ExpectedLyrics(
      synced: true,
      firstText: 'Flac first line',
      firstTime: _syncedAt500,
      secondText: 'Flac second line',
    ),
    lrc: null,
  ),
  FixtureTrack(
    title: 'IT Flac Unsynced Space',
    tag: ExpectedLyrics(
      synced: false,
      firstText: 'Unsynced first line',
      firstTime: Duration.zero,
      secondText: 'Unsynced second line',
    ),
    lrc: null,
  ),
  FixtureTrack(
    title: 'IT Ogg Plain Tag',
    tag: ExpectedLyrics(
      synced: false,
      firstText: 'Ogg first line',
      firstTime: Duration.zero,
      secondText: 'Ogg second line',
    ),
    lrc: null,
  ),
  FixtureTrack(
    title: 'IT Lrc Utf8',
    tag: null,
    lrc: ExpectedLyrics(
      synced: true,
      firstText: 'Utf8 first line',
      firstTime: _syncedAt500,
      secondText: 'Utf8 second line - déjà vu',
    ),
  ),
  FixtureTrack(
    title: 'IT Lrc Utf16',
    tag: null,
    lrc: ExpectedLyrics(
      synced: true,
      firstText: 'Utf16 first line',
      firstTime: _syncedAt500,
      secondText: 'Utf16 second line',
    ),
  ),
  FixtureTrack(
    title: 'IT Lrc Upper',
    tag: null,
    lrc: ExpectedLyrics(
      synced: true,
      firstText: 'Upper first line',
      firstTime: _syncedAt500,
      secondText: 'Upper second line',
    ),
  ),
  FixtureTrack(title: 'IT No Lyrics', tag: null, lrc: null),
];
