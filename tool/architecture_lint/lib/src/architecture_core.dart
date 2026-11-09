import 'architecture_config.dart';

export 'architecture_config.dart';
export 'architecture_helpers.dart';

/// Message of the violation for a file placed directly in `lib/src/`.
const outsideModuleMessage =
    "File sits in 'lib/src/' outside any module folder; move it into a module.";

/// Violation for an app package file at [fileRel] (relative to lib/src) that
/// sits outside every module folder, or null.
Violation? fileOutsideModule(String fileRel) =>
    Place.of(fileRel) == null ? Violation('module_dependency', outsideModuleMessage) : null;

/// Violation when a file of `packages/kanaru_ui/lib` imports the app package.
/// The design system stays unaware of the app (Pro packages may import it).
Violation? packageImportsApp(ArchitectureConfig config, String uri) =>
    uri.startsWith('package:${config.package}/')
        ? Violation('package_imports_app',
            "kanaru_ui may not import the app ('$uri').")
        : null;

/// All violations for one directive. [fileRel] is the importing file relative
/// to lib/src (null when the file is outside lib/src). [targetRel] comes from
/// `resolveToLibSrc`, [targetRootFile] from `resolveToCompositionRoot`.
List<Violation> checkDirective({
  required ArchitectureConfig config,
  required String? fileRel,
  required String uri,
  required String? targetRel,
  String? targetRootFile,
}) {
  final out = <Violation>[];
  if (fileRel == null) return out;
  final from = Place.of(fileRel);
  if (from == null) {
    // A loose file would launder any edge: it is an error as importer.
    out.add(Violation('module_dependency', outsideModuleMessage));
    return out;
  }

  if (targetRootFile != null) {
    out.add(Violation('module_dependency',
        "Modules may not import the composition root 'lib/$targetRootFile'."));
  }
  if (from.layer == 'domain' && config.isForbiddenInDomain(uri)) {
    out.add(Violation('domain_no_flutter',
        "'domain/' must stay pure Dart; '$uri' depends on Flutter."));
  }
  final to = targetRel == null ? null : Place.of(targetRel);
  if (targetRel != null && to == null) {
    out.add(Violation('module_dependency', "Import target '$targetRel' is outside any module."));
    return out;
  }
  if (to == null) return out;

  if (from.layer == 'domain' && (to.layer == 'data' || to.layer == 'state' || to.layer == 'ui')) {
    out.add(Violation('domain_layer',
        "'domain/' may not import '${to.layer}/' (found '${to.module}/${to.layer}')."));
  }
  if (to.module == 'rust' && from.module != 'rust' && from.layer != 'data') {
    out.add(Violation('rust_only_from_data',
        "'rust/' (generated FFI) can only be imported from '<module>/data/'."));
  }
  if (from.module == 'screens' && to.module != 'screens' &&
      (to.layer == 'data' || to.module == 'database')) {
    out.add(Violation('screens_no_data',
        "'screens/' may not import data/ or database/ (found '${to.module}${to.layer == 'data' ? '/data' : ''}')."));
  }
  if (to.module != from.module && !config.special.contains(to.module)) {
    final ok = config.allowed[from.module];
    if (ok == null) {
      out.add(Violation('module_dependency',
          "Module '${from.module}' is not declared in architecture.yaml."));
    } else if (!config.direct.containsKey(to.module)) {
      out.add(Violation('module_dependency',
          "Module '${to.module}' is not declared in architecture.yaml."));
    } else if (!ok.contains(to.module)) {
      out.add(Violation('module_dependency',
          "'${from.module}' may not depend on '${to.module}' (allowed: ${ok.toList()..sort()})."));
    }
  }
  return out;
}
