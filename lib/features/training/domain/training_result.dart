import '../../../core/domain/intelligence_domain.dart';
import '../../../core/domain/question_difficulty.dart';

class TrainingResult {
  const TrainingResult({
    required this.id,
    required this.profileId,
    required this.selectedDomains,
    required this.selectedDifficulty,
    required this.questionCount,
    required this.correctCount,
    required this.completedAt,
  });

  final String id;
  final String profileId;
  final List<IntelligenceDomain> selectedDomains;
  final QuestionDifficulty selectedDifficulty;
  final int questionCount;
  final int correctCount;
  final DateTime completedAt;

  double get accuracy => questionCount == 0 ? 0 : correctCount / questionCount;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'selected_domains': selectedDomains
          .map((domain) => domain.name)
          .join(','),
      'selected_difficulty': selectedDifficulty.name,
      'question_count': questionCount,
      'correct_count': correctCount,
      'completed_at': completedAt.toIso8601String(),
    };
  }

  factory TrainingResult.fromMap(Map<String, Object?> map) {
    final domainNames = (map['selected_domains'] as String? ?? '')
        .split(',')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    return TrainingResult(
      id: map['id'] as String,
      profileId: map['profile_id'] as String,
      selectedDomains: [
        for (final name in domainNames) IntelligenceDomain.values.byName(name),
      ],
      selectedDifficulty: QuestionDifficulty.values.byName(
        map['selected_difficulty'] as String,
      ),
      questionCount: (map['question_count'] as num).toInt(),
      correctCount: (map['correct_count'] as num).toInt(),
      completedAt: DateTime.parse(map['completed_at'] as String),
    );
  }
}
