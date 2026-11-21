import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/package/package_problem.dart';
import 'package:kanaru/src/plugins/domain/package/zip_reader.dart';

/// The problem [readZip] throws for [zip]; fails when it reads.
PackageProblem problemOf(Uint8List zip) {
  try {
    readZip(zip);
  } on PackageProblemError catch (e) {
    return e.problem;
  }
  fail('the zip was accepted');
}

void expectProblem<T extends PackageProblem>(Uint8List zip, [String? text]) {
  final problem = problemOf(zip);
  expect(problem, isA<T>());
  if (text != null) expect(problem.detail, contains(text));
}
