import '../../../../core/domain/intelligence_domain.dart';
import '../../../../core/domain/question_difficulty.dart';
import '../../question_engine/core/generator_factory.dart';
import '../../question_engine/domain/question_engine_models.dart';
import '../domain/item.dart';
import 'item_bank_repository.dart';

class InMemoryItemBankRepository implements ItemBankRepository {
  InMemoryItemBankRepository({GeneratorFactory? generatorFactory})
    : _generatorFactory = generatorFactory ?? GeneratorFactory();

  final GeneratorFactory _generatorFactory;
  List<Item>? _items;

  @override
  List<Item> load() {
    _items ??= _buildMockItems();
    return List.unmodifiable(_items!);
  }

  @override
  void save(List<Item> items) {
    _items = List.unmodifiable(items);
  }

  @override
  List<Item> findByDomain(IntelligenceDomain domain) {
    return load().where((item) => item.domain == domain).toList();
  }

  @override
  List<Item> findByDifficulty(QuestionDifficulty difficulty) {
    return load().where((item) => item.difficulty == difficulty).toList();
  }

  @override
  List<Item> findByTag(String tag) {
    return load().where((item) => item.tags.contains(tag)).toList();
  }

  @override
  List<Item> findCandidates({
    required IntelligenceDomain domain,
    required QuestionDifficulty difficulty,
  }) {
    return findByDomain(domain);
  }

  List<Item> _buildMockItems() {
    final createdAt = DateTime.utc(2026, 1);
    return [
      for (final domain in IntelligenceDomain.values)
        for (var index = 0; index < 20; index++)
          _buildItem(
            domain: domain,
            index: index,
            difficulty: QuestionDifficulty
                .values[index % QuestionDifficulty.values.length],
            createdAt: createdAt,
          ),
    ];
  }

  Item _buildItem({
    required IntelligenceDomain domain,
    required int index,
    required QuestionDifficulty difficulty,
    required DateTime createdAt,
  }) {
    final generator = _generatorFactory.generatorFor(domain);
    final typeCode = generator.supportedTypeCodes
        .toList()[index % generator.supportedTypeCodes.length];
    final seed = 100000 + domain.index * 1000 + index * 17;
    final generated = generator.generate(
      GenerateQuestionRequest(
        profileId: 'item-bank',
        testId: 'item-bank-${domain.name}',
        domain: domain,
        ageGroup: 'grade5_6',
        index: index,
        typeCode: typeCode,
        level: 5,
        seed: seed,
        difficulty: difficulty,
      ),
    );
    return Item.fromGeneratedQuestion(
      generated,
      id: '${domain.generatorPrefix}-${(index + 1).toString().padLeft(3, '0')}',
      now: createdAt,
    );
  }
}
