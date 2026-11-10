import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/scan/artist_split.dart';

void main() {
  List<String> split(String v) => splitArtists([v]);

  test('splits on ; and / and keeps AC/DC whole', () {
    expect(split('A; B'), ['A', 'B']);
    expect(split('A;B'), ['A', 'B']);
    expect(split('A/B'), ['A', 'B']);
    expect(split('AC/DC'), ['AC/DC']);
    expect(split('ac/dc'), ['ac/dc']);
    expect(split('AC/DC; Queen'), ['AC/DC', 'Queen']);
    expect(split('Queen / AC/DC'), ['Queen', 'AC/DC']);
    expect(split('BAC/DCE'), ['BAC', 'DCE']);
  });

  test('splits on featuring words between whitespace only', () {
    expect(split('A feat. B'), ['A', 'B']);
    expect(split('A FEAT B'), ['A', 'B']);
    expect(split('A ft B'), ['A', 'B']);
    expect(split('A ft. B'), ['A', 'B']);
    expect(split('A featuring B'), ['A', 'B']);
    expect(split('Featherweight'), ['Featherweight']);
    expect(split('Soft Machine'), ['Soft Machine']);
  });

  test('a bracketed featuring part gives its names too', () {
    expect(split('A (feat. B)'), ['A', 'B']);
    expect(split('A [ft. B]'), ['A', 'B']);
    expect(split('A (feat. B); C'), ['A', 'B', 'C']);
  });

  test('never splits on comma, ampersand or with', () {
    expect(split('A & B'), ['A & B']);
    expect(split('A, B'), ['A, B']);
    expect(split('A with B'), ['A with B']);
    expect(split('Earth, Wind & Fire'), ['Earth, Wind & Fire']);
  });

  test('repeated names are deduped by group key, first spelling kept', () {
    expect(splitArtists(['Hà Anh Tuấn', 'hà  anh tuấn']), ['Hà Anh Tuấn']);
    expect(splitArtists(['A; a', 'A feat. B']), ['A', 'B']);
    // Accents are kept: two different artists.
    expect(splitArtists(['Anh; Ánh']), ['Anh', 'Ánh']);
  });

  test('Vietnamese names keep their accents', () {
    expect(split('Đen Vâu feat. Linh Cáo'), ['Đen Vâu', 'Linh Cáo']);
  });

  test('empty parts and control characters are dropped', () {
    expect(split(' ; ;A;; '), ['A']);
    expect(split(''), isEmpty);
    expect(split('   '), isEmpty);
    expect(split('A\u0000B'), ['A B']);
    expect(splitArtists(const []), isEmpty);
  });

  test('artistsForRow pairs each name with its group key', () {
    expect(artistsForRow(['Hà Anh; Hà Anh', ' B ']), [
      (key: 'hà anh', name: 'Hà Anh'),
      (key: 'b', name: 'B'),
    ]);
  });
}
