import 'package:kanaru/src/library/domain/browse/menu_targets.dart';
import 'package:kanaru/src/library/domain/info/release_date.dart';
import 'package:kanaru/src/library/domain/info/song_details.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

const _folder = FolderRef(
  sourceId: 1,
  sourceUid: 'uid-1',
  folderKey: 'Blue',
  name: 'Blue',
  songCount: 0,
);

/// A fully tagged FLAC; every argument overrides one field. Null arguments
/// cannot clear a field: build a bare song with [bareDetails].
SongDetails fullDetails({
  int id = 7,
  String title = 'Ngày chưa giông bão',
  SongFileStatus status = SongFileStatus.present,
  int? missingSince,
  String? scanError,
  String? codec = 'FLAC',
  String? format = 'FLAC',
  ReleaseDate? releaseDate = const ReleaseDate(year: 2018, month: 3),
  int? year = 2018,
  int playCount = 19,
  int skipCount = 2,
  String? path = '/home/u/Music/Blue/01 - Song.flac',
  bool languageDetected = true,
}) => SongDetails(
  id: TrackId(id),
  title: title,
  status: status,
  addedAt: DateTime(2026, 11, 9, 10, 2).millisecondsSinceEpoch,
  folder: _folder,
  artists: [
    ArtistRef(ArtistKey('bui'), 'Bùi Lan Hương'),
    ArtistRef(ArtistKey('phan'), 'Phan Mạnh Quỳnh'),
  ],
  album: 'Người bất tử OST',
  albumKey: AlbumKey('bui', 'nguoi bat tu ost'),
  albumArtist: 'Bùi Lan Hương',
  albumArtistKey: ArtistKey('bui'),
  albumArtistDisplay: 'Bùi Lan Hương',
  genre: 'Ballad',
  genreKey: 'ballad',
  composer: 'Phan Mạnh Quỳnh',
  year: year,
  releaseDate: releaseDate,
  trackNo: 1,
  trackTotal: 12,
  discNo: 1,
  discTotal: 2,
  language: 'vi',
  languageDetected: languageDetected,
  comment: 'Nhạc phim Người bất tử',
  description: 'Bài hát chủ đề phim',
  durationMs: 310000,
  codec: codec,
  format: format,
  bitrate: 2304,
  sampleRate: 96000,
  bitDepth: 24,
  channels: 2,
  path: path,
  sourceName: 'Music',
  sourceRoot: '/home/u/Music',
  sizeBytes: 91447000,
  mtimeMs: DateTime(2025, 6, 8, 21, 14).millisecondsSinceEpoch,
  missingSince: missingSince,
  scanError: scanError,
  playCount: playCount,
  skipCount: skipCount,
  firstPlayedAt: DateTime(2026, 11, 9, 22, 40).millisecondsSinceEpoch,
  lastPlayedAt: DateTime(2026, 11, 13, 23, 5).millisecondsSinceEpoch,
);

/// A file with no tags but a title (the file name) and the facts every file
/// has.
SongDetails bareDetails({
  int id = 8,
  String title = 'track07',
  String? path = '/home/u/Music/track07.mp3',
  String? scanError,
}) => SongDetails(
  id: TrackId(id),
  title: title,
  status: SongFileStatus.present,
  addedAt: DateTime(2026, 11, 9, 10, 2).millisecondsSinceEpoch,
  folder: _folder,
  format: 'MP3',
  path: path,
  scanError: scanError,
);
