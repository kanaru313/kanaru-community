import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/state/track_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_body.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_for_track_body.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../lyrics_ui_host.dart';
import '../picker/picker_harness.dart' show pickerOverrides;
import 'modal_harness.dart' show RecordingOnlineCommands;
import 'online_ui_overrides.dart';
import '../lyrics_spinner_finders.dart';

const _body = LyricsBody(surface: KLyricsSurface.screen);

Finder _button(String label) => find.ancestor(
  of: find.text(label),
  matching: find.bySubtype<ButtonStyleButton>(),
);

LyricsUiHost _host(TrackLyrics lyrics) => LyricsUiHost(
  lyrics: lyrics,
  extra: [
    ...onlineUiOverrides(sources: [lyricsSource('netease')]),
    // The picker and the modal the buttons open read the track's own state.
    trackLyricsProvider.overrideWith((ref, id) => lyrics),
    ...pickerOverrides(online: RecordingOnlineCommands()),
  ],
);

void main() {
  testWidgets('searching is no longer blank: it says what it does', (
    tester,
  ) async {
    await _host(const LyricsSearching(2)).pump(tester, _body);
    expect(find.text('Searching for lyrics…'), findsOneWidget);
    expect(byLyricsSpinner(), findsOneWidget);
  });

  testWidgets('"Find lyrics online…" opens the picker of the playing '
      'track', (tester) async {
    await _host(const LyricsNotFound(asked: 2, off: 0)).pump(tester, _body);
    await tester.tap(_button('Find lyrics online…'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Choose lyrics'), findsOneWidget);
    expect(find.byType(LyricsForTrackBody), findsNothing);
  });

  testWidgets('"Search manually…" opens it too', (tester) async {
    await _host(const LyricsNone()).pump(tester, _body);
    await tester.tap(_button('Search manually…'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Choose lyrics'), findsOneWidget);
  });

  testWidgets('failed and paused keep the find button', (tester) async {
    await _host(LyricsLookupPaused(DateTime(2030, 1, 1, 21, 5)))
        .pump(tester, _body);
    expect(_button('Find lyrics online…'), findsOneWidget);
  });

  testWidgets('online lyrics render like local ones', (tester) async {
    await _host(LyricsShown(onlineLyrics(synced: false))).pump(tester, _body);
    expect(find.text('La la'), findsOneWidget);
    expect(find.byType(ButtonStyleButton), findsNothing);
  });
}
