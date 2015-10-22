// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.task.options_test;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/task/model.dart';
import 'package:unittest/unittest.dart';

import '../../generated/test_support.dart';
import '../../reflective_tests.dart';
import '../../utils.dart';
import '../context/abstract_context.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(GenerateOptionsErrorsTaskTest);
  runReflectiveTests(OptionsFileValidatorTest);
}

isInstanceOf isGenerateOptionsErrorsTask =
    new isInstanceOf<GenerateOptionsErrorsTask>();

@reflectiveTest
class GenerateOptionsErrorsTaskTest extends AbstractContextTest {
  final optionsFilePath = '/${AnalysisEngine.ANALYSIS_OPTIONS_FILE}';

  Source source;
  @override
  setUp() {
    super.setUp();
    source = newSource(optionsFilePath);
  }

  test_buildInputs() {
    Map<String, TaskInput> inputs =
        GenerateOptionsErrorsTask.buildInputs(source);
    expect(inputs, isNotNull);
    expect(inputs.keys,
        unorderedEquals([GenerateOptionsErrorsTask.CONTENT_INPUT_NAME]));
  }

  test_constructor() {
    GenerateOptionsErrorsTask task =
        new GenerateOptionsErrorsTask(context, source);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, source);
  }

  test_createTask() {
    GenerateOptionsErrorsTask task =
        GenerateOptionsErrorsTask.createTask(context, source);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, source);
  }

  test_description() {
    GenerateOptionsErrorsTask task =
        new GenerateOptionsErrorsTask(null, source);
    expect(task.description, isNotNull);
  }

  test_descriptor() {
    TaskDescriptor descriptor = GenerateOptionsErrorsTask.DESCRIPTOR;
    expect(descriptor, isNotNull);
  }

  test_perform_bad_yaml() {
    String code = r'''
:
''';
    AnalysisTarget target = newSource(optionsFilePath, code);
    computeResult(target, ANALYSIS_OPTIONS_ERRORS);
    expect(task, isGenerateOptionsErrorsTask);
    List<AnalysisError> errors = outputs[ANALYSIS_OPTIONS_ERRORS];
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, AnalysisOptionsErrorCode.PARSE_ERROR);
  }

  test_perform_OK() {
    String code = r'''
analyzer:
  strong-mode: true
''';
    AnalysisTarget target = newSource(optionsFilePath, code);
    computeResult(target, ANALYSIS_OPTIONS_ERRORS);
    expect(task, isGenerateOptionsErrorsTask);
    expect(outputs[ANALYSIS_OPTIONS_ERRORS], isEmpty);
  }

  test_perform_unsupported_analyzer_option() {
    String code = r'''
analyzer:
  not_supported: true
''';
    AnalysisTarget target = newSource(optionsFilePath, code);
    computeResult(target, ANALYSIS_OPTIONS_ERRORS);
    expect(task, isGenerateOptionsErrorsTask);
    List<AnalysisError> errors = outputs[ANALYSIS_OPTIONS_ERRORS];
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, AnalysisOptionsWarningCode.UNSUPPORTED_OPTION);
    expect(errors[0].message,
        "The option 'not_supported' is not supported by analyzer");
  }
}

@reflectiveTest
class OptionsFileValidatorTest {
  final OptionsFileValidator validator =
      new OptionsFileValidator(new TestSource());
  final AnalysisOptionsProvider optionsProvider = new AnalysisOptionsProvider();

  test_analyzer_supported_exclude() {
    validate(
        '''
analyzer:
  exclude:
    - test/_data/p4/lib/lib1.dart
    ''',
        []);
  }

  test_analyzer_supported_strong_mode() {
    validate(
        '''
analyzer:
  strong-mode: true
    ''',
        []);
  }

  test_analyzer_unsupported_option() {
    validate(
        '''
analyzer:
  not_supported: true
    ''',
        [AnalysisOptionsWarningCode.UNSUPPORTED_OPTION]);
  }

  test_linter_supported_rules() {
    validate(
        '''
linter:
  rules:
    - camel_case_types
    ''',
        []);
  }

  test_linter_unssupported_option() {
    validate(
        '''
linter:
  unsupported: true
    ''',
        [AnalysisOptionsWarningCode.UNSUPPORTED_OPTION]);
  }

  void validate(String source, List<AnalysisOptionsErrorCode> expected) {
    var options = optionsProvider.getOptionsFromString(source);
    var errors = validator.validate(options);
    expect(errors.map((AnalysisError e) => e.errorCode),
        unorderedEquals(expected));
  }
}
