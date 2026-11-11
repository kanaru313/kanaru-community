import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/flight_source.dart';

/// The mini player's side of the queue flight. One for the app: the mobile
/// shell hands it to the mini player, and every way of opening the queue sheet
/// from outside Now Playing (long press, the Queue nav item) flies from it.
final miniPlayerFlightProvider = Provider<FlightSource>((ref) {
  final source = FlightSource();
  ref.onDispose(source.dispose);
  return source;
});
