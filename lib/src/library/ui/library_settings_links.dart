import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../state/library_settings_focus.dart';

/// Where Settings › Library lives. The library module cannot import the
/// screens that own the route, so the location is repeated here.
const String librarySettingsLocation = '/settings/library';

/// Opens Settings › Library. With [focus] the page also scrolls to that block
/// and pulses it once (the request is a signal, not part of the location).
void openLibrarySettings(
  BuildContext context,
  WidgetRef ref, {
  LibrarySettingsAnchor? focus,
}) {
  if (focus != null) {
    ref.read(librarySettingsFocusProvider.notifier).request(focus);
  }
  context.go(librarySettingsLocation);
}
