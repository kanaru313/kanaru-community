import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The red "Không cập nhật được: …" line of each row whose in-place update
/// failed, by install id. It stays until the next try of that row.
class UpdateFailures extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => const {};

  void set(String installId, String line) =>
      state = {...state, installId: line};

  void clear(String installId) {
    if (!state.containsKey(installId)) return;
    state = {...state}..remove(installId);
  }
}

final updateFailuresProvider =
    NotifierProvider<UpdateFailures, Map<String, String>>(UpdateFailures.new);
