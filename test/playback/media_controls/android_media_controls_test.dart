import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/data/media_controls/android_audio_session_port.dart';
import 'package:kanaru/src/platform/data/media_controls/android_media_controls.dart';
import 'package:kanaru/src/platform/data/media_controls/android_media_handler.dart';
import 'package:kanaru/src/platform/data/media_controls/command_buffer.dart';
import 'package:kanaru/src/platform/domain/media_controls.dart';

class FakeSession implements AudioSessionPort {
  bool grant = true;
  bool throws = false;
  final calls = <bool>[];
  final interruption = StreamController<AudioInterruptionEvent>.broadcast();
  final noisy = StreamController<void>.broadcast();

  @override
  Future<bool> setActive(bool active) async {
    calls.add(active);
    if (throws) throw StateError('no audio manager');
    return grant;
  }

  @override
  Stream<AudioInterruptionEvent> get interruptions => interruption.stream;

  @override
  Stream<void> get becomingNoisy => noisy.stream;
}

const _item = MediaControlsItem(
  id: '5',
  title: 'Song',
  artists: ['A', 'B'],
  album: 'Album',
  duration: Duration(seconds: 90),
);

MediaControlsState state({
  bool playing = true,
  bool started = true,
  Duration position = Duration.zero,
}) => MediaControlsState(
  playing: playing,
  stopped: false,
  started: started,
  canPlay: true,
  canNext: true,
  canPrevious: true,
  canSeek: true,
  position: position,
);

void main() {
  late AndroidMediaHandler handler;
  late FakeSession session;
  late AndroidMediaControls controls;
  late List<MediaCommand> seen;

  setUp(() {
    handler = AndroidMediaHandler();
    session = FakeSession();
    controls = AndroidMediaControls(handler, session);
    seen = [];
    controls.commands.listen(seen.add);
  });
  tearDown(() async {
    await controls.dispose();
    await session.interruption.close();
    await session.noisy.close();
  });

  group('command mapping', () {
    test('handler methods become commands', () async {
      await handler.play();
      await handler.pause();
      await handler.stop();
      await handler.skipToNext();
      await handler.skipToPrevious();
      await handler.setShuffleMode(AudioServiceShuffleMode.all);
      await handler.setShuffleMode(AudioServiceShuffleMode.none);
      await handler.setRepeatMode(AudioServiceRepeatMode.one);
      await handler.setRepeatMode(AudioServiceRepeatMode.all);
      await handler.setRepeatMode(AudioServiceRepeatMode.none);
      await pumpEventQueue();
      expect(seen.map((c) => c.runtimeType), [
        Play, Pause, Stop, Next, Previous, SetShuffle, SetShuffle, SetRepeat, SetRepeat, SetRepeat,
      ]);
      expect((seen[5] as SetShuffle).on, isTrue);
      expect((seen[6] as SetShuffle).on, isFalse);
      expect([for (final c in seen.skip(7)) (c as SetRepeat).repeat],
          [MediaRepeat.track, MediaRepeat.playlist, MediaRepeat.none]);
    });

    test('headset buttons: media toggles, next and previous', () async {
      await handler.click(MediaButton.media);
      await handler.click(MediaButton.next);
      await handler.click(MediaButton.previous);
      await pumpEventQueue();
      expect(seen.map((c) => c.runtimeType), [PlayPause, Next, Previous]);
    });

    test('seek targets the current item; without one it is dropped', () async {
      await handler.seek(const Duration(seconds: 3));
      await pumpEventQueue();
      expect(seen, isEmpty);
      await controls.update(_item, state());
      await handler.seek(const Duration(seconds: 3));
      await pumpEventQueue();
      final c = seen.single as SetPosition;
      expect((c.id, c.position), ('5', const Duration(seconds: 3)));
    });
  });

  group('cold-start buffer', () {
    test('a command before anyone listens is replayed once', () async {
      final h = AndroidMediaHandler();
      await h.click(MediaButton.media);
      final got = <MediaCommand>[];
      final c = AndroidMediaControls(h, FakeSession());
      c.commands.listen(got.add);
      await pumpEventQueue();
      expect(got.single, isA<PlayPause>());
      await c.dispose();
    });

    test('only the last held command is kept', () async {
      final b = CommandBuffer()..add(const Play())..add(const Next());
      final got = <MediaCommand>[];
      b.stream.listen(got.add);
      await pumpEventQueue();
      expect(got.single, isA<Next>());
      await b.close();
    });

    test('a command older than ten seconds is dropped', () async {
      var now = DateTime(2026);
      final b = CommandBuffer(clock: () => now)..add(const Play());
      now = now.add(const Duration(seconds: 11));
      final got = <MediaCommand>[];
      b.stream.listen(got.add);
      await pumpEventQueue();
      expect(got, isEmpty);
      await b.close();
    });

    test('a command just under ten seconds old is replayed', () async {
      var now = DateTime(2026);
      final b = CommandBuffer(clock: () => now)..add(const Play());
      now = now.add(const Duration(seconds: 9, milliseconds: 900));
      final got = <MediaCommand>[];
      b.stream.listen(got.add);
      await pumpEventQueue();
      expect(got.single, isA<Play>());
      await b.close();
    });

    test('after the listener is there, commands flow straight through', () async {
      final b = CommandBuffer();
      final got = <MediaCommand>[];
      b.stream.listen(got.add);
      b.add(const Stop());
      await pumpEventQueue();
      expect(got.single, isA<Stop>());
      await b.close();
    });
  });

  group('published state', () {
    test('item and controls', () async {
      await controls.update(_item, state(position: const Duration(seconds: 4)));
      final item = handler.mediaItem.value!;
      expect((item.id, item.title, item.artist, item.album, item.duration),
          ('5', 'Song', 'A, B', 'Album', const Duration(seconds: 90)));
      final s = handler.playbackState.value;
      expect(s.controls.map((c) => c.action), [
        MediaAction.skipToPrevious, MediaAction.pause, MediaAction.skipToNext,
      ]);
      expect(s.systemActions, {MediaAction.seek});
      expect(s.playing, isTrue);
      expect(s.processingState, AudioProcessingState.ready);
      expect(s.updatePosition, const Duration(seconds: 4));
    });

    test('paused shows the play control', () async {
      await controls.update(_item, state(playing: false));
      expect(handler.playbackState.value.controls[1].action, MediaAction.play);
    });

    test('not started stays idle: no notification at launch', () async {
      await controls.update(_item, state(playing: false, started: false));
      expect(handler.playbackState.value.processingState, AudioProcessingState.idle);
    });

    test('no item stays idle even when started', () async {
      await controls.update(null, state());
      expect(handler.playbackState.value.processingState, AudioProcessingState.idle);
      expect(handler.mediaItem.value, isNull);
    });

    test('an identical update publishes nothing', () async {
      await controls.update(_item, state());
      var emitted = 0;
      final sub = handler.playbackState.skip(1).listen((_) => emitted++);
      await controls.update(_item, state());
      await controls.update(_item, state(position: const Duration(seconds: 9)));
      await pumpEventQueue();
      expect(emitted, 0);
      await sub.cancel();
    });

    test('seeked publishes the new position', () async {
      await controls.update(_item, state());
      controls.seeked(const Duration(seconds: 50));
      expect(handler.playbackState.value.updatePosition, const Duration(seconds: 50));
    });
  });

  group('audio focus', () {
    test('activate asks for focus and reports a denial', () async {
      expect(await controls.activate(), isTrue);
      session.grant = false;
      expect(await controls.activate(), isFalse);
      expect(session.calls, [true, true]);
    });

    test('a failing platform call is a denial, not a throw', () async {
      session.throws = true;
      expect(await controls.activate(), isFalse);
      await controls.deactivate();
    });

    test('deactivate gives focus back', () async {
      await controls.deactivate();
      expect(session.calls, [false]);
    });

    AudioInterruptionEvent begin([AudioInterruptionType t = AudioInterruptionType.pause]) =>
        AudioInterruptionEvent(true, t);
    AudioInterruptionEvent end([AudioInterruptionType t = AudioInterruptionType.pause]) =>
        AudioInterruptionEvent(false, t);

    test('an interruption pauses; its end resumes our own pause', () async {
      await controls.update(_item, state());
      session.interruption.add(begin());
      await pumpEventQueue();
      expect(seen.single, isA<Pause>());
      await controls.update(_item, state(playing: false));
      session.interruption.add(end());
      await pumpEventQueue();
      expect(seen.map((c) => c.runtimeType), [Pause, Play]);
    });

    test('an end after a user pause does nothing', () async {
      await controls.update(_item, state(playing: false));
      session.interruption.add(begin());
      session.interruption.add(end());
      await pumpEventQueue();
      expect(seen, isEmpty);
    });

    test('an end that says do not resume does nothing', () async {
      await controls.update(_item, state());
      session.interruption.add(begin());
      session.interruption.add(end(AudioInterruptionType.unknown));
      await pumpEventQueue();
      expect(seen.single, isA<Pause>());
    });

    test('ducking is left to the system', () async {
      await controls.update(_item, state());
      session.interruption.add(begin(AudioInterruptionType.duck));
      session.interruption.add(end(AudioInterruptionType.duck));
      await pumpEventQueue();
      expect(seen, isEmpty);
    });

    test('playing again by hand cancels the resume', () async {
      await controls.update(_item, state());
      session.interruption.add(begin());
      await pumpEventQueue();
      await controls.update(_item, state(playing: false));
      await controls.update(_item, state()); // the user pressed play
      session.interruption.add(end());
      await pumpEventQueue();
      expect(seen.map((c) => c.runtimeType), [Pause]);
    });

    test('a second end does not resume twice', () async {
      await controls.update(_item, state());
      session.interruption.add(begin());
      await pumpEventQueue();
      await controls.update(_item, state(playing: false));
      session.interruption.add(end());
      session.interruption.add(end());
      await pumpEventQueue();
      expect(seen.whereType<Play>(), hasLength(1));
    });

    test('becoming noisy pauses', () async {
      session.noisy.add(null);
      await pumpEventQueue();
      expect(seen.single, isA<Pause>());
    });
  });

  test('start is a no-op and update never needs it', () async {
    await controls.start();
    await controls.update(_item, state());
  });
}
