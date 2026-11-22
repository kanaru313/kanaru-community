import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The plugins (by install id) whose last in-place update found the package
/// different from the repository list: their page offers [Làm mới danh sách]
/// instead of [Cập nhật] until the list is refreshed. Kept here, not in the
/// band, so leaving the page and coming back keeps the offer.
class RefreshOffers extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void offer(String installId) => state = {...state, installId};

  void clear(String installId) {
    if (!state.contains(installId)) return;
    state = {...state}..remove(installId);
  }
}

final refreshOffersProvider = NotifierProvider<RefreshOffers, Set<String>>(
  RefreshOffers.new,
);
