import '../../../../core/domain/intelligence_domain.dart';
import '../../../../core/domain/question_difficulty.dart';
import '../domain/item.dart';

abstract class ItemBankRepository {
  List<Item> load();

  void save(List<Item> items);

  List<Item> findByDomain(IntelligenceDomain domain);

  List<Item> findByDifficulty(QuestionDifficulty difficulty);

  List<Item> findByTag(String tag);

  List<Item> findCandidates({
    required IntelligenceDomain domain,
    required QuestionDifficulty difficulty,
  });
}
