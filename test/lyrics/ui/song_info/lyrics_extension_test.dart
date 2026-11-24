import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/extension/state/extension_registry.dart';
import 'package:kanaru/src/lyrics/lyrics_extension.dart';

void main() {
  test('registers one song detail section for the lyrics group', () {
    final registry = ExtensionRegistry();
    const LyricsExtension().register(registry);
    expect(registry.songDetailSections.map((s) => s.id), ['lyrics']);
  });
}
