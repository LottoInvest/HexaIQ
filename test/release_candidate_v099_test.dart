import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/app/app_config.dart';
import 'package:hexaiq_app/app/version_info.dart';
import 'package:hexaiq_app/features/ads/domain/ad_checkpoint_manager.dart';
import 'package:hexaiq_app/features/analytics/domain/analytics_service.dart';
import 'package:hexaiq_app/features/export/domain/pdf_export_service.dart';
import 'package:hexaiq_app/features/hexaiq/domain/hexaiq_models.dart';
import 'package:hexaiq_app/features/pattern_grid/domain/pattern_pack_integrity_checker.dart';
import 'package:hexaiq_app/features/pattern_grid/domain/pattern_pack_manager.dart';
import 'package:hexaiq_app/features/payment/domain/purchase_status.dart';
import 'package:hexaiq_app/features/test/application/state_persistence_service.dart';
import 'package:hexaiq_app/features/test/application/test_flow_controller.dart';
import 'package:hexaiq_app/features/test/domain/models/test_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('v1.0.1 QA Stabilization', () {
    test('version info exposes stabilization metadata', () {
      expect(VersionInfo.current.version, '1.0.1');
      expect(VersionInfo.current.buildName, '1.0.1');
      expect(AppConfig.current.isReleaseCandidate, isFalse);
      expect(VersionInfo.current.releaseName, 'QA Stabilization Build');
    });

    test(
      'professional pattern pack loads and passes integrity checks',
      () async {
        final manager = PatternPackManager();
        final packs = await manager.loadPacks();
        final report = const PatternPackIntegrityChecker().checkPacks(packs);

        expect(packs.map((pack) => pack.id), contains('professional_pack'));
        expect(report.invalidQuestionCount, 0);
        expect(report.duplicateQuestionIds, isEmpty);
        expect(report.isReadyForRelease, isTrue);
        expect(
          manager
              .getQuestionsByTestType(TestType.professional)
              .where((question) => question.packId == 'professional_pack'),
          isEmpty,
        );
        expect(
          manager.getQuestionsByTestType(
            TestType.professional,
            hasPremium: true,
          ),
          isNotEmpty,
        );
      },
    );

    test('ad checkpoints prevent duplicate mid and result ads', () {
      const manager = AdCheckpointManager();
      var state = const AdCheckpointState();

      expect(
        manager.shouldShowMidAd(
          type: TestType.quickIq,
          completedDomainCount: 3,
          state: state,
        ),
        isTrue,
      );
      state = state.recordMidAd(TestType.quickIq, 3);
      expect(
        manager.shouldShowMidAd(
          type: TestType.quickIq,
          completedDomainCount: 3,
          state: state,
        ),
        isFalse,
      );

      expect(
        manager.shouldShowResultAd(
          type: TestType.advanced,
          professionalPurchased: false,
          state: state,
        ),
        isTrue,
      );
      state = state.recordResultAd().recordResultAd();
      expect(
        manager.shouldShowResultAd(
          type: TestType.advanced,
          professionalPurchased: false,
          state: state,
        ),
        isFalse,
      );
      expect(
        const TestFlowController().shouldShowMidAd(
          type: TestType.quickIq,
          completedQuestionCount: 30,
        ),
        isTrue,
      );
    });

    test('state snapshot keeps question index, answers, and elapsed time', () {
      final session = TestSession(
        sessionId: 'session-101',
        startedAt: DateTime(2026, 7, 1),
        currentQuestionIndex: 5,
        selectedAnswers: const {'q1': 2, 'q2': 1},
        elapsedSeconds: const {'q1': 8, 'q2': 12},
        usedItemIds: const {'q1', 'q2'},
      );

      final service = const StatePersistenceService();
      final snapshot = service.snapshot(
        session,
        adCheckpointState: 'quickIq:3',
        paymentState: 'free',
        savedAt: DateTime(2026, 7, 1, 12),
      );
      final restored = TestSessionSnapshot.fromJson(snapshot.toJson());
      final applied = service.applySnapshot(session.copyWith(), restored);

      expect(service.canResume(restored), isTrue);
      expect(restored.currentQuestionIndex, 5);
      expect(restored.selectedAnswers['q1'], 2);
      expect(restored.elapsedSeconds['q2'], 12);
      expect(applied.usedItemIds, contains('q2'));
    });

    test('analytics events remove memo, personal, and payment fields', () {
      final service = InMemoryAnalyticsService();
      service.record(
        AnalyticsEventType.answerSelected,
        properties: const {
          'questionId': 'basic_shape_rotation_001',
          'memoContent': 'private memo',
          'email': 'user@example.com',
          'paymentToken': 'secret',
          'isCorrect': true,
        },
      );

      final properties = service.payloads.single['properties'] as Map;
      expect(properties['questionId'], 'basic_shape_rotation_001');
      expect(properties['isCorrect'], isTrue);
      expect(properties.containsKey('memoContent'), isFalse);
      expect(properties.containsKey('email'), isFalse);
      expect(properties.containsKey('paymentToken'), isFalse);
    });

    test('payment lock and PDF preview stay consistent', () {
      const service = PdfExportService();
      final free = service.samplePreview(status: PurchaseStatus.free);
      final purchased = service.samplePreview(
        status: PurchaseStatus.professionalPurchased,
      );

      expect(PurchaseStatus.free.hasProfessionalAccess, isFalse);
      expect(
        PurchaseStatus.professionalPurchased.hasProfessionalAccess,
        isTrue,
      );
      expect(free.hasWatermark, isTrue);
      expect(free.canSave, isFalse);
      expect(purchased.hasWatermark, isFalse);
      expect(purchased.canSave, isTrue);
      expect(free.content, contains('상위 비율'));
    });
  });
}
