import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/src/widgets/media/waveform_phase.dart';

/// Every cell of the state x event table, on a clock the test moves itself.
Duration ms(int v) => Duration(milliseconds: v);

const _snap = [20.0, 10.0, 30.0];
const unknown = KWaveformStatus.unknown;
const computing = KWaveformStatus.computing;
const ready = KWaveformStatus.ready;
const none = KWaveformStatus.none;

/// Mounted and decided at once.
WaveformPhase _mounted(KWaveformStatus s) =>
    WaveformPhase()..onStatus(s, Duration.zero);

/// A track changed right after mount (no decision yet); gate ends at 800.
WaveformPhase _afterChange() => WaveformPhase()..onTrackChange(ms(0));

/// Bars shown, then a track change at 0: collapsing, gate ends at 800.
WaveformPhase _collapsing([KWaveformStatus s = unknown]) => _mounted(ready)
  ..onTrackChange(ms(0), snapshot: _snap)
  ..onStatus(s, ms(0));

/// Computing, then ready with no gate pending: growing from 0.
WaveformPhase _growing() => _mounted(computing)..onStatus(ready, ms(0));

void expectKind(WaveformPhase p, WaveformPhaseKind k) => expect(p.kind, k);

void main() {
  group('unknown (mount)', () {
    test('status unknown: stays', () {
      final p = WaveformPhase()..onStatus(unknown, ms(0));
      expectKind(p, WaveformPhaseKind.unknown);
      expect(p.needsTicks, isFalse);
    });
    test('computing: dots at once', () {
      final p = _mounted(computing);
      expectKind(p, WaveformPhaseKind.dots);
      expect(p.growT, 0);
      expect(p.needsTicks, isFalse);
    });
    test('ready: shown at once, nothing to animate', () {
      final p = _mounted(ready);
      expectKind(p, WaveformPhaseKind.shown);
      expect(p.growT, 1);
      expect(p.needsTicks, isFalse);
    });
    test('none: fallback at once', () {
      final p = _mounted(none);
      expectKind(p, WaveformPhaseKind.fallback);
      expect(p.fallbackT, 1);
      expect(p.needsTicks, isFalse);
    });
    test('track change: unknown again, the gate starts', () {
      final p = WaveformPhase()..onTrackChange(ms(100));
      expectKind(p, WaveformPhaseKind.unknown);
      expect(p.gateAt, ms(900));
      expect(p.changed, isTrue);
    });
    test('tick: nothing changes', () {
      final p = WaveformPhase();
      final r = p.revision;
      p.onTick(ms(500));
      expectKind(p, WaveformPhaseKind.unknown);
      expect(p.revision, r);
    });
    test('reduce motion on: stays unknown', () {
      final p = WaveformPhase()..onReduceMotion(true, ms(0));
      expectKind(p, WaveformPhaseKind.unknown);
    });
    test('the first decision after an async gap is still applied at once', () {
      final p = WaveformPhase()..onStatus(unknown, ms(0));
      p.onStatus(ready, ms(40));
      expectKind(p, WaveformPhaseKind.shown);
      expect(p.needsTicks, isFalse);
    });
  });

  group('unknown (after change)', () {
    test('status unknown: stays', () {
      final p = _afterChange()..onStatus(unknown, ms(10));
      expectKind(p, WaveformPhaseKind.unknown);
    });
    test('computing: dots, gate kept', () {
      final p = _afterChange()..onStatus(computing, ms(10));
      expectKind(p, WaveformPhaseKind.dots);
      expect(p.gateAt, ms(800));
    });
    test('ready: waits for the gate, then grows', () {
      final p = _afterChange()..onStatus(ready, ms(10));
      expectKind(p, WaveformPhaseKind.unknown);
      expect(p.needsTicks, isTrue);
      p.onTick(ms(799));
      expectKind(p, WaveformPhaseKind.unknown);
      p.onTick(ms(800));
      expectKind(p, WaveformPhaseKind.growing);
      expect(p.gateAt, isNull);
    });
    test('none: fallback fades in over 200 ms', () {
      final p = _afterChange()..onStatus(none, ms(0));
      expectKind(p, WaveformPhaseKind.fallback);
      expect(p.fallbackT, 0);
      p.onTick(ms(100));
      expect(p.fallbackT, closeTo(0.5, 1e-9));
      p.onTick(ms(200));
      expect(p.fallbackT, 1);
    });
    test('track change: the gate restarts', () {
      final p = _afterChange()..onTrackChange(ms(300));
      expect(p.gateAt, ms(1100));
    });
    test('tick: the gate passing acts on the held status', () {
      final p = _afterChange()..onStatus(computing, ms(0));
      p.onTick(ms(800));
      expectKind(p, WaveformPhaseKind.dots);
      expect(p.gateAt, isNull);
      expect(p.needsTicks, isFalse);
    });
    test('reduce motion on: instant to the target, gate skipped', () {
      final p = _afterChange()..onStatus(ready, ms(10));
      p.onReduceMotion(true, ms(20));
      expectKind(p, WaveformPhaseKind.shown);
      expect(p.growT, 1);
      expect(p.gateAt, isNull);
      expect(p.needsTicks, isFalse);
    });
  });

  group('dots', () {
    test('status unknown / computing: stay dots', () {
      final p = _mounted(computing)
        ..onStatus(unknown, ms(0))
        ..onStatus(computing, ms(0));
      expectKind(p, WaveformPhaseKind.dots);
    });
    test('ready, gate passed: growing', () {
      final p = _mounted(computing)..onStatus(ready, ms(50));
      expectKind(p, WaveformPhaseKind.growing);
    });
    test('ready, gate pending: waits', () {
      final p = _afterChange()
        ..onStatus(computing, ms(0))
        ..onStatus(ready, ms(100));
      expectKind(p, WaveformPhaseKind.dots);
      p.onTick(ms(800));
      expectKind(p, WaveformPhaseKind.growing);
    });
    test('none: fallback fade', () {
      final p = _mounted(computing)..onStatus(none, ms(0));
      expectKind(p, WaveformPhaseKind.fallback);
      p.onTick(ms(200));
      expect(p.fallbackT, 1);
    });
    test('track change: stays dots, the gate restarts', () {
      final p = _afterChange()
        ..onStatus(computing, ms(0))
        ..onTrackChange(ms(400), snapshot: _snap);
      expectKind(p, WaveformPhaseKind.dots);
      expect(p.gateAt, ms(1200));
    });
    test('reduce motion on: instant', () {
      final p = _afterChange()
        ..onStatus(computing, ms(0))
        ..onReduceMotion(true, ms(0));
      expectKind(p, WaveformPhaseKind.dots);
      expect(p.gateAt, isNull);
    });
  });

  group('growing', () {
    test('status ready: continues', () {
      final p = _growing()..onTick(ms(300));
      final t = p.growT;
      p.onStatus(ready, ms(300));
      expectKind(p, WaveformPhaseKind.growing);
      expect(p.growT, t);
    });
    test('tick: advances over 600 ms, then shown', () {
      final p = _growing()..onTick(ms(300));
      expect(p.growT, closeTo(0.5, 1e-9));
      p.onTick(ms(600));
      expectKind(p, WaveformPhaseKind.shown);
      expect(p.growT, 1);
      expect(p.needsTicks, isFalse);
    });
    test('none: fades to the fallback from the current height', () {
      final p = _growing()..onTick(ms(300));
      p.onStatus(none, ms(300));
      expectKind(p, WaveformPhaseKind.fallback);
      expect(p.growT, closeTo(0.5, 1e-9));
      p.onTick(ms(400));
      expect(p.fallbackT, closeTo(0.5, 1e-9));
    });
    test('track change: collapses from the current heights', () {
      final p = _growing()..onTick(ms(300));
      p.onTrackChange(ms(300), snapshot: _snap);
      expectKind(p, WaveformPhaseKind.collapsing);
      expect(p.snapshot, _snap);
      expect(p.growT, 1);
      expect(p.gateAt, ms(1100));
    });
    test('reduce motion on: jumps to shown', () {
      final p = _growing()..onReduceMotion(true, ms(0));
      expectKind(p, WaveformPhaseKind.shown);
      expect(p.growT, 1);
    });
  });

  group('shown', () {
    test('status ready: stays shown', () {
      final p = _mounted(ready)..onStatus(ready, ms(10));
      expectKind(p, WaveformPhaseKind.shown);
      expect(p.needsTicks, isFalse);
    });
    test('none: fallback fade', () {
      final p = _mounted(ready)..onStatus(none, ms(0));
      expectKind(p, WaveformPhaseKind.fallback);
      expect(p.needsTicks, isTrue);
    });
    test('track change: collapse with a snapshot', () {
      final p = _mounted(ready)..onTrackChange(ms(0), snapshot: _snap);
      expectKind(p, WaveformPhaseKind.collapsing);
      expect(p.snapshot, _snap);
      expect(p.needsTicks, isTrue);
    });
    test('track change without a snapshot goes straight to dots', () {
      final p = _mounted(ready)..onTrackChange(ms(0));
      expectKind(p, WaveformPhaseKind.dots);
      expect(p.growT, 0);
    });
    test('reduce motion on: stays shown', () {
      final p = _mounted(ready)..onReduceMotion(true, ms(0));
      expectKind(p, WaveformPhaseKind.shown);
    });
  });

  group('collapsing', () {
    test('status unknown or computing: holds the collapse', () {
      final p = _collapsing()
        ..onStatus(unknown, ms(100))
        ..onStatus(computing, ms(100));
      expectKind(p, WaveformPhaseKind.collapsing);
    });
    test('computing: dots at the end of the collapse', () {
      final p = _collapsing(computing)..onTick(ms(600));
      expectKind(p, WaveformPhaseKind.dots);
      expect(p.snapshot, isNull);
    });
    test('ready: holds, grows after the collapse and the gate', () {
      final p = _collapsing(ready)..onTick(ms(300));
      expectKind(p, WaveformPhaseKind.collapsing);
      p.onTick(ms(600));
      expectKind(p, WaveformPhaseKind.dots);
      p.onTick(ms(799));
      expectKind(p, WaveformPhaseKind.dots);
      p.onTick(ms(800));
      expectKind(p, WaveformPhaseKind.growing);
    });
    test('none: fades to the fallback while the rest of the collapse runs', () {
      final p = _collapsing()..onTick(ms(300));
      p.onStatus(none, ms(300));
      expectKind(p, WaveformPhaseKind.fallback);
      expect(p.snapshot, _snap);
      p.onTick(ms(500));
      expect(p.fallbackT, 1);
      expect(p.growT, lessThan(0.5));
    });
    test('track change: snapshot again, collapse and gate restart', () {
      const again = [5.0, 6.0];
      final p = _collapsing()..onTick(ms(300));
      p.onTrackChange(ms(300), snapshot: again);
      expectKind(p, WaveformPhaseKind.collapsing);
      expect(p.snapshot, again);
      expect(p.growT, 1);
      expect(p.gateAt, ms(1100));
    });
    test('tick: advances, at the end dots', () {
      final p = _collapsing()..onTick(ms(300));
      expect(p.growT, closeTo(0.5, 1e-9));
      p.onTick(ms(600));
      expectKind(p, WaveformPhaseKind.dots);
    });
    test('reduce motion on: jumps to dots or the target', () {
      final a = _collapsing()..onReduceMotion(true, ms(10));
      expectKind(a, WaveformPhaseKind.dots);
      expect(a.growT, 0);
      expect(a.snapshot, isNull);
      final b = _collapsing(ready)..onReduceMotion(true, ms(10));
      expectKind(b, WaveformPhaseKind.shown);
      expect(b.growT, 1);
    });
  });

  group('fallback', () {
    test('status unknown or none: stays', () {
      final p = _mounted(none)
        ..onStatus(unknown, ms(0))
        ..onStatus(none, ms(0));
      expectKind(p, WaveformPhaseKind.fallback);
      expect(p.fallbackT, 1);
    });
    test('computing: fades back to dots over 200 ms', () {
      final p = _mounted(none)..onStatus(computing, ms(0));
      expectKind(p, WaveformPhaseKind.dots);
      p.onTick(ms(100));
      expect(p.fallbackT, closeTo(0.5, 1e-9));
      p.onTick(ms(200));
      expect(p.fallbackT, 0);
    });
    test('ready, gate passed: fades out and grows', () {
      final p = _mounted(none)..onStatus(ready, ms(0));
      expectKind(p, WaveformPhaseKind.growing);
      p.onTick(ms(200));
      expect(p.fallbackT, 0);
    });
    test('ready, gate pending: waits', () {
      final p = _afterChange()
        ..onStatus(none, ms(0))
        ..onStatus(ready, ms(100));
      expectKind(p, WaveformPhaseKind.fallback);
      p.onTick(ms(800));
      expectKind(p, WaveformPhaseKind.growing);
    });
    test('track change: fades back to dots, the gate restarts', () {
      final p = _mounted(none)..onTrackChange(ms(0), snapshot: _snap);
      expectKind(p, WaveformPhaseKind.dots);
      expect(p.gateAt, ms(800));
      p.onTick(ms(200));
      expect(p.fallbackT, 0);
    });
    test('reduce motion on: instant', () {
      final p = _mounted(none)
        ..onStatus(computing, ms(0))
        ..onReduceMotion(true, ms(10));
      expect(p.fallbackT, 0);
      expectKind(p, WaveformPhaseKind.dots);
      final q = _mounted(none)..onReduceMotion(true, ms(10));
      expect(q.fallbackT, 1);
    });
  });

  group('reduce motion, unknown on the same track', () {
    test('shown bars stay shown', () {
      final p = _mounted(ready)
        ..onReduceMotion(true, ms(0))
        ..onStatus(unknown, ms(10));
      expectKind(p, WaveformPhaseKind.shown);
      expect(p.growT, 1);
    });
    test('the fallback stays', () {
      final p = _mounted(none)
        ..onReduceMotion(true, ms(0))
        ..onStatus(unknown, ms(10));
      expectKind(p, WaveformPhaseKind.fallback);
      expect(p.fallbackT, 1);
    });
    test('growing bars end grown when reduce motion turns on', () {
      final p = _growing()
        ..onStatus(unknown, ms(10))
        ..onReduceMotion(true, ms(20));
      expectKind(p, WaveformPhaseKind.shown);
      expect(p.growT, 1);
    });
    test('a track change still settles on dots, then the new status', () {
      final p = _mounted(ready)
        ..onReduceMotion(true, ms(0))
        ..onTrackChange(ms(10), snapshot: _snap);
      expectKind(p, WaveformPhaseKind.dots);
      expect(p.growT, 0);
      expect(p.snapshot, isNull);
      p.onStatus(unknown, ms(20));
      expectKind(p, WaveformPhaseKind.dots);
      p.onStatus(ready, ms(30));
      expectKind(p, WaveformPhaseKind.shown);
      final q = _mounted(none)
        ..onReduceMotion(true, ms(0))
        ..onTrackChange(ms(10));
      expectKind(q, WaveformPhaseKind.dots);
      expect(q.fallbackT, 0);
    });
  });

  group('clock', () {
    test('a cached track grows no earlier than 800 ms after the change', () {
      final p = _mounted(ready)..onTrackChange(ms(1000), snapshot: _snap);
      p.onStatus(ready, ms(1000));
      p.onTick(ms(1500));
      expect(p.kind, isNot(WaveformPhaseKind.growing));
      p.onTick(ms(1799));
      expect(p.kind, isNot(WaveformPhaseKind.growing));
      p.onTick(ms(1800));
      expectKind(p, WaveformPhaseKind.growing);
    });
    test('goes idle once everything settled', () {
      final p = _mounted(ready)..onTrackChange(ms(0), snapshot: _snap);
      p.onStatus(ready, ms(0));
      for (var t = 0; t <= 1600; t += 16) {
        p.onTick(ms(t));
      }
      expectKind(p, WaveformPhaseKind.shown);
      expect(p.needsTicks, isFalse);
    });
    test('a clock that goes backwards does not move anything', () {
      final p = _growing()..onTick(ms(300));
      final t = p.growT;
      p.onTick(ms(100));
      expect(p.growT, t);
    });
  });
}
