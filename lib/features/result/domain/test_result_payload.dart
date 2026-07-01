import 'dart:convert';

import '../../../core/domain/domain_result.dart';
import '../../../core/domain/intelligence_domain.dart';
import '../../hexaiq/domain/hexaiq_models.dart';
import '../../test/domain/models/test_mode.dart';

class TestResultPayload {
  const TestResultPayload({
    required this.resultId,
    required this.profileId,
    required this.testMode,
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.correctCount,
    required this.accuracy,
    required this.totalElapsedSeconds,
    required this.averageElapsedSeconds,
    required this.questionIds,
    required this.domainScores,
  });

  final String resultId;
  final String profileId;
  final TestMode testMode;
  final int totalQuestions;
  final int answeredQuestions;
  final int correctCount;
  final double accuracy;
  final int totalElapsedSeconds;
  final int averageElapsedSeconds;
  final List<String> questionIds;
  final Map<IntelligenceDomain, DomainResult> domainScores;

  int get accuracyPercent => (accuracy.clamp(0, 1) * 100).round();

  String get elapsedLabel {
    if (totalElapsedSeconds < 60) {
      return '$totalElapsedSeconds초';
    }
    final minutes = totalElapsedSeconds ~/ 60;
    final seconds = totalElapsedSeconds % 60;
    return seconds == 0 ? '$minutes분' : '$minutes분 $seconds초';
  }

  List<int?> get hexagonValues {
    return [
      for (final info in domainCatalog)
        domainScores.containsKey(info.domain)
            ? domainScores[info.domain]!.domainScore.round().clamp(0, 100)
            : null,
    ];
  }

  List<double> get visibleHexagonValues {
    return [for (final value in hexagonValues) (value ?? 0).toDouble()];
  }

  Map<String, Object?> toJson() {
    return {
      'schemaVersion': 1,
      'resultId': resultId,
      'profileId': profileId,
      'testMode': testMode.name,
      'totalQuestions': totalQuestions,
      'answeredQuestions': answeredQuestions,
      'correctCount': correctCount,
      'accuracy': accuracy,
      'totalElapsedSeconds': totalElapsedSeconds,
      'averageElapsedSeconds': averageElapsedSeconds,
      'questionIds': questionIds,
      'domainScores': {
        for (final entry in domainScores.entries)
          entry.key.name: {
            'correctCount': entry.value.correctCount,
            'totalCount': entry.value.totalCount,
            'accuracy': entry.value.accuracy,
            'elapsedSeconds': entry.value.elapsedSeconds,
            'theta': entry.value.theta,
            'difficulty': entry.value.difficulty,
            'domainScore': entry.value.domainScore,
            'iqContribution': entry.value.iqContribution,
          },
      },
    };
  }

  String encode() => jsonEncode(toJson());

  factory TestResultPayload.fromResult(TestResultSummary result) {
    Map<String, Object?> decoded;
    try {
      final parsed = jsonDecode(result.payloadJson);
      decoded = parsed is Map ? parsed.cast<String, Object?>() : {};
    } on Object {
      decoded = {};
    }

    final totalQuestions = _intValue(
      decoded['totalQuestions'],
      fallback: result.questionCount,
    );
    final answeredQuestions = _intValue(
      decoded['answeredQuestions'],
      fallback: totalQuestions,
    ).clamp(0, totalQuestions);
    final correctCount = _intValue(
      decoded['correctCount'],
      fallback: 0,
    ).clamp(0, totalQuestions);
    final accuracy = _doubleValue(
      decoded['accuracy'],
      fallback: totalQuestions == 0 ? 0 : correctCount / totalQuestions,
    ).clamp(0.0, 1.0);
    final averageElapsedSeconds = _intValue(
      decoded['averageElapsedSeconds'],
      fallback: result.averageElapsedSeconds,
    );
    final totalElapsedSeconds = _intValue(
      decoded['totalElapsedSeconds'],
      fallback: averageElapsedSeconds * totalQuestions,
    );
    final modeName = decoded['testMode'] as String?;
    final questionIdsValue = decoded['questionIds'];
    final questionIds = questionIdsValue is List
        ? questionIdsValue.map((item) => '$item').toList(growable: false)
        : const <String>[];

    return TestResultPayload(
      resultId: decoded['resultId'] as String? ?? result.id,
      profileId: decoded['profileId'] as String? ?? result.profileId,
      testMode:
          TestMode.values.where((mode) => mode.name == modeName).firstOrNull ??
          TestMode.quickIq,
      totalQuestions: totalQuestions,
      answeredQuestions: answeredQuestions,
      correctCount: correctCount,
      accuracy: accuracy,
      totalElapsedSeconds: totalElapsedSeconds,
      averageElapsedSeconds: averageElapsedSeconds,
      questionIds: questionIds,
      domainScores: _domainScores(decoded['domainScores']),
    );
  }

  static Map<IntelligenceDomain, DomainResult> _domainScores(Object? value) {
    if (value is! Map) {
      return const {};
    }
    return {
      for (final entry in value.entries)
        if (entry.key is String && entry.value is Map)
          ..._domainScore(entry.key as String, entry.value as Map),
    };
  }

  static Map<IntelligenceDomain, DomainResult> _domainScore(
    String domainName,
    Map<dynamic, dynamic> value,
  ) {
    final domain = IntelligenceDomain.values
        .where((item) => item.name == domainName)
        .firstOrNull;
    if (domain == null) {
      return const {};
    }
    final total = _intValue(value['totalCount'], fallback: 0);
    final correct = _intValue(
      value['correctCount'],
      fallback: 0,
    ).clamp(0, total);
    return {
      domain: DomainResult(
        domain: domain,
        correctCount: correct,
        totalCount: total,
        accuracy: _doubleValue(
          value['accuracy'],
          fallback: total == 0 ? 0 : correct / total,
        ).clamp(0.0, 1.0),
        elapsedSeconds: _intValue(value['elapsedSeconds'], fallback: 0),
        theta: _doubleValue(value['theta'], fallback: 0),
        difficulty: _doubleValue(value['difficulty'], fallback: 0),
        domainScore: _doubleValue(
          value['domainScore'],
          fallback: 0,
        ).clamp(0, 100),
        iqContribution: _doubleValue(value['iqContribution'], fallback: 0),
      ),
    };
  }

  static int _intValue(Object? value, {required int fallback}) {
    if (value is int) {
      return value;
    }
    if (value is num && value.isFinite) {
      return value.round();
    }
    return fallback;
  }

  static double _doubleValue(Object? value, {required double fallback}) {
    if (value is num && value.isFinite) {
      return value.toDouble();
    }
    return fallback;
  }
}
