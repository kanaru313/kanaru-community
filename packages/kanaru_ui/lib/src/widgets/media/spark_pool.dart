import 'dart:math' as math;
import 'dart:typed_data';

/// Most particles alive at once.
const int sparkPoolSize = 60;

/// The particles of the flat bar's `sparks` effect: a fixed pool, no
/// allocation after construction. A particle is born at the head of the played
/// part, flies back and down or up, and fades over its life.
class SparkPool {
  final _x = Float32List(sparkPoolSize);
  final _y = Float32List(sparkPoolSize);
  final _vx = Float32List(sparkPoolSize);
  final _vy = Float32List(sparkPoolSize);
  final _age = Float32List(sparkPoolSize);
  final _life = Float32List(sparkPoolSize);
  final _radius = Float32List(sparkPoolSize);
  int _count = 0;
  int _seed = 0x2545F491;

  /// Particles alive.
  int get count => _count;

  double get _unit {
    // xorshift32: cheap and deterministic.
    var s = _seed;
    s ^= (s << 13) & 0xFFFFFFFF;
    s ^= s >> 17;
    s ^= (s << 5) & 0xFFFFFFFF;
    _seed = s & 0xFFFFFFFF;
    return _seed / 0xFFFFFFFF;
  }

  double x(int i) => _x[i];
  double y(int i) => _y[i];
  double radius(int i) => _radius[i];

  /// 1 at birth, 0 at the end of its life.
  double remaining(int i) => 1 - _age[i] / _life[i];

  void clear() => _count = 0;

  /// Moves every particle by [dt] seconds and, with [emit] (0..1 energy),
  /// maybe gives birth to one at ([headX], [headY]): about 28 a second at
  /// full energy. A full pool gives none.
  void step(
    double dt, {
    required double headX,
    required double headY,
    required double emit,
  }) {
    final drag = math.pow(0.94, dt * 60).toDouble();
    var n = 0;
    for (var i = 0; i < _count; i++) {
      final age = _age[i] + dt;
      if (age >= _life[i]) continue;
      _x[n] = _x[i] + _vx[i] * dt;
      _y[n] = _y[i] + _vy[i] * dt;
      _vx[n] = _vx[i];
      _vy[n] = _vy[i] * drag;
      _age[n] = age;
      _life[n] = _life[i];
      _radius[n] = _radius[i];
      n++;
    }
    _count = n;
    if (emit > 0.05 && _count < sparkPoolSize && _unit < dt * 28 * emit) {
      final i = _count++;
      _x[i] = headX;
      _y[i] = headY;
      _vx[i] = -(15 + _unit * 25);
      _vy[i] = (_unit < 0.5 ? -1 : 1) * (18 + _unit * 28);
      _age[i] = 0;
      _life[i] = 0.7 + _unit * 0.5;
      _radius[i] = 1 + _unit * 1.3;
    }
  }
}
