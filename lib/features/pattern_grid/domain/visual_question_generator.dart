import 'dart:math';

import 'pattern_cell.dart';
import 'pattern_generator.dart';
import 'visual_question.dart';

class VisualQuestionGenerator {
  const VisualQuestionGenerator();

  VisualQuestion generate({
    required int seed,
    PatternRule rule = PatternRule.rotation,
    QuestionLayout layout = QuestionLayout.matrix,
    int size = 3,
    String packId = 'basic',
  }) {
    final random = Random(seed);
    final grid = PatternGrid.square(
      size: size.clamp(2, 5),
      cells: [
        for (
          var index = 0;
          index < size.clamp(2, 5) * size.clamp(2, 5);
          index++
        )
          PatternCell(
            element: _elementFor(index + seed),
            color:
                PatternColor.values[random.nextInt(PatternColor.values.length)],
            rotation: (random.nextInt(4) * 90).toDouble(),
            scale: 0.8 + random.nextDouble() * 0.4,
            highlighted:
                rule == PatternRule.missingBlock && index == seed.abs() % 9,
          ),
      ],
    );
    final generated = const PatternGenerator().question(
      seed: seed,
      rule: rule,
      size: size,
    );
    return VisualQuestion(
      id: 'VQ-${seed.abs()}-${rule.name}',
      type: layout.name,
      layout: layout,
      rule: rule,
      grid: grid,
      choices: generated.choices,
      answerIndex: generated.answerIndex,
      prompt: const PatternGenerator().promptFor(rule),
      packId: packId,
    );
  }

  PatternElement _elementFor(int seed) {
    return switch (seed % 5) {
      0 => ShapeElement(PatternShape.values[seed % PatternShape.values.length]),
      1 => const IconElement('psychology'),
      2 => const EmojiElement('🎲'),
      3 => const SvgElement('assets/patterns/shapes/sample_shape.svg'),
      _ => const IconElement('bolt'),
    };
  }
}
