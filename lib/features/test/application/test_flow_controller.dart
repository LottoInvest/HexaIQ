import '../../hexaiq/domain/hexaiq_models.dart';

class TestFlowController {
  const TestFlowController();

  int targetQuestionCount(TestType type) {
    return switch (type) {
      TestType.basic => 30,
      TestType.quickIq => 60,
      TestType.advanced => 90,
      TestType.professional => 120,
    };
  }

  int questionsPerDomain(TestType type) {
    return switch (type) {
      TestType.basic => 5,
      TestType.quickIq => 10,
      TestType.advanced => 15,
      TestType.professional => 20,
    };
  }

  bool shouldShowMidAd({
    required TestType type,
    required int completedQuestionCount,
  }) {
    if (type == TestType.quickIq) {
      return completedQuestionCount == questionsPerDomain(type) * 3;
    }
    if (type != TestType.advanced) {
      return false;
    }
    final perDomain = questionsPerDomain(type);
    if (completedQuestionCount % perDomain != 0) {
      return false;
    }
    final completedDomains = completedQuestionCount ~/ perDomain;
    return completedDomains == 2 || completedDomains == 4;
  }

  int resultAdCount(TestType type, {required bool professionalPurchased}) {
    return switch (type) {
      TestType.basic => 0,
      TestType.quickIq => 1,
      TestType.advanced => 1,
      TestType.professional => professionalPurchased ? 0 : 0,
    };
  }

  int totalAdCount(TestType type, {required bool professionalPurchased}) {
    final mid = switch (type) {
      TestType.quickIq => 1,
      TestType.advanced => 2,
      _ => 0,
    };
    return mid +
        resultAdCount(type, professionalPurchased: professionalPurchased);
  }
}
