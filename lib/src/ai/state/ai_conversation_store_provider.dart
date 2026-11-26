import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/state/database_providers.dart';
import '../data/conversation_store.dart';

final aiConversationStoreProvider = Provider<ConversationStore>((ref) {
  final store = ConversationStore(ref.watch(appDatabaseProvider));
  ref.onDispose(store.dispose);
  return store;
});
