import 'package:material_ui/material_ui.dart';

/// Shown when startup fails before the real app can run. The localization
/// delegates are not available yet, so the text is fixed English + Vietnamese.
class KanaruErrorApp extends StatelessWidget {
  const KanaruErrorApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kanaru',
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SelectionArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Kanaru could not start.\nKanaru không thể khởi động.'),
                  const SizedBox(height: 16),
                  Text('$error'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
