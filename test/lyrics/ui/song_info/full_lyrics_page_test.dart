import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';
import 'package:kanaru/src/lyrics/domain/online/online_lyrics_ref.dart';
import 'package:kanaru/src/lyrics/ui/song_info/song_info_lyrics_prefs.dart';

import '../../../support/memory_settings_store.dart';
import 'song_info_lyrics_host.dart';

/// Synced lyrics with an instrumental gap after line 1.
Lyrics _withGap() => const Lyrics(
  lines: [
    LyricLine(Duration(seconds: 1), 'Line 0'),
    LyricLine(Duration(seconds: 65), 'Line 1'),
    LyricLine(Duration(seconds: 70), ''),
    LyricLine(Duration(seconds: 80), 'Line 2'),
  ],
  synced: true,
  origin: LyricsOrigin.tag,
);

/// An intro gap, two lines, an end gap.
Lyrics _gapped() => const Lyrics(
  lines: [
    LyricLine(Duration.zero, ''),
    LyricLine(Duration(seconds: 9), 'A'),
    LyricLine(Duration(seconds: 12), 'B'),
    LyricLine(Duration(seconds: 15), ''),
  ],
  synced: true,
  origin: LyricsOrigin.tag,
);

Finder get _toggle => iconButton(showStamps);

Matcher _toggleState({required bool on, bool enabled = true}) => isSemantics(
  isButton: true,
  hasToggledState: true,
  isToggled: on,
  hasEnabledState: true,
  isEnabled: enabled,
  hasTapAction: enabled,
  hasFocusAction: enabled,
  isFocusable: enabled,
  label: enabled ? (on ? hideStamps : showStamps) : null,
);

void main() {
  testWidgets('modal: title, song, short source strip and every line', (
    tester,
  ) async {
    await openFull(tester, synced(8));
    expect(find.text('Lyrics'), findsNWidgets(2), reason: 'group + modal');
    expect(find.text('Song · Artist'), findsOneWidget);
    expect(find.text("In the file's tags · 8 lines"), findsOneWidget);
    for (var i = 0; i < 8; i++) {
      expect(modalLine('Line $i'), findsOneWidget);
    }
    expect(find.text('0:04'), findsNothing, reason: 'timestamps start off');
  });

  testWidgets('the strip never carries the .lrc file name', (tester) async {
    await openFull(tester, plain(3), lrc: 'sub/01 - Song.lrc');
    expect(find.text('.lrc file next to the song · 3 lines'), findsOneWidget);
  });

  testWidgets('an auto-found copy: plugin and "found automatically", no kind', (
    tester,
  ) async {
    await openFull(tester, online(OnlineHow.auto, n: 2));
    expect(
      find.text('NetEase · found automatically · 2 lines'),
      findsOneWidget,
    );
  });

  testWidgets('a kept copy names its plugin in the strip', (tester) async {
    await openFull(tester, online(OnlineHow.kept, n: 2));
    expect(
      find.text('Kept online copy · NetEase · 2 lines'),
      findsAtLeastNWidgets(1),
    );
  });

  testWidgets('the toggle is a button with toggled state, off by default', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await openFull(tester, synced(3));
    expect(
      tester.getSemantics(find.bySemanticsLabel(showStamps)),
      _toggleState(on: false),
    );
    await tester.tap(_toggle);
    await tester.pump();
    expect(
      tester.getSemantics(find.bySemanticsLabel(hideStamps)),
      _toggleState(on: true),
    );
    handle.dispose();
  });

  testWidgets('on: an m:ss column and a spoken gap mark; off: neither', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await openFull(tester, _withGap());
    expect(find.text('1:05'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('Instrumental break')), findsNothing);
    await tester.tap(_toggle);
    await tester.pump();
    for (final t in ['0:01', '1:05', '1:10', '1:20']) {
      expect(find.text(t), findsOneWidget);
    }
    expect(find.bySemanticsLabel(RegExp('Instrumental break')), findsOneWidget);
    await tester.tap(iconButton(hideStamps));
    await tester.pump();
    expect(find.text('1:05'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('Instrumental break')), findsNothing);
    handle.dispose();
  });

  testWidgets('the choice is remembered for the next opening', (tester) async {
    final settings = MemorySettingsStore();
    await openFull(tester, synced(3), settings: settings);
    await tester.tap(_toggle);
    await tester.pump();
    expect(settings.read('lyrics.info_show_timestamps'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.tap(find.text(openLabel));
    await tester.pumpAndSettle();
    expect(iconButton(hideStamps), findsOneWidget);
    expect(find.text('0:04'), findsOneWidget);
  });

  test('the setting key is its own and defaults to off', () {
    expect(lyricsInfoShowTimestampsSetting.key, 'lyrics.info_show_timestamps');
    expect(lyricsInfoShowTimestampsSetting.defaultValue, isFalse);
  });

  testWidgets('plain lyrics: toggle disabled with a reason and a note', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final settings = MemorySettingsStore();
    await settings.write('lyrics.info_show_timestamps', true);
    await openFull(tester, plain(3), settings: settings);
    const why = 'Plain lyrics, no timestamps';
    expect(
      tester.getSemantics(find.bySemanticsLabel(why).first),
      isSemantics(
        label: why,
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
        hasToggledState: true,
        isToggled: false,
      ),
    );
    expect(find.text(why), findsOneWidget, reason: 'the note at the body top');
    expect(find.text('0:00'), findsNothing);
    handle.dispose();
  });

  group('copy', () {
    String? copied;
    Object? failWith;

    setUp(() {
      copied = null;
      failWith = null;
    });

    void mockClipboard(WidgetTester tester) {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            if (failWith != null) throw failWith!;
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
    }

    testWidgets('puts the lines on the clipboard and says how many', (
      tester,
    ) async {
      mockClipboard(tester);
      await openFull(tester, synced(3));
      await tester.tap(iconButton('Copy lyrics'));
      await tester.pump();
      await tester.pump();
      expect(copied, 'Line 0\nLine 1\nLine 2');
      expect(find.text('Lyrics copied (3 lines)'), findsOneWidget);
    });

    testWidgets('leaves out the intro and end gaps', (tester) async {
      mockClipboard(tester);
      await openFull(tester, _gapped());
      await tester.tap(iconButton('Copy lyrics'));
      await tester.pump();
      await tester.pump();
      expect(copied, 'A\nB');
    });

    testWidgets('a refused clipboard is reported and says nothing is copied', (
      tester,
    ) async {
      mockClipboard(tester);
      failWith = PlatformException(code: 'denied');
      await openFull(tester, synced(3));
      await tester.tap(iconButton('Copy lyrics'));
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isA<PlatformException>());
      expect(copied, isNull);
      expect(find.textContaining('Lyrics copied'), findsNothing);
    });
  });
}
