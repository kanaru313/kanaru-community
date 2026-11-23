import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/info/song_details.dart';
import '../browse/library_labels.dart';
import '../library_locations.dart';
import 'song_info_formats.dart';
import 'song_info_row_helpers.dart';
import 'song_info_spec.dart';

/// Rows of the Tags group.
List<InfoRowSpec> tagRows(AppLocalizations l10n, SongDetails d, DateTime now) {
  final year =
      d.releaseDate != null && (d.year == null || d.releaseDate!.year == d.year)
      ? d.releaseDate!.year
      : d.year;
  final date = d.releaseDate != null && year == d.releaseDate!.year
      ? formatReleaseDate(d.releaseDate!)
      : (d.year == null ? null : '${d.year}');
  final age = year == null ? null : now.year - year;
  final released = date == null
      ? textRow(InfoRowId.released, l10n.libraryInfoReleased, null)
      : InfoRowSpec(
          InfoRowId.released,
          l10n.libraryInfoReleased,
          value: age == null || age < 0
              ? date
              : l10n.libraryInfoDateWithAge(
                  date,
                  age == 0
                      ? l10n.libraryInfoThisYear
                      : l10n.libraryInfoYearsAgo(age),
                ),
          copyText: date,
        );
  final albumArtist = infoText(d.albumArtistDisplay ?? d.albumArtist);
  final languageCode = infoText(d.language);
  final languageName = languageCode == null
      ? null
      : languageDisplayName(l10n, languageCode);
  final genre = infoText(d.genre);
  final album = infoText(d.album);
  return [
    textRow(InfoRowId.title, l10n.libraryInfoTitle, d.title),
    linksRow(InfoRowId.artists, l10n.libraryInfoArtist, [
      for (final a in d.artists)
        InfoLink(
          a.name,
          LibraryLocations.artist(a.key),
          l10n.libraryInfoGoArtist(a.name),
        ),
    ]),
    linksRow(InfoRowId.album, l10n.libraryInfoAlbum, [
      if (album != null && d.albumKey != null)
        InfoLink(
          album,
          LibraryLocations.album(d.albumKey!),
          l10n.libraryInfoGoAlbum(album),
        ),
    ]),
    linksRow(InfoRowId.albumArtist, l10n.libraryInfoAlbumArtist, [
      if (albumArtist != null && d.albumArtistKey != null)
        InfoLink(
          albumArtist,
          LibraryLocations.artist(d.albumArtistKey!),
          l10n.libraryInfoGoArtist(albumArtist),
        ),
    ]),
    linksRow(InfoRowId.genre, l10n.libraryInfoGenre, [
      if (genre != null && d.genreKey != null)
        InfoLink(
          genre,
          LibraryLocations.genre(d.genreKey!),
          l10n.libraryInfoGoGenre(genre),
        ),
    ]),
    textRow(InfoRowId.composer, l10n.libraryInfoComposer, d.composer),
    released,
    textRow(
      InfoRowId.trackNo,
      l10n.libraryInfoTrackNo,
      _ofTotal(d.trackNo, d.trackTotal),
    ),
    textRow(
      InfoRowId.disc,
      l10n.libraryInfoDisc,
      _ofTotal(d.discNo, d.discTotal),
    ),
    linksRow(InfoRowId.language, l10n.libraryInfoLanguage, [
      if (languageCode != null && languageName != null)
        InfoLink(
          languageName,
          LibraryLocations.language(languageCode),
          l10n.libraryInfoGoLanguage(languageName),
        ),
    ], badge: d.languageDetected ? l10n.libraryInfoAutoDetected : null),
    textRow(InfoRowId.comment, l10n.libraryInfoComment, d.comment),
    // A missing description is not a gap to show: it is left out.
    if (infoText(d.description) != null)
      textRow(
        InfoRowId.description,
        l10n.libraryInfoDescription,
        d.description,
      ),
  ];
}

String? _ofTotal(int? n, int? total) {
  if (n == null || n <= 0) return null;
  return total == null || total <= 0 ? '$n' : '$n/$total';
}
