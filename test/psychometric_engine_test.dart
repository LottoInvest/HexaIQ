import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/core/domain/question_difficulty.dart';
import 'package:hexaiq_app/core/persistence/hexa_iq_database.dart';
import 'package:hexaiq_app/core/persistence/settings_repository.dart';
import 'package:hexaiq_app/features/calibration/data/sqlite_calibration_repository.dart';
import 'package:hexaiq_app/features/calibration/domain/calibration_config.dart';
import 'package:hexaiq_app/features/calibration/domain/calibration_profile.dart';
import 'package:hexaiq_app/features/calibration/domain/calibration_repository.dart';
import 'package:hexaiq_app/features/calibration/domain/calibration_updater.dart';
import 'package:hexaiq_app/features/export/data/sqlite_export_repository.dart';
import 'package:hexaiq_app/features/export/domain/report_exporter.dart';
import 'package:hexaiq_app/features/hexaiq/data/mock_hexaiq_repository.dart';
import 'package:hexaiq_app/features/hexaiq/domain/hexaiq_models.dart';
import 'package:hexaiq_app/features/test/application/test_session_controller.dart';
import 'package:hexaiq_app/features/test/domain/models/question_record.dart';
import 'package:hexaiq_app/features/test/domain/models/test_session.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late HexaIQDatabase database;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() {
    database = HexaIQDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('CalibrationConfig exposes stable defaults', () {
    const config = CalibrationConfig();

    expect(config.minResponsesForStable, 30);
    expect(config.learningRate, greaterThan(0));
    expect(config.maxGuessing, greaterThan(config.minGuessing));
    expect(config.maxDifficulty, 3);
  });

  test('CalibrationProfile maps to and from SQLite row', () {
    final profile = CalibrationProfile(
      itemId: 'NR-001',
      responseCount: 4,
      correctCount: 3,
      correctRate: 0.75,
      averageTheta: 0.4,
      averageResponseTimeMs: 1200,
      difficulty: 0.2,
      discrimination: 1.2,
      guessing: 0.2,
      upperAsymptote: 1,
      updatedAt: DateTime(2026),
    );

    final restored = CalibrationProfile.fromMap(profile.toMap());

    expect(restored.itemId, profile.itemId);
    expect(restored.responseCount, 4);
    expect(restored.correctRate, 0.75);
    expect(restored.discrimination, 1.2);
  });

  test('CalibrationUpdater updates counts, rate, theta, and parameters', () {
    const updater = CalibrationUpdater();
    final current = CalibrationProfile(itemId: 'NR-001');
    final record = QuestionRecord.fromQuestion(
      question: _question(),
      correct: true,
      elapsedSeconds: 2,
      thetaAfter: 0.5,
      expectedProbability: 0.4,
      residual: 0.6,
    ).copyWith(itemInformation: 0.3);

    final next = updater.update(current: current, response: record);

    expect(next.responseCount, 1);
    expect(next.correctCount, 1);
    expect(next.correctRate, 1);
    expect(next.averageTheta, 0.5);
    expect(next.averageResponseTimeMs, 2000);
    expect(next.difficulty, lessThanOrEqualTo(current.difficulty));
    expect(next.discrimination, greaterThan(current.discrimination));
  });

  test('InMemoryCalibrationRepository saves and loads profiles', () async {
    final repository = InMemoryCalibrationRepository();
    final profile = CalibrationProfile(itemId: 'NR-001', responseCount: 1);

    await repository.save(profile);

    expect(await repository.load('NR-001'), isNotNull);
    expect(await repository.loadAll(), hasLength(1));
    await repository.clear();
    expect(await repository.loadAll(), isEmpty);
  });

  test('SQLiteCalibrationRepository persists profiles', () async {
    final repository = SQLiteCalibrationRepository(database);
    final profile = CalibrationProfile(itemId: 'NR-002', responseCount: 2);

    await repository.save(profile);
    final loaded = await repository.load('NR-002');

    expect(loaded?.itemId, 'NR-002');
    expect(loaded?.responseCount, 2);
    expect(await repository.loadAll(), hasLength(1));
  });

  test('SQLite settings repository persists theme', () async {
    final repository = SQLiteSettingsRepository(database);

    expect(await repository.loadThemeMode(), ThemeMode.dark);
    await repository.saveThemeMode(ThemeMode.light);

    expect(await repository.loadThemeMode(), ThemeMode.light);
  });

  test('Mock repository stores profiles in SQLite', () async {
    final repository = MockHexaIQRepository(database: database);
    final profiles = await repository.loadProfiles();
    final updated = profiles.first.copyWith(recentIQ: 112, testCount: 1);

    await repository.saveProfiles([updated, ...profiles.skip(1)]);
    final reloaded = await repository.loadProfiles();

    expect(reloaded.first.recentIQ, 112);
    expect(reloaded.first.testCount, 1);
  });

  test('Mock repository stores test history in SQLite', () async {
    final repository = MockHexaIQRepository(database: database);
    final profile = (await repository.loadProfiles()).first;
    final result = _result(profile.id);

    await repository.saveTestResult(result);
    final history = await repository.loadTestHistory(profile.id);

    expect(history, hasLength(1));
    expect(history.single.estimatedIQ, 109);
  });

  test('Growth uses persisted test history when available', () async {
    final repository = MockHexaIQRepository(database: database);
    final profile = (await repository.loadProfiles()).first;

    await repository.saveTestResult(_result(profile.id));
    final growth = await repository.loadGrowth(profile);

    expect(growth.single.score, 109);
  });

  test('TestSessionController writes calibration updates', () async {
    final repository = InMemoryCalibrationRepository();
    final question = _question();
    final controller = TestSessionController(
      TestSession(
        sessionId: 'session-calibration',
        startedAt: DateTime(2026),
        questions: [question],
        generatedQuestions: [question],
      ),
      calibrationRepository: repository,
    )..selectAnswer(question.answerIndex);

    controller.submit(completedAt: DateTime(2026, 1, 2));
    await Future<void>.delayed(Duration.zero);

    final profile = await repository.load(question.itemId!);
    expect(profile?.responseCount, 1);
    expect(profile?.correctCount, 1);
  });

  test('ReportExporter emits JSON and CSV', () {
    const exporter = ReportExporter();
    final result = _result('profile-1');

    final jsonReport = exporter.export(
      format: ReportExportFormat.json,
      result: result,
    );
    final csvReport = exporter.export(
      format: ReportExportFormat.csv,
      result: result,
    );

    expect(jsonDecode(jsonReport.content)['estimatedIQ'], 109);
    expect(csvReport.content, contains('estimated_iq'));
    expect(csvReport.content, contains('109'));
  });

  test('SQLiteExportRepository persists export jobs', () async {
    final repository = SQLiteExportRepository(database);
    final report = const ReportExporter().export(
      format: ReportExportFormat.csv,
      result: _result('profile-1'),
    );

    await repository.save(report);
    final loaded = await repository.loadAll();

    expect(loaded, hasLength(1));
    expect(loaded.single.content, report.content);
  });
}

TestQuestion _question() {
  return const TestQuestion(
    id: 'q-cal',
    domain: CognitiveDomain.numerical,
    typeCode: 'NR01',
    level: 5,
    prompt: '1, 2, ?',
    choices: ['2', '3', '4', '5'],
    answerIndex: 1,
    explanation: 'Add one.',
    difficulty: QuestionDifficulty.normal,
    difficultyIndex: 0,
    discrimination: 1,
    guessing: 0.25,
    itemId: 'NR-001',
  );
}

TestResultSummary _result(String profileId) {
  return TestResultSummary(
    id: 'session-result',
    profileId: profileId,
    startedAt: DateTime(2026),
    completedAt: DateTime(2026, 1, 2),
    theta: 0.6,
    standardError: 0.7,
    estimatedIQ: 109,
    percentile: 73,
    abilityLevel: '평균 이상',
    averageDifficulty: QuestionDifficulty.normal,
    averageElapsedSeconds: 12,
    questionCount: 5,
  );
}
