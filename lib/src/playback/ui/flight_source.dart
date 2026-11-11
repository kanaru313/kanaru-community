import 'package:material_ui/material_ui.dart';

/// The four pieces that fly between a player surface (Now Playing, the mini
/// player) and the strip at the top of the queue sheet.
enum FlightPiece { cover, text, play, next }

/// A surface the queue sheet flies from and back to: it owns a key per piece
/// (to read where the piece is) and a flag the surface uses to hide its own
/// pieces while the flight draws them, so nothing shows twice.
class FlightSource {
  FlightSource() : keys = {for (final p in FlightPiece.values) p: GlobalKey()};

  final Map<FlightPiece, GlobalKey> keys;

  /// True while the queue sheet is open or moving.
  final ValueNotifier<bool> hidden = ValueNotifier(false);
  bool _disposed = false;

  /// Hides or shows the pieces; ignored once the surface is gone (the sheet
  /// can outlive the page it flew from by a frame).
  void setHidden(bool value) {
    if (!_disposed) hidden.value = value;
  }

  GlobalKey key(FlightPiece piece) => keys[piece]!;

  /// The piece's rect in global coordinates, or null when it is not on
  /// screen (not mounted, not laid out).
  Rect? rectOf(FlightPiece piece) {
    final context = keys[piece]?.currentContext;
    if (context == null) return null;
    try {
      final object = context.findRenderObject();
      if (object is! RenderBox || !object.attached || !object.hasSize) {
        return null;
      }
      return object.localToGlobal(Offset.zero) & object.size;
    } on Object {
      // The surface is leaving the tree (its element is inactive): the piece
      // then has no place to fly from and the flight fades instead.
      return null;
    }
  }

  void dispose() {
    _disposed = true;
    hidden.dispose();
  }
}

/// Wraps one piece of a [FlightSource]: keeps its key and hides it (still
/// laid out, so its rect stays readable) while the source is flying.
class FlightPieceHost extends StatelessWidget {
  const FlightPieceHost({
    super.key,
    required this.source,
    required this.piece,
    required this.child,
  });

  final FlightSource source;
  final FlightPiece piece;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: source.hidden,
      builder: (context, hidden, child) => Opacity(
        opacity: hidden ? 0 : 1,
        child: KeyedSubtree(key: source.key(piece), child: child!),
      ),
      child: child,
    );
  }
}
