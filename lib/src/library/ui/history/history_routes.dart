import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import 'history_page.dart';
import 'track/track_history_page.dart';

/// Child routes of `/playlists`: History and the plays of one song. Paths are
/// relative to the Playlist route and go before `:uid`.
List<GoRoute> historyRoutes() => [
  GoRoute(
    path: 'history',
    pageBuilder: (context, state) =>
        KDetailPage(key: state.pageKey, child: const HistoryPage()),
    routes: [
      GoRoute(
        path: 'track/:trackId',
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['trackId'] ?? '');
          return KDetailPage(
            key: state.pageKey,
            child: TrackHistoryPage(trackId: id),
          );
        },
      ),
    ],
  ),
];
