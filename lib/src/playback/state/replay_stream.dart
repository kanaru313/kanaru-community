import 'dart:async';

/// A broadcast value stream that gives a new listener the latest value first
/// (replay-1) and skips values equal to the last one.
class ReplayStream<T> {
  ReplayStream(this._value);

  T _value;
  final _controller = StreamController<T>.broadcast();

  T get value => _value;

  /// Sets [value] and notifies, unless it equals the current one.
  void add(T value) {
    if (_controller.isClosed || value == _value) return;
    _value = value;
    _controller.add(value);
  }

  Stream<T> get stream {
    late StreamController<T> out;
    StreamSubscription<T>? sub;
    out = StreamController<T>(
      onListen: () {
        out.add(_value);
        sub = _controller.stream.listen(
          out.add,
          onError: out.addError,
          onDone: out.close,
        );
      },
      onCancel: () => sub?.cancel(),
    );
    return out.stream;
  }

  Future<void> close() => _controller.close();
}
