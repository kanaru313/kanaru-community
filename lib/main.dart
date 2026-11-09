import 'package:flutter/material.dart';

import 'src/rust/api/native_info.dart';
import 'src/rust/frb_generated.dart';

/// Placeholder entry point until the app shells land: loads the Rust library
/// and shows which native crates it links, proving the native build works on
/// every platform.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  runApp(KanaruApp(nativeVersions: nativeVersions()));
}

class KanaruApp extends StatelessWidget {
  const KanaruApp({super.key, required this.nativeVersions});

  final String nativeVersions;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kanaru',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: Scaffold(body: Center(child: Text('Native: $nativeVersions'))),
    );
  }
}
