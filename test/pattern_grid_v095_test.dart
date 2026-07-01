import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/core/domain/domain_result.dart';
import 'package:hexaiq_app/core/domain/intelligence_domain.dart';
import 'package:hexaiq_app/core/domain/question_difficulty.dart';
import 'package:hexaiq_app/features/export/domain/pdf_export_service.dart';
import 'package:hexaiq_app/features/growth/domain/progress_analytics.dart';
import 'package:hexaiq_app/features/hexaiq/domain/hexaiq_models.dart';
import 'package:hexaiq_app/features/pattern_grid/domain/pattern_cell.dart';
import 'package:hexaiq_app/features/pattern_grid/domain/pattern_generator.dart';
import 'package:hexaiq_app/features/pattern_grid/presentation/pattern_grid_view.dart';
import 'package:hexaiq_app/features/pattern_grid/presentation/pattern_question_widget.dart';
import 'package:hexaiq_app/features/training/domain/ai_training_engine.dart';

void main() {
  group('v0.9.5 Pattern Grid Engine', () {
    test('supports 2x2 through 5x5 grids', () {
      const generator = PatternGenerator();

      for (var size = 2; size <= 5; size++) {
        final grid = generator.generate(seed: 95, size: size);

        expect(grid.rows, size);
        expect(grid.columns, size);
        expect(grid.cells, hasLength(size * size));
      }
    });

    test('same seed generates the same pattern', () {
      const generator = PatternGenerator();

      final first = generator.generate(seed: 950, rule: PatternRule.color);
      final second = generator.generate(seed: 950, rule: PatternRule.color);

      expect(
        first.cells.map((cell) => cell.shape),
        second.cells.map((cell) => cell.shape),
      );
      expect(
        first.cells.map((cell) => cell.color),
        second.cells.map((cell) => cell.color),
      );
      expect(
        first.cells.map((cell) => cell.rotation),
        second.cells.map((cell) => cell.rotation),
      );
    });

    testWidgets('PatternGridView renders with Material theme and dark mode', (
      tester,
    ) async {
      final grid = const PatternGenerator().generate(seed: 1, size: 3);

      await tester.pumpWidget(
        MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.dark,
          ),
          home: Scaffold(
            body: Center(child: PatternGridView(grid: grid)),
          ),
        ),
      );

      expect(find.byType(PatternGridView), findsOneWidget);
      expect(find.byType(Card), findsWidgets);
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('PatternQuestionWidget can show generated choices', (
      tester,
    ) async {
      final pattern = const PatternGenerator().question(
        seed: 2,
        rule: PatternRule.rotation,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PatternQuestionWidget(pattern: pattern, showChoices: true),
          ),
        ),
      );

      expect(find.byType(PatternGridView), findsNWidgets(5));
      expect(find.text('1'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    test('PatternCell copyWith preserves omitted fields', () {
      const cell = PatternCell(
        shape: PatternShape.square,
        color: PatternColor.primary,
        rotation: 90,
      );

      final copied = cell.copyWith(color: PatternColor.error);

      expect(copied.shape, PatternShape.square);
      expect(copied.color, PatternColor.error);
      expect(copied.rotation, 90);
      expect(copied.filled, isTrue);
    });
  });

  group('v0.9.5 AI Training and Progress', () {
    test('AITrainingEngine prioritizes weak domains', () {
      final report = ReportSummary(
        overallScore: 90,
        summary: '요약',
        domainScores: const [],
        recommendations: const [],
        domainResults: const {
          IntelligenceDomain.numerical: DomainResult(
            domain: IntelligenceDomain.numerical,
            correctCount: 1,
            totalCount: 3,
            accuracy: 0.33,
            theta: -0.6,
          ),
          IntelligenceDomain.verbal: DomainResult(
            domain: IntelligenceDomain.verbal,
            correctCount: 3,
            totalCount: 3,
            accuracy: 1,
            theta: 0.8,
          ),
        },
      );

      final recommendations = const AITrainingEngine().recommend(
        report: report,
      );

      expect(recommendations.first.domain, IntelligenceDomain.numerical);
      expect(recommendations.first.focusAreas, contains('수열'));
    });

    test('ProgressAnalytics calculates IQ delta and average response time', () {
      final history = [
        _result(id: 'a', iq: 100, elapsed: 8, day: 1),
        _result(id: 'b', iq: 112, elapsed: 12, day: 2),
      ];

      final summary = const ProgressAnalytics().summarize(
        profile: null,
        history: history,
        growth: const [],
      );

      expect(summary.latestIQ, 112);
      expect(summary.iqDelta, 12);
      expect(summary.testCount, 2);
      expect(summary.averageResponseTime, 10);
    });

    test('Professional PDF includes report sections', () {
      final report = const PdfExportService().buildProfessionalReport(
        _result(id: 'pdf', iq: 118, elapsed: 9, day: 3),
      );

      expect(report, contains('패턴 문항'));
      expect(report, contains('영역별 상세 분석'));
      expect(report, contains('성장 그래프'));
      expect(report, contains('훈련 추천'));
      expect(report, contains('검사 이력 요약'));
    });
  });
}

TestResultSummary _result({
  required String id,
  required int iq,
  required int elapsed,
  required int day,
}) {
  return TestResultSummary(
    id: id,
    profileId: 'profile',
    startedAt: DateTime(2026, 1, day, 10),
    completedAt: DateTime(2026, 1, day, 10, 20),
    theta: (iq - 100) / 15,
    standardError: 0.5,
    estimatedIQ: iq,
    percentile: 70,
    abilityLevel: '평균 이상',
    averageDifficulty: QuestionDifficulty.normal,
    averageElapsedSeconds: elapsed,
    questionCount: 18,
  );
}
