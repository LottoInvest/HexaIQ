import '../../../../core/domain/intelligence_domain.dart';
import '../../../../core/domain/question_difficulty.dart';

enum AdaptiveLevel { easy, medium, hard, expert }

extension AdaptiveLevelInfo on AdaptiveLevel {
  QuestionDifficulty get questionDifficulty {
    return switch (this) {
      AdaptiveLevel.easy => QuestionDifficulty.easy,
      AdaptiveLevel.medium => QuestionDifficulty.normal,
      AdaptiveLevel.hard => QuestionDifficulty.hard,
      AdaptiveLevel.expert => QuestionDifficulty.veryHard,
    };
  }

  double get thetaCenter {
    return switch (this) {
      AdaptiveLevel.easy => -1.2,
      AdaptiveLevel.medium => 0,
      AdaptiveLevel.hard => 1,
      AdaptiveLevel.expert => 2,
    };
  }
}

class DomainAdaptiveSnapshot {
  const DomainAdaptiveSnapshot({
    this.level = AdaptiveLevel.medium,
    this.theta = 0,
    this.correctStreak = 0,
    this.wrongStreak = 0,
  });

  final AdaptiveLevel level;
  final double theta;
  final int correctStreak;
  final int wrongStreak;

  DomainAdaptiveSnapshot copyWith({
    AdaptiveLevel? level,
    double? theta,
    int? correctStreak,
    int? wrongStreak,
  }) {
    return DomainAdaptiveSnapshot(
      level: level ?? this.level,
      theta: theta ?? this.theta,
      correctStreak: correctStreak ?? this.correctStreak,
      wrongStreak: wrongStreak ?? this.wrongStreak,
    );
  }
}

class DomainAdaptiveState {
  const DomainAdaptiveState({this.domains = const {}});

  final Map<IntelligenceDomain, DomainAdaptiveSnapshot> domains;

  DomainAdaptiveSnapshot snapshotFor(IntelligenceDomain domain) {
    return domains[domain] ?? const DomainAdaptiveSnapshot();
  }

  DomainAdaptiveState copyWithDomain({
    required IntelligenceDomain domain,
    required DomainAdaptiveSnapshot snapshot,
  }) {
    return DomainAdaptiveState(domains: {...domains, domain: snapshot});
  }
}

class AdaptiveEngine {
  const AdaptiveEngine();

  DomainAdaptiveState recordResponse({
    required DomainAdaptiveState state,
    required IntelligenceDomain domain,
    required bool isCorrect,
    double? theta,
  }) {
    final current = state.snapshotFor(domain);
    final safeTheta = theta != null && theta.isFinite ? theta : current.theta;
    final correctStreak = isCorrect ? current.correctStreak + 1 : 0;
    final wrongStreak = isCorrect ? 0 : current.wrongStreak + 1;
    final levelFromAnswer = nextLevel(
      current: current.level,
      isCorrect: isCorrect,
      correctStreak: correctStreak,
      wrongStreak: wrongStreak,
    );
    final thetaLevel = levelForTheta(safeTheta);
    final next = isCorrect
        ? _higher(levelFromAnswer, thetaLevel)
        : levelFromAnswer;
    return state.copyWithDomain(
      domain: domain,
      snapshot: current.copyWith(
        level: next,
        theta: safeTheta,
        correctStreak: correctStreak,
        wrongStreak: wrongStreak,
      ),
    );
  }

  AdaptiveLevel nextLevel({
    required AdaptiveLevel current,
    required bool isCorrect,
    int correctStreak = 0,
    int wrongStreak = 0,
  }) {
    final delta = isCorrect
        ? (correctStreak >= 2 ? 2 : 1)
        : (wrongStreak >= 1 ? -1 : 0);
    return _shift(current, delta);
  }

  AdaptiveLevel levelForTheta(double theta) {
    final safeTheta = theta.isFinite ? theta : 0.0;
    if (safeTheta < -0.75) {
      return AdaptiveLevel.easy;
    }
    if (safeTheta < 0.75) {
      return AdaptiveLevel.medium;
    }
    if (safeTheta < 1.75) {
      return AdaptiveLevel.hard;
    }
    return AdaptiveLevel.expert;
  }

  QuestionDifficulty difficultyForTheta(double theta) {
    return levelForTheta(theta).questionDifficulty;
  }

  AdaptiveLevel _shift(AdaptiveLevel level, int delta) {
    final values = AdaptiveLevel.values;
    final index = (level.index + delta).clamp(0, values.length - 1);
    return values[index];
  }

  AdaptiveLevel _higher(AdaptiveLevel a, AdaptiveLevel b) {
    return a.index >= b.index ? a : b;
  }
}
