import '../../../../core/domain/intelligence_domain.dart';
import 'item_generator.dart';
import 'math_logic_item_generator.dart';
import 'memory_item_generator.dart';
import 'reasoning_item_generator.dart';
import 'spatial_item_generator.dart';
import 'speed_item_generator.dart';
import 'verbal_item_generator.dart';
import '../models/test_item.dart';
import '../models/test_mode.dart';

class MultiDomainItemEngine {
  const MultiDomainItemEngine({
    this.numerical = const MathLogicItemGenerator(),
    this.verbal = const VerbalItemGenerator(),
    this.spatial = const SpatialItemGenerator(),
    this.memory = const MemoryItemGenerator(),
    this.logic = const ReasoningItemGenerator(),
    this.processing = const SpeedItemGenerator(),
  });

  final ItemGenerator numerical;
  final ItemGenerator verbal;
  final ItemGenerator spatial;
  final ItemGenerator memory;
  final ItemGenerator logic;
  final ItemGenerator processing;

  static const allDomains = [
    IntelligenceDomain.numerical,
    IntelligenceDomain.verbal,
    IntelligenceDomain.spatial,
    IntelligenceDomain.memory,
    IntelligenceDomain.logic,
    IntelligenceDomain.processing,
  ];
  static const domains = allDomains;

  List<TestItem> generate({
    required TestMode mode,
    IntelligenceDomain domain = IntelligenceDomain.numerical,
    int? count,
  }) {
    return switch (mode) {
      TestMode.quickIq =>
        count == null
            ? generateQuickIq()
            : generateQuickIq(
                domains: allDomains,
                perDomain: (count / allDomains.length).ceil(),
              ).take(count).toList(growable: false),
      TestMode.fullDiagnostic => generateFullDiagnostic(count: count ?? 30),
      TestMode.domainTraining => generateDomainTraining(
        domain: domain,
        count: count ?? 10,
      ),
    };
  }

  List<TestItem> generateQuickIq({
    List<IntelligenceDomain> domains = allDomains,
    int perDomain = 10,
  }) {
    final difficulties = difficultyPlan(domains.length * perDomain);
    return _generateBalanced(
      domains: domains,
      perDomain: perDomain,
      difficulties: difficulties,
      idSuffix: 'Q',
    );
  }

  List<TestItem> generateFullDiagnostic({int count = 30}) {
    final normalizedCount = count.clamp(30, 120).toInt();
    final perDomain = (normalizedCount / allDomains.length).ceil();
    final items = _generateBalanced(
      domains: allDomains,
      perDomain: perDomain,
      difficulties: difficultyPlan(perDomain * domains.length),
      idSuffix: 'F',
    );
    return items.take(normalizedCount).toList(growable: false);
  }

  List<TestItem> generateDomainTraining({
    required IntelligenceDomain domain,
    int count = 10,
  }) {
    final difficulties = difficultyPlan(count.clamp(1, 60).toInt());
    return [
      for (var index = 0; index < difficulties.length; index++)
        _generatorFor(domain)
            .generate(count: index + 1, targetDifficulty: difficulties[index])
            .last,
    ];
  }

  List<TestItem> generateItems({
    required IntelligenceDomain domain,
    required double difficulty,
    required int count,
    Set<String> excludedItems = const {},
  }) {
    final generated = _generatorFor(domain).generate(
      count: count + excludedItems.length,
      targetDifficulty: difficulty,
    );
    final available = generated
        .where((item) => !excludedItems.contains(item.id))
        .toList(growable: false);
    return available.take(count).toList(growable: false);
  }

  static List<double> difficultyPlan(int count) {
    if (count <= 0) {
      return const [];
    }
    final easy = (count * 0.3).round();
    final medium = (count * 0.4).round();
    final hard = count - easy - medium;
    return [
      for (var i = 0; i < easy; i++) 0.3,
      for (var i = 0; i < medium; i++) 0.55,
      for (var i = 0; i < hard; i++) 0.82,
    ];
  }

  List<TestItem> _generateBalanced({
    required List<IntelligenceDomain> domains,
    required int perDomain,
    required List<double> difficulties,
    required String idSuffix,
  }) {
    final items = <TestItem>[];
    var difficultyIndex = 0;
    for (final domain in domains) {
      for (var index = 0; index < perDomain; index++) {
        final difficulty = difficulties[difficultyIndex % difficulties.length];
        final generated = _generatorFor(
          domain,
        ).generate(count: index + 1, targetDifficulty: difficulty).last;
        items.add(_withUniqueId(generated, '${generated.id}-$idSuffix-$index'));
        difficultyIndex += 1;
      }
    }
    return items;
  }

  ItemGenerator _generatorFor(IntelligenceDomain domain) {
    return switch (domain) {
      IntelligenceDomain.numerical => numerical,
      IntelligenceDomain.verbal => verbal,
      IntelligenceDomain.spatial => spatial,
      IntelligenceDomain.memory => memory,
      IntelligenceDomain.logic => logic,
      IntelligenceDomain.processing => processing,
    };
  }

  TestItem _withUniqueId(TestItem item, String id) {
    return item.copyWith(id: id);
  }
}
