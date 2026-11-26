import 'dart:ui' show Size;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/data/conversation_rows.dart' show AiChatStats;
import 'package:kanaru/src/ai/domain/output/chat_readiness.dart';
import 'package:kanaru/src/ai/state/ai_chat_stats_provider.dart';
import 'package:kanaru/src/ai/state/chat_providers.dart';
import 'package:kanaru/src/plugins/domain/package/chat_spec.dart';
import 'package:kanaru/src/screens/settings/settings_routes.dart';
import 'package:kanaru/src/screens/settings/ui/ai/ai_services_section.dart';
import 'package:material_ui/material_ui.dart' show ThemeData;

import '../../../support/memory_settings_store.dart';
import '../../plugins/support/plugin_fixtures.dart';
import '../support/settings_host.dart';

// Marks "no model given": a null model means the plugin has none.
const String _auto = '\u0000auto';

/// An installed AI chat plugin as the services list reads it.
ChatPluginInfo service(
  String id, {
  String? name,
  String? model = _auto,
  ChatReadiness readiness = const ChatReady(),
}) => ChatPluginInfo(
  installId: id,
  installGeneration: 1,
  name: name ?? 'Service $id',
  version: 1,
  spec: const ChatSpec(),
  models: const [],
  defaultModel: identical(model, _auto) ? 'model-$id' : model,
  readiness: readiness,
);

/// Settings › AI chat over a plugin fixture: [services] is the list of
/// installed AI chat plugins (`null` = still loading), [removedNames] the
/// tombstone names by install id.
Future<SettingsHarness> openAiSettings(
  WidgetTester tester, {
  List<ChatPluginInfo>? services = const [],
  Map<String, String> removedNames = const {},
  MemorySettingsStore? store,
  Size size = const Size(400, 4000),
  String location = SettingsPaths.ai,
  ThemeData? theme,

  /// What the history block reads (default: 3 conversations, 1.8 MB).
  Future<AiChatStats> Function()? stats,
  List<Override> overrides = const [],
}) {
  final fixture = StoreFixture();
  addTearDown(fixture.close);
  return pumpSettings(
    tester,
    location: location,
    size: size,
    theme: theme,
    store: store,
    scaffold: true,
    quietPlugins: false,
    overrides: [
      ...fixture.overrides,
      chatPluginsProvider.overrideWithValue(
        services == null ? const AsyncLoading() : AsyncData(services),
      ),
      aiRemovedPluginNameProvider.overrideWith(
        (ref, id) async => removedNames[id],
      ),
      aiChatStatsProvider.overrideWith(
        (ref) =>
            (stats ??
            () async => const AiChatStats(conversations: 3, bytes: 1887436))(),
      ),
      ...overrides,
    ],
  );
}
