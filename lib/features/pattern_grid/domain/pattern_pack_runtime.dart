import '../../hexaiq/domain/hexaiq_models.dart';
import 'pattern_difficulty_resolver.dart';
import 'pattern_json_parser.dart';
import 'pattern_pack_manager.dart';
import 'pattern_question_validator.dart';
import 'visual_question.dart';
import 'visual_question_generator.dart';

class PatternPackRuntimeResult {
  const PatternPackRuntimeResult({
    required this.packs,
    required this.validQuestions,
    required this.invalidQuestions,
    required this.fallbackQuestion,
  });

  final List<PatternPack> packs;
  final List<VisualQuestion> validQuestions;
  final List<VisualQuestion> invalidQuestions;
  final VisualQuestion fallbackQuestion;
}

class PatternPackRuntime {
  PatternPackRuntime({
    PatternPackManager? packManager,
    this.parser = const PatternJsonParser(),
    this.validator = const PatternQuestionValidator(),
    this.difficultyResolver = const PatternDifficultyResolver(),
  }) : packManager = packManager ?? PatternPackManager();

  final PatternPackManager packManager;
  final PatternJsonParser parser;
  final PatternQuestionValidator validator;
  final PatternDifficultyResolver difficultyResolver;

  Future<PatternPackRuntimeResult> load({
    TestType type = TestType.basic,
    bool hasPremium = false,
  }) async {
    final packs = await packManager.loadPacks();
    final questions = packManager.getQuestionsByTestType(
      type,
      hasPremium: hasPremium,
    );
    final valid = <VisualQuestion>[];
    final invalid = <VisualQuestion>[];
    for (final question in questions) {
      final result = validator.validate(question);
      if (result.isValid) {
        valid.add(question);
      } else {
        invalid.add(question);
      }
    }
    final fallback = fallbackQuestion();
    return PatternPackRuntimeResult(
      packs: packs,
      validQuestions: valid.isEmpty ? [fallback] : valid,
      invalidQuestions: invalid,
      fallbackQuestion: fallback,
    );
  }

  List<VisualQuestion> questionsForTestType(
    TestType type, {
    bool hasPremium = false,
  }) {
    final questions = packManager.getQuestionsByTestType(
      type,
      hasPremium: hasPremium,
    );
    return questions
        .where((question) => validator.validate(question).isValid)
        .toList(growable: false);
  }

  VisualQuestion parseQuestion(Map<String, Object?> json) {
    return parser.parseMap(json);
  }

  VisualQuestion fallbackQuestion() {
    return const VisualQuestionGenerator().generate(
      seed: 970,
      packId: 'fallback_pack',
    );
  }
}
