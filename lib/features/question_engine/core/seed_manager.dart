import '../domain/question_engine_models.dart';

class SeedManager {
  final Set<String> _usedKeys = <String>{};
  final Set<String> _usedSignatures = <String>{};

  int createSeed({
    required String profileId,
    required String testId,
    required QuestionDomain domain,
    required String typeCode,
    required int index,
    int retry = 0,
  }) {
    final raw = '$profileId:$testId:${domain.name}:$typeCode:$index:$retry';
    return _stableHash(raw) & 0x7fffffff;
  }

  int nextUniqueSeed({
    required String profileId,
    required String testId,
    required QuestionDomain domain,
    required String typeCode,
    required int index,
  }) {
    for (var retry = 0; retry < 20; retry++) {
      final seed = createSeed(
        profileId: profileId,
        testId: testId,
        domain: domain,
        typeCode: typeCode,
        index: index,
        retry: retry,
      );
      final key = duplicateKey(
        profileId: profileId,
        typeCode: typeCode,
        seed: seed,
      );
      if (!_usedKeys.contains(key)) {
        _usedKeys.add(key);
        return seed;
      }
    }
    throw StateError('Unable to create unique seed for $typeCode.');
  }

  bool registerSignature({
    required String profileId,
    required String question,
    required String answer,
  }) {
    final signature = '$profileId:${_stableHash('$question:$answer')}';
    if (_usedSignatures.contains(signature)) {
      return false;
    }
    _usedSignatures.add(signature);
    return true;
  }

  String duplicateKey({
    required String profileId,
    required String typeCode,
    required int seed,
  }) {
    return '$profileId:$typeCode:$seed';
  }

  int _stableHash(String input) {
    var hash = 0x811c9dc5;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }
}
