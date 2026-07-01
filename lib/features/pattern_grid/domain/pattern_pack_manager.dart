import 'dart:convert';

import 'package:flutter/services.dart';

import '../../hexaiq/domain/hexaiq_models.dart';
import 'pattern_difficulty.dart';
import 'pattern_json_parser.dart';
import 'pattern_pack_manifest.dart';
import 'visual_question.dart';

enum PatternPackType { basic, advanced, professional, kids, senior }

class PatternPack {
  const PatternPack({required this.manifest, required this.questions});

  final PatternPackManifest manifest;
  final List<VisualQuestion> questions;

  String get id => manifest.packId;

  PatternPackType get type {
    return PatternPackType.values.firstWhere(
      (value) => value.name == manifest.target,
      orElse: () => PatternPackType.basic,
    );
  }
}

class PatternPackManager {
  PatternPackManager({this.parser = const PatternJsonParser()});

  final PatternJsonParser parser;
  List<PatternPack> _packs = const [];

  static const defaultPackPaths = [
    'assets/pattern_packs/basic_pack',
    'assets/pattern_packs/kids_pack',
    'assets/pattern_packs/advanced_pack',
    'assets/pattern_packs/professional_pack',
  ];

  Future<List<PatternPack>> loadPacks({
    AssetBundle? bundle,
    List<String> packPaths = defaultPackPaths,
  }) async {
    final assetBundle = bundle ?? rootBundle;
    final packs = <PatternPack>[];
    for (final path in packPaths) {
      try {
        final manifestJson =
            jsonDecode(await assetBundle.loadString('$path/manifest.json'))
                as Map<String, Object?>;
        final questionsJson =
            jsonDecode(await assetBundle.loadString('$path/questions.json'))
                as List<Object?>;
        final manifest = PatternPackManifest.fromJson(manifestJson);
        if (!manifest.enabled) {
          continue;
        }
        packs.add(
          PatternPack(
            manifest: manifest,
            questions: [
              for (final raw in questionsJson)
                if (raw is Map<String, Object?>)
                  parser.parseMap(raw, id: '${manifest.packId}_question'),
            ],
          ),
        );
      } catch (_) {
        continue;
      }
    }
    _packs = _dedupePacks(packs);
    return _packs;
  }

  List<VisualQuestion> getQuestionsByTestType(
    TestType type, {
    bool hasPremium = false,
  }) {
    final allowedTargets = switch (type) {
      TestType.quickIq => {'kids', 'basic'},
      TestType.basic => {'basic'},
      TestType.advanced => {'basic', 'advanced'},
      TestType.professional => {'advanced', 'professional'},
    };
    return [
      for (final pack in _packs)
        if (allowedTargets.contains(pack.manifest.target) &&
            (!pack.manifest.requiresPremium || hasPremium))
          ...pack.questions.where(
            (question) => !question.premiumOnly || hasPremium,
          ),
    ];
  }

  List<VisualQuestion> getQuestionsByDifficulty(
    PatternDifficulty difficulty, {
    bool hasPremium = false,
  }) {
    return [
      for (final pack in _packs)
        if (!pack.manifest.requiresPremium || hasPremium)
          ...pack.questions.where(
            (question) => question.difficulty == difficulty,
          ),
    ];
  }

  PatternPack loadFromJsonList({
    required String id,
    required PatternPackType type,
    required List<Map<String, Object?>> items,
    PatternPackManifest? manifest,
  }) {
    final pack = PatternPack(
      manifest:
          manifest ??
          PatternPackManifest(
            packId: id,
            name: id,
            version: '1.0.0',
            target: type.name,
            difficultyRange: const [PatternDifficulty.normal],
            questionCount: items.length,
            supportedElements: const ['shape', 'icon', 'emoji', 'svg', 'image'],
            requiresPremium: type == PatternPackType.professional,
          ),
      questions: [
        for (var index = 0; index < items.length; index++)
          parser.parseMap(items[index], id: '$id-$index'),
      ],
    );
    _packs = _dedupePacks([..._packs, pack]);
    return pack;
  }

  List<PatternPack> get loadedPacks => _packs;

  List<PatternPack> _dedupePacks(List<PatternPack> packs) {
    final seenPackVersions = <String>{};
    final seenQuestions = <String>{};
    final result = <PatternPack>[];
    for (final pack in packs) {
      final versionKey = '${pack.id}:${pack.manifest.version}';
      if (!seenPackVersions.add(versionKey)) {
        continue;
      }
      final questions = <VisualQuestion>[];
      for (final question in pack.questions) {
        if (seenQuestions.add(question.id)) {
          questions.add(question);
        }
      }
      result.add(PatternPack(manifest: pack.manifest, questions: questions));
    }
    return result;
  }
}
