// Architecture gate entry point: `dart run tool/check_architecture.dart`
// (works from the app root; delegates to the pure-Dart package next to it).
import 'dart:io';

Future<void> main(List<String> args) async {
  final here = File.fromUri(Platform.script).parent.parent.path;
  final process = await Process.start(
    Platform.resolvedExecutable,
    ['run', 'bin/check_architecture.dart', args.isEmpty ? here : args.first],
    workingDirectory: '$here/tool/architecture_lint',
    mode: ProcessStartMode.inheritStdio,
  );
  exit(await process.exitCode);
}
