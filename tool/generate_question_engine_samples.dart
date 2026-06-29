import 'dart:convert';
import 'dart:io';

import 'package:hexaiq_app/features/question_engine/question_engine.dart';

void main() {
  final engine = QuestionEngine();
  final output = <String, List<Map<String, Object?>>>{};

  for (final typeCode in NumericalGenerator.typeCodes) {
    output[typeCode] = [
      for (var index = 0; index < 20; index++)
        engine
            .generate(
              GenerateQuestionRequest(
                profileId: 'sample-profile',
                testId: 'sample-test',
                domain: QuestionDomain.numerical,
                ageGroup: 'grade5_6',
                index: index,
                typeCode: typeCode,
                level: (index % 10) + 1,
              ),
            )
            .toPublicJson(),
    ];
  }

  const encoder = JsonEncoder.withIndent('  ');
  final json = encoder.convert(output);
  Directory('outputs').createSync(recursive: true);
  final file = File('outputs/numerical_samples_NR01_NR20.json');
  file.writeAsStringSync(json);
  stdout.write(json);
}
