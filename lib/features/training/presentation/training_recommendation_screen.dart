import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/domain/intelligence_domain.dart';
import '../../../core/domain/question_difficulty.dart';
import '../../../core/responsive/responsive_page.dart';
import '../../hexaiq/presentation/state/hexaiq_app_state.dart';
import '../../hexaiq/presentation/widgets/dashboard_nav.dart';
import '../../question_engine/core/question_engine.dart';
import '../../question_engine/domain/question_engine_models.dart';
import '../domain/ai_training_engine.dart';
import '../domain/training_result.dart';

enum _TrainingStage { setup, practice, result }

class TrainingRecommendationScreen extends StatefulWidget {
  const TrainingRecommendationScreen({super.key});

  @override
  State<TrainingRecommendationScreen> createState() =>
      _TrainingRecommendationScreenState();
}

class _TrainingRecommendationScreenState
    extends State<TrainingRecommendationScreen> {
  static const _engine = AITrainingEngine();
  static final _questionEngine = QuestionEngine();

  _TrainingStage _stage = _TrainingStage.setup;
  final Set<IntelligenceDomain> _selectedDomains = {
    IntelligenceDomain.numerical,
  };
  QuestionDifficulty _selectedDifficulty = QuestionDifficulty.normal;
  int _questionCount = 10;
  List<_TrainingQuestion> _questions = const [];
  int _index = 0;
  int? _selectedAnswer;
  bool _showHint = false;
  bool _checked = false;
  final Set<String> _hintUsedQuestionIds = {};
  final Map<String, int> _answers = {};
  DateTime? _startedAt;
  DateTime? _completedAt;

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      title: '맞춤 훈련',
      currentIndex: 2,
      onDestinationSelected: (index) =>
          handleDashboardDestination(context, index),
      child: switch (_stage) {
        _TrainingStage.setup => _SetupView(
          selectedDomains: _selectedDomains,
          selectedDifficulty: _selectedDifficulty,
          questionCount: _questionCount,
          recommendations: _recommendations(context),
          onToggleDomain: _toggleDomain,
          onSelectDifficulty: (difficulty) =>
              setState(() => _selectedDifficulty = difficulty),
          onSelectQuestionCount: (count) =>
              setState(() => _questionCount = count),
          onUseWeakDomains: () => _useWeakDomains(context),
          onStart: () => _startTraining(context),
        ),
        _TrainingStage.practice => _PracticeView(
          question: _questions[_index],
          index: _index,
          total: _questions.length,
          selectedAnswer: _selectedAnswer,
          showHint: _showHint,
          checked: _checked,
          onSelect: (answer) {
            if (_checked) {
              return;
            }
            setState(() => _selectedAnswer = answer);
          },
          onShowHint: () {
            setState(() {
              _showHint = true;
              _hintUsedQuestionIds.add(_questions[_index].id);
            });
          },
          onCheck: _selectedAnswer == null
              ? null
              : () {
                  setState(() {
                    _checked = true;
                    _answers[_questions[_index].id] = _selectedAnswer!;
                  });
                },
          onNext: _goNext,
        ),
        _TrainingStage.result => _TrainingResultView(
          domains: _selectedDomains.toList(growable: false),
          difficulty: _selectedDifficulty,
          total: _questions.length,
          correct: _correctCount,
          hintUsed: _hintUsedQuestionIds.length,
          wrongQuestions: _wrongQuestions,
          elapsed: _elapsed,
          onRestart: () => _startTraining(context),
          onRetryWrong: _wrongQuestions.isEmpty ? null : _retryWrongOnly,
          onChangeSetup: () => setState(() => _stage = _TrainingStage.setup),
        ),
      },
    );
  }

  List<TrainingRecommendation> _recommendations(BuildContext context) {
    final state = context.watch<HexaIQAppState>();
    return _engine.recommend(report: state.report, limit: 3);
  }

  int get _correctCount {
    return _questions.where((question) {
      return _answers[question.id] == question.answerIndex;
    }).length;
  }

  List<_TrainingQuestion> get _wrongQuestions {
    return _questions
        .where((question) {
          final answer = _answers[question.id];
          return answer != null && answer != question.answerIndex;
        })
        .toList(growable: false);
  }

  Duration get _elapsed {
    final started = _startedAt;
    final completed = _completedAt;
    if (started == null || completed == null) {
      return Duration.zero;
    }
    return completed.difference(started);
  }

  void _toggleDomain(IntelligenceDomain domain) {
    setState(() {
      if (_selectedDomains.contains(domain)) {
        if (_selectedDomains.length > 1) {
          _selectedDomains.remove(domain);
        }
      } else {
        _selectedDomains.add(domain);
      }
    });
  }

  void _useWeakDomains(BuildContext context) {
    final report = context.read<HexaIQAppState>().report;
    final entries =
        report?.domainResults.entries
            .where((entry) => entry.value.totalCount > 0)
            .toList() ??
        const [];
    if (entries.isEmpty) {
      setState(() {
        _selectedDomains
          ..clear()
          ..addAll({IntelligenceDomain.numerical, IntelligenceDomain.spatial});
      });
      return;
    }
    entries.sort((a, b) => a.value.accuracy.compareTo(b.value.accuracy));
    setState(() {
      _selectedDomains
        ..clear()
        ..addAll(entries.take(2).map((entry) => entry.key));
    });
  }

  void _startTraining(BuildContext context) {
    final state = context.read<HexaIQAppState>();
    final profile = state.selectedProfile;
    final domains = _selectedDomains.toList(growable: false)
      ..sort((a, b) => a.index.compareTo(b.index));
    final now = DateTime.now();
    final generated = _generateQuestions(
      domains: domains,
      count: _questionCount,
      difficulty: _selectedDifficulty,
      profileId: profile?.id ?? 'training-profile',
      ageGroup: profile?.ageGroup ?? 'adult',
      baseSeed: now.millisecondsSinceEpoch & 0x7fffffff,
    );

    setState(() {
      _questions = generated;
      _index = 0;
      _selectedAnswer = null;
      _showHint = false;
      _checked = false;
      _answers.clear();
      _hintUsedQuestionIds.clear();
      _startedAt = now;
      _completedAt = null;
      _stage = _TrainingStage.practice;
    });
  }

  List<_TrainingQuestion> _generateQuestions({
    required List<IntelligenceDomain> domains,
    required int count,
    required QuestionDifficulty difficulty,
    required String profileId,
    required String ageGroup,
    required int baseSeed,
  }) {
    final allocation = _allocateQuestions(domains: domains, count: count);
    final questions = <_TrainingQuestion>[];
    var globalIndex = 0;
    for (final domain in domains) {
      final domainCount = allocation[domain] ?? 0;
      for (var localIndex = 0; localIndex < domainCount; localIndex++) {
        final dto = _questionEngine.generateOne(
          seed: baseSeed + domain.index * 7919 + localIndex * 1009,
          domain: domain,
          difficulty: difficulty,
          profileId: profileId,
          testId: 'training-$baseSeed',
          ageGroup: ageGroup,
          index: globalIndex,
          level: difficulty.level * 2,
        );
        questions.add(_TrainingQuestion.fromDto(dto));
        globalIndex += 1;
      }
    }
    questions.shuffle();
    return questions;
  }

  Map<IntelligenceDomain, int> _allocateQuestions({
    required List<IntelligenceDomain> domains,
    required int count,
  }) {
    final safeCount = count.clamp(1, 60);
    final allocation = {for (final domain in domains) domain: 0};
    var remaining = safeCount;
    for (final domain in domains) {
      if (remaining <= 0) {
        break;
      }
      allocation[domain] = 1;
      remaining -= 1;
    }
    var index = 0;
    while (remaining > 0) {
      final domain = domains[index % domains.length];
      allocation[domain] = (allocation[domain] ?? 0) + 1;
      remaining -= 1;
      index += 1;
    }
    return allocation;
  }

  void _goNext() {
    if (_index >= _questions.length - 1) {
      final completedAt = DateTime.now();
      setState(() {
        _completedAt = completedAt;
        _stage = _TrainingStage.result;
      });
      unawaited(_saveTrainingResult(completedAt));
      return;
    }
    setState(() {
      _index += 1;
      _selectedAnswer = null;
      _showHint = false;
      _checked = false;
    });
  }

  Future<void> _saveTrainingResult(DateTime completedAt) async {
    final state = context.read<HexaIQAppState>();
    final profile = state.selectedProfile;
    if (profile == null) {
      return;
    }
    final domains = _selectedDomains.toList(growable: false)
      ..sort((a, b) => a.index.compareTo(b.index));
    await state.repository.saveTrainingResult(
      TrainingResult(
        id: 'training-${completedAt.millisecondsSinceEpoch}',
        profileId: profile.id,
        selectedDomains: domains,
        selectedDifficulty: _selectedDifficulty,
        questionCount: _questions.length,
        correctCount: _correctCount,
        completedAt: completedAt,
      ),
    );
  }

  void _retryWrongOnly() {
    final wrong = _wrongQuestions;
    if (wrong.isEmpty) {
      return;
    }
    setState(() {
      _questions = wrong;
      _index = 0;
      _selectedAnswer = null;
      _showHint = false;
      _checked = false;
      _answers.clear();
      _hintUsedQuestionIds.clear();
      _startedAt = DateTime.now();
      _completedAt = null;
      _stage = _TrainingStage.practice;
    });
  }
}

class _SetupView extends StatelessWidget {
  const _SetupView({
    required this.selectedDomains,
    required this.selectedDifficulty,
    required this.questionCount,
    required this.recommendations,
    required this.onToggleDomain,
    required this.onSelectDifficulty,
    required this.onSelectQuestionCount,
    required this.onUseWeakDomains,
    required this.onStart,
  });

  final Set<IntelligenceDomain> selectedDomains;
  final QuestionDifficulty selectedDifficulty;
  final int questionCount;
  final List<TrainingRecommendation> recommendations;
  final ValueChanged<IntelligenceDomain> onToggleDomain;
  final ValueChanged<QuestionDifficulty> onSelectDifficulty;
  final ValueChanged<int> onSelectQuestionCount;
  final VoidCallback onUseWeakDomains;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('훈련 영역 선택', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final domain in IntelligenceDomain.values)
                      FilterChip(
                        label: Text(domain.label),
                        selected: selectedDomains.contains(domain),
                        onSelected: (_) => onToggleDomain(domain),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('취약 영역 자동 추천'),
                  onPressed: onUseWeakDomains,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('훈련 수준', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in const [
                      QuestionDifficulty.easy,
                      QuestionDifficulty.normal,
                      QuestionDifficulty.hard,
                      QuestionDifficulty.veryHard,
                    ])
                      ChoiceChip(
                        label: Text(_trainingDifficultyLabel(option)),
                        selected: selectedDifficulty == option,
                        onSelected: (_) => onSelectDifficulty(option),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('문항 수', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final count in const [5, 10, 15, 30])
                      ChoiceChip(
                        label: Text('$count문항'),
                        selected: questionCount == count,
                        onSelected: (_) => onSelectQuestionCount(count),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (recommendations.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('추천 훈련', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final item in recommendations.take(3))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.psychology_outlined),
                      title: Text(item.title),
                      subtitle: Text(item.reason),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.play_arrow),
          label: const Text('훈련 시작'),
          onPressed: selectedDomains.isEmpty ? null : onStart,
        ),
      ],
    );
  }
}

class _PracticeView extends StatelessWidget {
  const _PracticeView({
    required this.question,
    required this.index,
    required this.total,
    required this.selectedAnswer,
    required this.showHint,
    required this.checked,
    required this.onSelect,
    required this.onShowHint,
    required this.onCheck,
    required this.onNext,
  });

  final _TrainingQuestion question;
  final int index;
  final int total;
  final int? selectedAnswer;
  final bool showHint;
  final bool checked;
  final ValueChanged<int> onSelect;
  final VoidCallback onShowHint;
  final VoidCallback? onCheck;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCorrect =
        checked &&
        selectedAnswer != null &&
        selectedAnswer == question.answerIndex;
    return ListView(
      children: [
        LinearProgressIndicator(value: (index + 1) / total),
        const SizedBox(height: 12),
        Text(
          '${index + 1} / $total · ${question.domain.label} · ${question.difficulty.labelKo}',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(question.question, style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                for (var i = 0; i < question.choices.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: checked ? null : () => onSelect(i),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selectedAnswer == i
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                          ),
                          color: checked && i == question.answerIndex
                              ? theme.colorScheme.primaryContainer
                              : checked && i == selectedAnswer
                              ? theme.colorScheme.errorContainer
                              : selectedAnswer == i
                              ? theme.colorScheme.secondaryContainer
                              : null,
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              selectedAnswer == i
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(question.choices[i])),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                if (showHint)
                  Card(
                    color: theme.colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(question.hint),
                    ),
                  ),
                if (checked) ...[
                  const SizedBox(height: 8),
                  Card(
                    color: isCorrect
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isCorrect ? '정답입니다.' : '오답입니다.'),
                          const SizedBox(height: 6),
                          Text('정답: ${question.choices[question.answerIndex]}'),
                          const SizedBox(height: 6),
                          Text('해설: ${question.explanation}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.lightbulb_outline),
                label: const Text('힌트 보기'),
                onPressed: showHint ? null : onShowHint,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                icon: Icon(checked ? Icons.navigate_next : Icons.check),
                label: Text(checked ? '다음 문제' : '정답 확인'),
                onPressed: checked ? onNext : onCheck,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrainingResultView extends StatelessWidget {
  const _TrainingResultView({
    required this.domains,
    required this.difficulty,
    required this.total,
    required this.correct,
    required this.hintUsed,
    required this.wrongQuestions,
    required this.elapsed,
    required this.onRestart,
    required this.onRetryWrong,
    required this.onChangeSetup,
  });

  final List<IntelligenceDomain> domains;
  final QuestionDifficulty difficulty;
  final int total;
  final int correct;
  final int hintUsed;
  final List<_TrainingQuestion> wrongQuestions;
  final Duration elapsed;
  final VoidCallback onRestart;
  final VoidCallback? onRetryWrong;
  final VoidCallback onChangeSetup;

  @override
  Widget build(BuildContext context) {
    final accuracy = total == 0 ? 0 : (correct / total * 100).round();
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('훈련 결과', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text(
                  '훈련 영역: ${domains.map((domain) => domain.label).join(', ')}',
                ),
                Text('훈련 수준: ${_trainingDifficultyLabel(difficulty)}'),
                Text('총 문항 수: $total문항'),
                Text('정답: $correct / $total'),
                Text('정답률: $accuracy%'),
                Text('힌트 사용: $hintUsed문항'),
                Text('오답: ${wrongQuestions.length}문항'),
                Text('풀이 시간: ${minutes}분 ${seconds}초'),
                const SizedBox(height: 12),
                const Text('훈련 결과는 IQ와 상위 비율로 표시하지 않습니다.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (wrongQuestions.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('오답 문항', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final question in wrongQuestions)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(question.question),
                      subtitle: Text(
                        '정답: ${question.choices[question.answerIndex]}',
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          icon: const Icon(Icons.replay),
          label: const Text('다시 풀기'),
          onPressed: onRestart,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('오답만 다시 풀기'),
          onPressed: onRetryWrong,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.tune),
          label: const Text('다른 조건으로 훈련하기'),
          onPressed: onChangeSetup,
        ),
      ],
    );
  }
}

class _TrainingQuestion {
  const _TrainingQuestion({
    required this.id,
    required this.domain,
    required this.difficulty,
    required this.question,
    required this.choices,
    required this.answerIndex,
    required this.hint,
    required this.explanation,
  });

  factory _TrainingQuestion.fromDto(GeneratedQuestionDto dto) {
    return _TrainingQuestion(
      id: dto.id,
      domain: dto.domain,
      difficulty: dto.difficulty,
      question: dto.question,
      choices: dto.choices,
      answerIndex: dto.answerIndex,
      hint: dto.hint?.trim().isNotEmpty == true
          ? dto.hint!
          : '문제의 규칙을 먼저 찾고 보기와 하나씩 비교해 보세요.',
      explanation: dto.solutionExplanation.trim().isNotEmpty
          ? dto.solutionExplanation
          : dto.explanation,
    );
  }

  final String id;
  final IntelligenceDomain domain;
  final QuestionDifficulty difficulty;
  final String question;
  final List<String> choices;
  final int answerIndex;
  final String hint;
  final String explanation;
}

String _trainingDifficultyLabel(QuestionDifficulty difficulty) {
  return switch (difficulty) {
    QuestionDifficulty.easy => '기초',
    QuestionDifficulty.normal => '표준',
    QuestionDifficulty.hard => '심화',
    QuestionDifficulty.veryHard => '도전',
    QuestionDifficulty.veryEasy => '기초',
  };
}
