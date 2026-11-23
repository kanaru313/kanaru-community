import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:kanaru/src/lyrics/data/online/store_result.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/state/lyrics_settings.dart';
import 'package:kanaru/src/lyrics/domain/online/lookup_outcome.dart';
import 'package:kanaru/src/lyrics/domain/online/online_lyrics_ref.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/lyrics/state/online/online_commands_provider.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_for_track_body.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_online_bar.dart';
import 'package:kanaru/src/lyrics/ui/online/online_row_info.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../lyrics_ui_host.dart' show syncedLyrics;
import '../picker/picker_harness.dart' show pickerOverrides;
import 'modal_harness.dart';
import 'online_ui_overrides.dart';
import '../lyrics_spinner_finders.dart';

Finder _row(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(SelectionRow));

bool _selected(WidgetTester tester, String title) =>
    isSemantics(isSelected: true).matches(tester.getSemantics(_row(title)), {});

bool _enabled(WidgetTester tester, String title) =>
    isSemantics(isEnabled: true).matches(tester.getSemantics(_row(title)), {});

Finder _button(String label) => find.ancestor(
  of: find.text(label),
  matching: find.bySubtype<ButtonStyleButton>(),
);

final _sources = [
  lyricsSource('netease', name: 'NetEase'),
  lyricsSource('lrclib', name: 'LRCLIB'),
];

void main() {
  for (final (name, size) in [
    ('mobile', const Size(400, 800)),
    ('desktop', const Size(1400, 900)),
  ]) {
    group(name, () {
      group('online row', () {
        testWidgets(
          'auto-found: chosen, described, tagged "found automatically"',
          (tester) async {
            final handle = tester.ensureSemantics();
            await openModal(
              tester,
              LyricsShown(onlineLyrics()),
              overrides: onlineUiOverrides(sources: _sources),
              size: size,
            );
            expect(_selected(tester, 'Online lyrics'), isTrue);
            expect(
              find.text('NetEase · Synced · 4:12 · found automatically'),
              findsOneWidget,
            );
            expect(_selected(tester, 'Lyrics in file'), isFalse);
            expect(_enabled(tester, 'Lyrics in file'), isFalse);
            handle.dispose();
          },
        );

        testWidgets('kept plain copy is described as kept', (tester) async {
          await openModal(
            tester,
            LyricsShown(onlineLyrics(how: OnlineHow.kept, synced: false)),
            overrides: onlineUiOverrides(sources: _sources),
            size: size,
          );
          expect(find.text('NetEase · Plain · 4:12'), findsOneWidget);
        });

        testWidgets('a copy that declared no duration shows none', (
          tester,
        ) async {
          await openModal(
            tester,
            LyricsShown(onlineLyrics(durationMs: null)),
            overrides: onlineUiOverrides(sources: _sources),
            size: size,
          );
          expect(
            find.text('NetEase · Synced · found automatically'),
            findsOneWidget,
          );
        });

        testWidgets('removed plugin: its initial and "plugin removed"', (
          tester,
        ) async {
          await openModal(
            tester,
            LyricsShown(
              onlineLyrics(id: 'zing', name: 'ZingMP3', how: OnlineHow.kept),
            ),
            overrides: onlineUiOverrides(sources: _sources),
            size: size,
          );
          expect(
            find.text('ZingMP3 · plugin removed · Synced · 4:12'),
            findsOneWidget,
          );
          final avatar = tester.widget<KSourceAvatar>(
            find.byType(KSourceAvatar),
          );
          expect(avatar.removed, isTrue);
          expect(avatar.label, 'ZingMP3');
        });

        testWidgets('no online copy: no online row', (tester) async {
          await openModal(
            tester,
            LyricsShown(syncedLyrics(2)),
            overrides: onlineUiOverrides(sources: _sources),
            size: size,
          );
          expect(find.text('Online lyrics'), findsNothing);
        });

        testWidgets('file chosen while a kept copy exists: its row stays', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          await openModal(
            tester,
            LyricsShown(syncedLyrics(2)),
            overrides: onlineUiOverrides(sources: _sources, pin: keptPick()),
            size: size,
          );
          expect(_selected(tester, 'Lyrics in file'), isTrue);
          expect(_selected(tester, 'Online lyrics'), isFalse);
          expect(_enabled(tester, 'Online lyrics'), isTrue);
          expect(find.text('NetEase · Synced'), findsOneWidget);
          handle.dispose();
        });

        testWidgets('instrumental: the row says so', (tester) async {
          final handle = tester.ensureSemantics();
          await openModal(
            tester,
            const LyricsInstrumental(
              OnlineLyricsRef(
                providerId: 'lrclib',
                providerName: 'LRCLIB',
                remoteId: 'r',
                how: OnlineHow.auto,
              ),
            ),
            overrides: onlineUiOverrides(sources: _sources),
            size: size,
          );
          expect(_selected(tester, 'Online lyrics'), isTrue);
          expect(
            find.text('LRCLIB · Instrumental · found automatically'),
            findsOneWidget,
          );
          handle.dispose();
        });

        testWidgets('off: the online copy is offered, not chosen', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          await openModal(
            tester,
            LyricsOff(onlineLyrics(how: OnlineHow.kept)),
            overrides: onlineUiOverrides(sources: _sources),
            size: size,
          );
          expect(_selected(tester, 'Don’t show lyrics'), isTrue);
          expect(_selected(tester, 'Online lyrics'), isFalse);
          handle.dispose();
        });

        testWidgets('choosing it writes automatic selection and closes', (
          tester,
        ) async {
          final m = await openModal(
            tester,
            LyricsOff(onlineLyrics(how: OnlineHow.kept)),
            overrides: onlineUiOverrides(sources: _sources),
            size: size,
          );
          await tester.tap(find.text('Online lyrics'));
          await tester.pumpAndSettle();
          expect(m.choices.calls, ['clear:1']);
          expect(find.byType(LyricsForTrackBody), findsNothing);
        });

        testWidgets('choosing the file beside a kept copy keeps the copy', (
          tester,
        ) async {
          final m = await openModal(
            tester,
            LyricsOff(syncedLyrics(2)),
            overrides: onlineUiOverrides(sources: _sources, pin: keptPick()),
            size: size,
          );
          await tester.tap(find.text('Lyrics in file'));
          await tester.pumpAndSettle();
          expect(m.choices.calls, ['file:1']);
        });
      });

      group('status line', () {
        Future<void> pump(WidgetTester tester, LyricsStatusCase c) async {
          await openModal(
            tester,
            c.lyrics,
            overrides: onlineUiOverrides(sources: _sources),
            size: size,
          );
          expect(find.text(c.text), findsOneWidget, reason: c.text);
        }

        for (final c in _statusCases) {
          testWidgets(c.name, (tester) => pump(tester, c));
        }

        testWidgets('a running search shows a spinner, not an icon', (
          tester,
        ) async {
          await openModal(
            tester,
            const LyricsSearching(2),
            overrides: onlineUiOverrides(sources: _sources),
            size: size,
          );
          expect(byLyricsSpinner(), findsOneWidget);
        });

        testWidgets('no status line for lyrics that show', (tester) async {
          await openModal(
            tester,
            LyricsShown(onlineLyrics()),
            overrides: onlineUiOverrides(sources: _sources),
            size: size,
          );
          expect(find.textContaining('No lyrics on this device'), findsNothing);
          expect(find.textContaining('Couldn’t find'), findsNothing);
        });
      });

      group('bottom bar', () {
        testWidgets('auto-found: keep and "wrong song" are offered', (
          tester,
        ) async {
          await openModal(
            tester,
            LyricsShown(onlineLyrics(name: 'LRCLIB', id: 'lrclib')),
            overrides: onlineUiOverrides(sources: _sources),
            size: size,
          );
          expect(find.text('Found automatically on LRCLIB'), findsOneWidget);
          expect(
            find.text('Keep it so Kanaru does not search again'),
            findsOneWidget,
          );
          expect(_button('Wrong song'), findsOneWidget);
          expect(_button('Keep this copy'), findsOneWidget);
        });

        testWidgets('kept copy shown: only "wrong song"', (tester) async {
          await openModal(
            tester,
            LyricsShown(onlineLyrics(how: OnlineHow.kept)),
            overrides: onlineUiOverrides(sources: _sources),
            size: size,
          );
          expect(find.text('Using the kept copy'), findsOneWidget);
          expect(_button('Wrong song'), findsOneWidget);
          expect(_button('Keep this copy'), findsNothing);
        });

        for (final (name, lyrics) in <(String, TrackLyrics)>[
          ('file lyrics', LyricsShown(syncedLyrics(2))),
          ('searching', const LyricsSearching(1)),
          ('none', const LyricsNone()),
          ('off', LyricsOff(onlineLyrics(how: OnlineHow.kept))),
        ]) {
          testWidgets('no bar for $name', (tester) async {
            await openModal(
              tester,
              lyrics,
              overrides: onlineUiOverrides(sources: _sources),
              size: size,
            );
            expect(_button('Wrong song'), findsNothing);
            expect(_button('Keep this copy'), findsNothing);
          });
        }

        testWidgets('"Keep this copy" closes once and keeps the found copy', (
          tester,
        ) async {
          final m = await openModal(
            tester,
            LyricsShown(onlineLyrics()),
            overrides: onlineUiOverrides(sources: _sources),
            size: size,
          );
          await tester.tap(_button('Keep this copy'));
          await tester.pumpAndSettle();
          expect(m.online.calls, ['keepAuto:1']);
          expect(find.byType(LyricsForTrackBody), findsNothing);
          expect(
            find.text('Kept the NetEase copy for this song'),
            findsOneWidget,
          );
        });

        testWidgets(
          '"Wrong song" on an automatic copy says it searches again',
          (tester) async {
            final m = await openModal(
              tester,
              LyricsShown(onlineLyrics()),
              overrides: onlineUiOverrides(sources: _sources),
              size: size,
            );
            await tester.tap(_button('Wrong song'));
            await tester.pumpAndSettle();
            expect(m.online.calls, ['reject:1']);
            expect(
              find.text('Dropped this copy, searching again…'),
              findsOneWidget,
            );
          },
        );

        testWidgets('a refused write shows no success toast', (tester) async {
          final m = await openModal(
            tester,
            LyricsShown(onlineLyrics()),
            overrides: onlineUiOverrides(sources: _sources),
            size: size,
          );
          m.online.keepResult = StoreResult.notStored;
          await tester.tap(_button('Keep this copy'));
          await tester.pumpAndSettle();
          expect(find.textContaining('Kept the'), findsNothing);
          expect(
            find.text("Couldn't save the lyrics. Try again."),
            findsOneWidget,
          );
        });

        testWidgets('"Wrong song" refuses the copy and closes', (tester) async {
          final m = await openModal(
            tester,
            LyricsShown(onlineLyrics(how: OnlineHow.kept)),
            overrides: onlineUiOverrides(sources: _sources),
            size: size,
          );
          await tester.tap(_button('Wrong song'));
          await tester.pumpAndSettle();
          expect(m.online.calls, ['reject:1']);
          expect(find.byType(LyricsForTrackBody), findsNothing);
          expect(find.text('Dropped the kept copy'), findsOneWidget);
        });

        testWidgets('a failed write is absorbed: the modal still closes', (
          tester,
        ) async {
          final m = await openModal(
            tester,
            LyricsShown(onlineLyrics()),
            overrides: onlineUiOverrides(sources: _sources),
            size: size,
          );
          m.online.error = StateError('database is gone');
          await tester.tap(_button('Keep this copy'));
          await tester.pumpAndSettle();
          expect(m.online.calls, ['keepAuto:1']);
          expect(find.byType(LyricsForTrackBody), findsNothing);
          expect(tester.takeException(), isNull);
        });

        for (final (button, call, how) in [
          ('Keep this copy', 'keepAuto:1', OnlineHow.auto),
          ('Wrong song', 'reject:1', OnlineHow.kept),
        ]) {
          testWidgets('"$button" throwing is logged, the modal still closes', (
            tester,
          ) async {
            final records = <LogRecord>[];
            Logger.root.level = Level.ALL;
            final sub = Logger.root.onRecord.listen(records.add);
            addTearDown(sub.cancel);
            final m = await openModal(
              tester,
              LyricsShown(onlineLyrics(how: how)),
              overrides: onlineUiOverrides(sources: _sources),
              size: size,
            );
            m.online.error = StateError('database is gone');
            await tester.tap(_button(button));
            await tester.pumpAndSettle();
            expect(m.online.calls, [call]);
            expect(find.byType(LyricsForTrackBody), findsNothing);
            expect(tester.takeException(), isNull);
            expect(
              find.text("Couldn't save the lyrics. Try again."),
              findsOneWidget,
            );
            expect(
              records.where(
                (r) =>
                    r.loggerName == 'lyrics_online_bar' &&
                    r.level >= Level.WARNING &&
                    r.error is StateError,
              ),
              hasLength(1),
            );
          });
        }

        testWidgets('a copy that could not be stored is absorbed too', (
          tester,
        ) async {
          final m = await openModal(
            tester,
            LyricsShown(onlineLyrics()),
            overrides: onlineUiOverrides(sources: _sources),
            size: size,
          );
          m.online.keepResult = StoreResult.notStored;
          await tester.tap(_button('Keep this copy'));
          await tester.pumpAndSettle();
          expect(find.byType(LyricsForTrackBody), findsNothing);
          expect(
            find.text("Couldn't save the lyrics. Try again."),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        });

        testWidgets('a double tap writes once', (tester) async {
          final m = await openModal(
            tester,
            LyricsShown(onlineLyrics()),
            overrides: onlineUiOverrides(sources: _sources),
            size: size,
          );
          final keep = _button('Keep this copy');
          await tester.tap(keep);
          await tester.tap(keep, warnIfMissed: false);
          await tester.pumpAndSettle();
          expect(m.online.calls, hasLength(1));
        });
      });

      group('search row', () {
        testWidgets('counts the sources that are on and off', (tester) async {
          await openModal(
            tester,
            const LyricsNone(),
            overrides: onlineUiOverrides(
              sources: [
                lyricsSource('a'),
                lyricsSource('b'),
                lyricsSource('c', enabled: false),
                lyricsSource('d', enabled: false),
              ],
            ),
            size: size,
          );
          expect(find.text('Find lyrics online…'), findsOneWidget);
          expect(find.text('2 on · 2 off'), findsOneWidget);
        });

        testWidgets('every source off says it searches only on request', (
          tester,
        ) async {
          await openModal(
            tester,
            const LyricsNotFound(asked: 0, off: 2),
            overrides: onlineUiOverrides(
              sources: [
                lyricsSource('a', enabled: false),
                lyricsSource('b', enabled: false),
              ],
            ),
            size: size,
          );
          expect(
            find.text('Every source is off (2) · searches only when you tap'),
            findsOneWidget,
          );
        });

        testWidgets('no lyrics plugin: "Add an online lyrics source" opens '
            'the lyrics plugin store', (tester) async {
          final m = await openModal(
            tester,
            const LyricsNoSource(),
            overrides: onlineUiOverrides(),
            size: size,
          );
          expect(find.text('Find lyrics online…'), findsNothing);
          expect(
            find.text('No lyrics plugin installed · open the plugin store'),
            findsOneWidget,
          );
          await tester.tap(find.text('Add an online lyrics source'));
          await tester.pumpAndSettle();
          expect(find.byType(LyricsForTrackBody), findsNothing);
          expect(m.location, '/settings/plugins');
          expect(find.text('store lyrics'), findsOneWidget);
        });

        testWidgets('the search row opens the picker and ← comes back', (
          tester,
        ) async {
          final m = await openModal(
            tester,
            const LyricsNone(),
            overrides: [
              ...onlineUiOverrides(sources: _sources),
              ...pickerOverrides(),
            ],
            size: size,
          );
          expect(find.text('Coming soon'), findsNWidgets(2));
          await tester.tap(find.text('Find lyrics online…'));
          await tester.pumpAndSettle(const Duration(milliseconds: 100));
          expect(find.byType(LyricsForTrackBody), findsNothing);
          expect(find.text('Choose lyrics'), findsOneWidget);
          await tester.tap(
            find.byWidgetPredicate(
              (w) =>
                  w is KIconButton &&
                  w.tooltip == 'Back to Lyrics for this song',
            ),
          );
          await tester.pumpAndSettle(const Duration(milliseconds: 100));
          expect(find.text('Choose lyrics'), findsNothing);
          expect(find.byType(LyricsForTrackBody), findsOneWidget);
          expect(m.choices.calls, isEmpty);
        });
      });

      testWidgets('auto search off: "Turn on auto search" switches it on', (
        tester,
      ) async {
        final m = await openModal(
          tester,
          const LyricsNone(),
          overrides: onlineUiOverrides(sources: _sources),
          size: size,
        );
        expect(m.container.read(lyricsAutoSearchProvider), isTrue);
        m.container.read(lyricsAutoSearchProvider.notifier).set(false);
        await tester.pump();
        await tester.tap(_button('Turn on auto search'));
        await tester.pump();
        expect(m.container.read(lyricsAutoSearchProvider), isTrue);
      });

      testWidgets('bar at 360 dp, normal text: no label wraps, the words do', (
        tester,
      ) async {
        await openModal(
          tester,
          LyricsShown(onlineLyrics(name: 'NetEase Cloud Music')),
          overrides: onlineUiOverrides(sources: _sources),
          size: const Size(360, 800),
        );
        for (final label in ['Keep this copy', 'Wrong song']) {
          final line = tester.getSize(find.text(label)).height;
          final one = tester.getSize(find.text('Wrong song')).height;
          expect(line, one, reason: '"$label" is one line');
        }
        expect(
          tester.getSize(find.text('Wrong song')).height,
          lessThan(24),
          reason: 'one line of label text',
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        'bar alone at 360 dp and 200 % text: wraps, no horizontal overflow',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(360, 700);
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                onlineLyricsCommandsProvider.overrideWithValue(
                  RecordingOnlineCommands(),
                ),
              ],
              child: MaterialApp(
                theme: buildKanaruTheme(brightness: Brightness.light),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                builder: (context, app) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(2)),
                  child: app!,
                ),
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: LyricsOnlineBar(
                      trackId: const TrackId(1),
                      close: () => true,
                      info: onlineRowInfoOf(
                        LyricsShown(
                          onlineLyrics(name: 'Một nguồn lời rất dài'),
                        ),
                        null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
          expect(find.text('Keep this copy'), findsOneWidget);
        },
      );

      testWidgets('200 % text, long Vietnamese-like names: no overflow', (
        tester,
      ) async {
        await openModal(
          tester,
          LyricsShown(
            onlineLyrics(
              name: 'Một nguồn lời có cái tên rất dài để thử cắt chữ',
              how: OnlineHow.kept,
            ),
          ),
          overrides: onlineUiOverrides(sources: _sources),
          size: size,
          textScale: 2,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('animations off: a running search draws a still arc', (
        tester,
      ) async {
        await openModal(
          tester,
          const LyricsSearching(1),
          overrides: onlineUiOverrides(sources: _sources),
          size: size,
          disableAnimations: true,
        );
        expect(byLyricsSpinner(), findsOneWidget);
        await expectStill(tester);
      });
    });
  }
}

/// One status line case: the state and the text it must show.
class LyricsStatusCase {
  const LyricsStatusCase(this.name, this.lyrics, this.text);
  final String name;
  final TrackLyrics lyrics;
  final String text;
}

final _statusCases = [
  const LyricsStatusCase(
    'searching',
    LyricsSearching(2),
    'No lyrics on this device · searching 2 enabled sources',
  ),
  LyricsStatusCase(
    'failed (network) with a retry time',
    LyricsLookupFailed(
      reason: LookupFailReason.network,
      asked: 2,
      retryAt: DateTime(2030, 1, 1, 21, 5),
    ),
    'Couldn’t find lyrics · network error · trying again at 9:05 PM',
  ),
  const LyricsStatusCase(
    'failed (needs config) without a retry time',
    LyricsLookupFailed(reason: LookupFailReason.needsConfig, asked: 1),
    'Couldn’t find lyrics · needs setting up',
  ),
  LyricsStatusCase(
    'paused',
    LyricsLookupPaused(DateTime(2030, 1, 1, 21, 5)),
    'The lyrics sources are paused until 9:05 PM '
        '(the server reported too many requests)',
  ),
  const LyricsStatusCase(
    'not found',
    LyricsNotFound(asked: 2, off: 2),
    'No lyrics found, even in 2 enabled sources',
  ),
  const LyricsStatusCase(
    'not found, every source off',
    LyricsNotFound(asked: 0, off: 2),
    'No lyrics on this device · every online source is off',
  ),
  const LyricsStatusCase(
    'no source',
    LyricsNoSource(),
    'No lyrics on this device · no online source yet',
  ),
  const LyricsStatusCase(
    'automatic search off',
    LyricsNone(),
    'No lyrics on this device · automatic search is off',
  ),
  const LyricsStatusCase(
    'not searchable',
    LyricsNone(reason: LyricsNoneReason.notSearchable),
    'No lyrics on this device',
  ),
];
