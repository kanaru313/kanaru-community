import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/install/held_package.dart';
import 'package:kanaru/src/plugins/domain/install/install_result.dart';
import 'package:kanaru/src/plugins/domain/install/script_checker.dart';
import 'package:kanaru/src/plugins/domain/install/update_diff.dart';

void main() {
  group('failureOfProblems', () {
    test('a package unlike the list is a catalog mismatch', () {
      expect(
        failureOfProblems(
          const ProblemsReview([
            CatalogDiffers([CatalogMismatch.sha256]),
          ]),
        ),
        InstallFailure.catalogMismatch,
      );
    });

    test('a script defect stays a plain package problem', () {
      expect(
        failureOfProblems(
          const ProblemsReview([
            ScriptSyntaxError('search.js', ScriptProblem(message: 'x')),
          ]),
        ),
        InstallFailure.hasProblems,
      );
    });

    test('another origin wins over the rest', () {
      expect(
        failureOfProblems(
          const ProblemsReview([
            CatalogDiffers([CatalogMismatch.sha256]),
            OtherOrigin(null),
          ]),
        ),
        InstallFailure.otherOrigin,
      );
    });
  });
}
