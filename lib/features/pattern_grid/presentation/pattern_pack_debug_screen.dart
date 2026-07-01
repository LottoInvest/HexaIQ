import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../domain/pattern_difficulty.dart';
import '../domain/pattern_pack_runtime.dart';
import '../domain/pattern_question_validator.dart';

class PatternPackDebugScreen extends StatelessWidget {
  PatternPackDebugScreen({
    super.key,
    PatternPackRuntime? runtime,
    this.validator = const PatternQuestionValidator(),
  }) : runtime = runtime ?? PatternPackRuntime();

  final PatternPackRuntime runtime;
  final PatternQuestionValidator validator;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(body: SizedBox.shrink());
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Pattern Pack Debug')),
      body: FutureBuilder(
        future: runtime.load(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final result = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Loaded packs: ${result.packs.length}'),
              Text('Valid questions: ${result.validQuestions.length}'),
              Text('Invalid questions: ${result.invalidQuestions.length}'),
              const SizedBox(height: 16),
              for (final pack in result.packs)
                Card(
                  child: ExpansionTile(
                    title: Text('${pack.manifest.name} (${pack.id})'),
                    subtitle: Text(
                      'v${pack.manifest.version} · ${pack.questions.length} questions',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Difficulty: ${_difficultySummary(pack.questions)}',
                            ),
                            Text(
                              'Elements: ${_elementSummary(pack.questions)}',
                            ),
                            const SizedBox(height: 8),
                            for (final question in pack.questions.take(5))
                              Text(validator.validate(question).debugLog()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _difficultySummary(Iterable<dynamic> questions) {
    final counts = {
      for (final difficulty in PatternDifficulty.values) difficulty.name: 0,
    };
    for (final question in questions) {
      final name = question.difficulty?.name ?? 'normal';
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return counts.entries
        .map((entry) => '${entry.key}:${entry.value}')
        .join(' ');
  }

  String _elementSummary(Iterable<dynamic> questions) {
    final counts = <String, int>{};
    for (final question in questions) {
      for (final cell in question.grid.cells) {
        counts[cell.element.type] = (counts[cell.element.type] ?? 0) + 1;
      }
    }
    return counts.entries
        .map((entry) => '${entry.key}:${entry.value}')
        .join(' ');
  }
}
