import '../../../hexaiq/domain/hexaiq_models.dart';

enum TestMode { quickIq, fullDiagnostic, domainTraining }

extension TestModeInfo on TestMode {
  String get labelKo {
    return switch (this) {
      TestMode.quickIq => '빠른 IQ',
      TestMode.fullDiagnostic => '정밀 진단',
      TestMode.domainTraining => '영역 훈련',
    };
  }

  bool get contributesToIq {
    return switch (this) {
      TestMode.quickIq || TestMode.fullDiagnostic => true,
      TestMode.domainTraining => false,
    };
  }

  int get defaultQuestionCount {
    return switch (this) {
      TestMode.quickIq => 60,
      TestMode.fullDiagnostic => 30,
      TestMode.domainTraining => 10,
    };
  }
}

TestMode testModeFromTestType(TestType type) {
  return switch (type) {
    TestType.quickIq => TestMode.quickIq,
    TestType.advanced || TestType.professional => TestMode.fullDiagnostic,
    TestType.basic => TestMode.fullDiagnostic,
  };
}
