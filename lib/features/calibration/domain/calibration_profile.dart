import '../../item_bank/domain/calibration_state.dart';
import 'calibration_config.dart';

class CalibrationProfile {
  CalibrationProfile({
    required this.itemId,
    this.responseCount = 0,
    this.correctCount = 0,
    this.correctRate = 0,
    this.averageTheta = 0,
    this.averageResponseTimeMs = 0,
    this.difficulty = 0,
    this.discrimination = 1,
    this.guessing = 0.25,
    this.upperAsymptote = 1,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  final String itemId;
  final int responseCount;
  final int correctCount;
  final double correctRate;
  final double averageTheta;
  final double averageResponseTimeMs;
  final double difficulty;
  final double discrimination;
  final double guessing;
  final double upperAsymptote;
  final DateTime updatedAt;

  CalibrationState state(CalibrationConfig config) {
    if (responseCount == 0) {
      return CalibrationState.notCalibrated;
    }
    if (responseCount < config.minResponsesForStable) {
      return CalibrationState.calibrating;
    }
    return CalibrationState.stable;
  }

  Map<String, Object?> toMap() {
    return {
      'item_id': itemId,
      'response_count': responseCount,
      'correct_count': correctCount,
      'correct_rate': correctRate,
      'average_theta': averageTheta,
      'average_response_time_ms': averageResponseTimeMs,
      'difficulty': difficulty,
      'discrimination': discrimination,
      'guessing': guessing,
      'upper_asymptote': upperAsymptote,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CalibrationProfile.fromMap(Map<String, Object?> map) {
    return CalibrationProfile(
      itemId: map['item_id'] as String,
      responseCount: map['response_count'] as int? ?? 0,
      correctCount: map['correct_count'] as int? ?? 0,
      correctRate: (map['correct_rate'] as num?)?.toDouble() ?? 0,
      averageTheta: (map['average_theta'] as num?)?.toDouble() ?? 0,
      averageResponseTimeMs:
          (map['average_response_time_ms'] as num?)?.toDouble() ?? 0,
      difficulty: (map['difficulty'] as num?)?.toDouble() ?? 0,
      discrimination: (map['discrimination'] as num?)?.toDouble() ?? 1,
      guessing: (map['guessing'] as num?)?.toDouble() ?? 0.25,
      upperAsymptote: (map['upper_asymptote'] as num?)?.toDouble() ?? 1,
      updatedAt:
          DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
