import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import 'saved_queues_page.dart';

/// Child routes of `/playlists`: the saved queues. Paths are
/// relative to the Playlist route and go before `:uid`.
List<GoRoute> savedQueueRoutes() => [
  GoRoute(
    path: 'queues',
    pageBuilder: (context, state) =>
        KDetailPage(key: state.pageKey, child: const SavedQueuesPage()),
  ),
];
