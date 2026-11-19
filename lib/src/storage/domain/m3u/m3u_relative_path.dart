import 'package:path/path.dart' as p;

/// The path of [toFile] relative to the folder [fromDir], both canonical
/// absolute POSIX paths. For example from `/a/b` to `/a/x/c.mp3` gives
/// `../x/c.mp3`. The file name is never taken for a shared folder: from
/// `/a/b` to the file `/a/b` gives `../b`.
String relativeM3uPath(String fromDir, String toFile) {
  final name = p.posix.basename(toFile);
  final dir = p.posix.relative(p.posix.dirname(toFile), from: fromDir);
  return dir == '.' ? name : p.posix.join(dir, name);
}
