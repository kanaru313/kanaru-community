import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the mobile push sidebar is open.
class MobileSidebarOpen extends Notifier<bool> {
  @override
  bool build() => false;

  void open() => state = true;
  void close() => state = false;
}

final mobileSidebarOpenProvider = NotifierProvider<MobileSidebarOpen, bool>(
  MobileSidebarOpen.new,
);
