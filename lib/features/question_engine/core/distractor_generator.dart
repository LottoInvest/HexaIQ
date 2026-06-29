import 'dart:math';

class DistractorGenerator {
  const DistractorGenerator();

  List<String> numericChoices(
    int answer,
    List<int> candidates,
    Random rng, {
    int minValue = 0,
  }) {
    final values = <int>[answer];
    for (final value in candidates) {
      if (value >= minValue && value != answer && !values.contains(value)) {
        values.add(value);
      }
    }
    var delta = 1;
    while (values.length < 4) {
      for (final candidate in [answer - delta, answer + delta]) {
        if (candidate >= minValue &&
            candidate != answer &&
            !values.contains(candidate)) {
          values.add(candidate);
        }
        if (values.length == 4) {
          break;
        }
      }
      delta++;
    }
    final selected = values.take(4).map((value) => '$value').toList();
    selected.shuffle(rng);
    return selected;
  }

  List<String> textChoices(String answer, List<String> candidates, Random rng) {
    final values = <String>[answer];
    for (final value in candidates) {
      if (value != answer && !values.contains(value)) {
        values.add(value);
      }
    }
    const fallback = ['보기 A', '보기 B', '보기 C', '보기 D', '보기 E'];
    for (final value in fallback) {
      if (values.length >= 4) {
        break;
      }
      if (!values.contains(value)) {
        values.add(value);
      }
    }
    return values.take(4).toList()..shuffle(rng);
  }
}
