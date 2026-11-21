import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/state/track_lyrics_providers.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

import 'support/fixtures.dart';
import 'support/harness.dart';

/// The lyrics readers of PR A on real files: Rust tag read (ID3 SYLT / USLT,
/// FLAC and Ogg comments) and `.lrc` sidecars (UTF-8, UTF-16, `.LRC`), through
/// the same providers the app uses.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('every fixture track gives the expected lyrics', (tester) async {
    final app = await startKanaru(tester);
    final ids = await app.trackIdsByTitle();
    final failures = <String>[];

    for (final fixture in fixtureTracks) {
      final id = TrackId(ids[fixture.title]!);
      // Listened, so the auto-dispose read is not cancelled while awaited.
      final readSub = app.container.listen(
        localLyricsReadProvider(id),
        (_, _) {},
      );
      final read = await app.container.read(localLyricsReadProvider(id).future);
      readSub.close();
      failures
        ..addAll(
          _check(
            '${fixture.title} tag',
            read.tag,
            fixture.tag,
            LyricsOrigin.tag,
          ),
        )
        ..addAll(
          _check(
            '${fixture.title} lrc',
            read.lrc,
            fixture.lrc,
            LyricsOrigin.lrc,
          ),
        );
      if (read.incomplete) failures.add('${fixture.title}: read is incomplete');

      // The selection the Now Playing page would show.
      final sub = app.container.listen(trackLyricsProvider(id), (_, _) {});
      await app.pumpUntil(
        () => sub.read() is! LyricsLoading,
        what: 'lyrics state of "${fixture.title}"',
      );
      final shown = sub.read();
      final hasAny = fixture.tag != null || fixture.lrc != null;
      if (hasAny != (shown is LyricsShown)) {
        failures.add(
          '${fixture.title}: selection is $shown, expected '
          '${hasAny ? 'lyrics' : 'none'}',
        );
      }
      sub.close();
    }

    expect(failures, isEmpty, reason: failures.join('\n'));
  }, timeout: const Timeout(Duration(minutes: 4)));
}

/// Mismatches between [actual] and [expected] (null = no lyrics).
List<String> _check(
  String label,
  Lyrics? actual,
  ExpectedLyrics? expected,
  LyricsOrigin origin,
) {
  if (expected == null) {
    return actual == null ? const [] : ['$label: expected none, got $actual'];
  }
  if (actual == null) return ['$label: expected lyrics, got none'];
  final problems = <String>[];
  if (actual.origin != origin) problems.add('$label: origin ${actual.origin}');
  if (actual.synced != expected.synced) {
    problems.add(
      '$label: synced ${actual.synced}, expected ${expected.synced}',
    );
  }
  final first = actual.lines.first;
  if (first.text != expected.firstText) {
    problems.add('$label: first line "${first.text}"');
  }
  if (first.time != expected.firstTime) {
    problems.add('$label: first time ${first.time}');
  }
  final second = expected.secondText;
  if (second != null &&
      (actual.lines.length < 2 || actual.lines[1].text != second)) {
    problems.add('$label: second line is not "$second"');
  }
  return problems;
}
