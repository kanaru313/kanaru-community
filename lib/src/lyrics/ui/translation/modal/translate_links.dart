import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../playback/state/now_playing_panel.dart';
import '../../lyrics_settings_link.dart';
import 'translate_frame.dart';

/// The plugin store filtered to translation plugins (`?kind=translate`),
/// where "Mở kho tiện ích" and "Tải thêm tiện ích dịch" lead. The route
/// belongs to `screens/plugins`, which this module cannot import.
const String translatePluginStoreLocation = '/settings/plugins?kind=translate';

/// Where a [location] button of the modal leads: the modal closes with every
/// page over it, the desktop Now Playing panel closes so the page is visible,
/// then the router goes there. The router and panel are taken first because
/// the modal's context is gone once it pops.
void openFromTranslateModal(
  WidgetRef ref,
  TranslateModalControl control,
  GoRouter router,
  String location,
) {
  final panel = ref.read(nowPlayingPanelProvider.notifier);
  if (!control.closeAll()) return;
  panel.close();
  router.go(location);
}

/// The ⚙ of the modal: Cài đặt › Lời bài, at the Dịch lời block.
String get translateSettingsLocation => lyricsTranslationSettingsLocation;

/// [installId]'s plugin page ("Cấu hình").
String translatePluginPageLocation(String installId) =>
    lyricsPluginPageLocation(installId);

/// "Mở kho tiện ích" / "Tải thêm tiện ích dịch".
void openTranslateStore(
  BuildContext context,
  WidgetRef ref,
  TranslateModalControl control,
) => openFromTranslateModal(
  ref,
  control,
  GoRouter.of(context),
  translatePluginStoreLocation,
);

/// "Cấu hình": the page of the plugin [installId].
void openTranslatePlugin(
  BuildContext context,
  WidgetRef ref,
  TranslateModalControl control,
  String installId,
) => openFromTranslateModal(
  ref,
  control,
  GoRouter.of(context),
  translatePluginPageLocation(installId),
);

/// The ⚙ of the modal.
void openTranslateSettings(
  BuildContext context,
  WidgetRef ref,
  TranslateModalControl control,
) => openFromTranslateModal(
  ref,
  control,
  GoRouter.of(context),
  translateSettingsLocation,
);
