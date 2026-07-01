import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/core/persistence/hexa_iq_database.dart';
import 'package:hexaiq_app/features/ads/presentation/mock_ad_dialog.dart';
import 'package:hexaiq_app/features/export/domain/pdf_export_service.dart';
import 'package:hexaiq_app/features/hexaiq/data/mock_hexaiq_repository.dart';
import 'package:hexaiq_app/features/hexaiq/domain/hexaiq_models.dart';
import 'package:hexaiq_app/features/hexaiq/presentation/state/hexaiq_app_state.dart';
import 'package:hexaiq_app/features/payment/domain/purchase_status.dart';
import 'package:hexaiq_app/features/test/application/test_flow_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  const flow = TestFlowController();

  setUpAll(() {
    sqfliteFfiInit();
  });

  test('v1.0.3 test modes expose stable question counts', () {
    expect(flow.targetQuestionCount(TestType.basic), 30);
    expect(flow.targetQuestionCount(TestType.quickIq), 60);
    expect(flow.targetQuestionCount(TestType.advanced), 90);
    expect(flow.questionsPerDomain(TestType.basic), 5);
    expect(flow.questionsPerDomain(TestType.quickIq), 10);
    expect(flow.questionsPerDomain(TestType.advanced), 15);
  });

  test('ad policy excludes Basic and keeps Quick/Advanced checkpoints', () {
    expect(flow.totalAdCount(TestType.basic, professionalPurchased: false), 0);
    expect(
      flow.totalAdCount(TestType.quickIq, professionalPurchased: false),
      2,
    );
    expect(
      flow.totalAdCount(TestType.advanced, professionalPurchased: false),
      3,
    );
    expect(
      flow.totalAdCount(TestType.professional, professionalPurchased: true),
      0,
    );
    expect(
      flow.shouldShowMidAd(type: TestType.quickIq, completedQuestionCount: 30),
      isTrue,
    );
    expect(
      flow.shouldShowMidAd(type: TestType.advanced, completedQuestionCount: 30),
      isTrue,
    );
    expect(
      flow.shouldShowMidAd(type: TestType.advanced, completedQuestionCount: 60),
      isTrue,
    );
  });

  test(
    'AppState consumes Advanced mid ads only after 2 and 4 domains',
    () async {
      final state = HexaIQAppState(repository: MockHexaIQRepository());
      await state.loadInitialData();
      state.selectTestType(TestType.advanced);
      await state.startTest();

      expect(state.totalQuestionCount, 90);
      for (var index = 0; index < 29; index++) {
        state.selectAnswer(state.currentQuestion!.answerIndex);
        state.nextQuestion();
      }
      state.selectAnswer(state.currentQuestion!.answerIndex);
      expect(state.consumeMidAdBreakForCurrentQuestion(), isTrue);
      expect(state.consumeMidAdBreakForCurrentQuestion(), isFalse);
    },
  );

  test('Purchase status persists in local SQLite settings', () async {
    final database = HexaIQDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    final repository = MockHexaIQRepository(database: database);

    expect(await repository.loadPurchaseStatus(), PurchaseStatus.free);
    await repository.savePurchaseStatus(PurchaseStatus.professionalPurchased);
    expect(
      await repository.loadPurchaseStatus(),
      PurchaseStatus.professionalPurchased,
    );
    await database.close();
  });

  test('PDF preview is watermarked before purchase and exportable after', () {
    const service = PdfExportService();

    final free = service.samplePreview(status: PurchaseStatus.free);
    final purchased = service.samplePreview(
      status: PurchaseStatus.professionalPurchased,
    );

    expect(free.hasWatermark, isTrue);
    expect(free.canSave, isFalse);
    expect(purchased.hasWatermark, isFalse);
    expect(purchased.canSave, isTrue);
    expect(service.canExportPdf(PurchaseStatus.professionalPurchased), isTrue);
  });

  testWidgets('MockAdDialog closes automatically after countdown', (
    tester,
  ) async {
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (context) => const MockAdDialog(
                  title: '광고',
                  message: '자동 종료',
                  countdown: Duration(seconds: 1),
                ),
              );
              completed = result == true;
            },
            child: const Text('show'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();
    expect(find.textContaining('잠시 후 검사 결과가 이어집니다.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(find.textContaining('잠시 후 검사 결과가 이어집니다.'), findsNothing);
  });
}
