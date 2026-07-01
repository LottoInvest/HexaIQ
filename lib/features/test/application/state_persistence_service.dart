import '../domain/models/test_session.dart';

class TestSessionSnapshot {
  const TestSessionSnapshot({
    required this.sessionId,
    required this.modeName,
    required this.currentQuestionIndex,
    required this.selectedAnswers,
    required this.elapsedSeconds,
    required this.usedItemIds,
    required this.questionOrder,
    required this.adCheckpointState,
    required this.paymentState,
    required this.savedAt,
    this.loadedPackId,
    this.memoContent = '',
  });

  final String sessionId;
  final String modeName;
  final int currentQuestionIndex;
  final Map<String, int> selectedAnswers;
  final Map<String, int> elapsedSeconds;
  final Set<String> usedItemIds;
  final List<String> questionOrder;
  final String adCheckpointState;
  final String paymentState;
  final DateTime savedAt;
  final String? loadedPackId;
  final String memoContent;

  bool get hasProgress =>
      selectedAnswers.isNotEmpty || currentQuestionIndex > 0;

  Map<String, Object?> toJson() {
    return {
      'sessionId': sessionId,
      'modeName': modeName,
      'currentQuestionIndex': currentQuestionIndex,
      'selectedAnswers': selectedAnswers,
      'elapsedSeconds': elapsedSeconds,
      'usedItemIds': usedItemIds.toList(growable: false)..sort(),
      'questionOrder': questionOrder,
      'adCheckpointState': adCheckpointState,
      'paymentState': paymentState,
      'savedAt': savedAt.toIso8601String(),
      'loadedPackId': loadedPackId,
      'memoContent': memoContent,
    };
  }

  factory TestSessionSnapshot.fromJson(Map<String, Object?> json) {
    return TestSessionSnapshot(
      sessionId: json['sessionId'] as String? ?? '',
      modeName: json['modeName'] as String? ?? 'quickIq',
      currentQuestionIndex: json['currentQuestionIndex'] as int? ?? 0,
      selectedAnswers: _intMap(json['selectedAnswers']),
      elapsedSeconds: _intMap(json['elapsedSeconds']),
      usedItemIds: {
        for (final value in json['usedItemIds'] as List<Object?>? ?? const [])
          value.toString(),
      },
      questionOrder: [
        for (final value in json['questionOrder'] as List<Object?>? ?? const [])
          value.toString(),
      ],
      adCheckpointState: json['adCheckpointState'] as String? ?? 'none',
      paymentState: json['paymentState'] as String? ?? 'free',
      savedAt:
          DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      loadedPackId: json['loadedPackId'] as String?,
      memoContent: json['memoContent'] as String? ?? '',
    );
  }

  static Map<String, int> _intMap(Object? value) {
    if (value is! Map) {
      return const {};
    }
    return {
      for (final entry in value.entries)
        entry.key.toString(): (entry.value as num?)?.toInt() ?? 0,
    };
  }
}

class StatePersistenceService {
  const StatePersistenceService();

  TestSessionSnapshot snapshot(
    TestSession session, {
    String adCheckpointState = 'none',
    String paymentState = 'free',
    String? loadedPackId,
    String memoContent = '',
    DateTime? savedAt,
  }) {
    return TestSessionSnapshot(
      sessionId: session.sessionId,
      modeName: session.mode.name,
      currentQuestionIndex: session.currentQuestionIndex,
      selectedAnswers: Map<String, int>.from(session.selectedAnswers),
      elapsedSeconds: Map<String, int>.from(session.elapsedSeconds),
      usedItemIds: Set<String>.from(session.usedItemIds),
      questionOrder: [
        for (final question in session.activeQuestions) question.id,
        for (final item in session.items) item.id,
      ],
      adCheckpointState: adCheckpointState,
      paymentState: paymentState,
      savedAt: savedAt ?? DateTime.now(),
      loadedPackId: loadedPackId,
      memoContent: memoContent,
    );
  }

  bool canResume(TestSessionSnapshot snapshot) {
    return snapshot.sessionId.isNotEmpty &&
        snapshot.currentQuestionIndex >= 0 &&
        snapshot.hasProgress;
  }

  TestSession applySnapshot(TestSession session, TestSessionSnapshot snapshot) {
    return session.copyWith(
      currentQuestionIndex: snapshot.currentQuestionIndex,
      selectedAnswers: snapshot.selectedAnswers,
      elapsedSeconds: snapshot.elapsedSeconds,
      usedItemIds: snapshot.usedItemIds,
    );
  }
}
