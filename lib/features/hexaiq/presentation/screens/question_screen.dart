import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/domain/intelligence_domain.dart';
import '../../../../core/domain/question_difficulty.dart';
import '../../../ads/domain/ad_service.dart';
import '../../../pattern_grid/domain/pattern_generator.dart';
import '../../../pattern_grid/presentation/pattern_question_widget.dart';
import '../../../question_layout/presentation/answer_choice_area.dart';
import '../../../question_layout/presentation/bottom_action_area.dart';
import '../../../question_layout/presentation/compact_progress_header.dart';
import '../../../question_layout/presentation/question_card.dart';
import '../../../question_layout/presentation/question_scroll_area.dart';
import '../../../question/widgets/memory_interaction.dart';
import '../../../question/widgets/spatial_canvas.dart';
import '../../../question/widgets/speed_test_screen.dart';
import '../../domain/hexaiq_models.dart';
import '../state/hexaiq_app_state.dart';

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({
    super.key,
    this.enableElapsedTimer = true,
    this.hintDelay = const Duration(seconds: 5),
  });

  final bool enableElapsedTimer;
  final Duration hintDelay;

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  static const AdService _adService = MockAdService();

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  int _displaySeconds = 0;
  String? _activeQuestionId;

  @override
  void initState() {
    super.initState();
    _startQuestionTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _startQuestionTimer() {
    _timer?.cancel();
    _displaySeconds = 0;
    _stopwatch
      ..reset()
      ..start();
    if (!widget.enableElapsedTimer) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _displaySeconds = _stopwatch.elapsed.inSeconds);
      }
    });
  }

  void _recordElapsed(HexaIQAppState state) {
    state.recordElapsedTime(_stopwatch.elapsed.inSeconds);
    _startQuestionTimer();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HexaIQAppState>();
    final question = state.currentQuestion;
    if (question == null) {
      return const DomainCompleteScreenRedirect();
    }
    if (_activeQuestionId != question.id) {
      _activeQuestionId = question.id;
      _startQuestionTimer();
    }

    return Scaffold(
      appBar: AppBar(title: Text(domainLabel(question.domain))),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = MediaQuery.of(context).size;
            final isLandscape = size.width > size.height;
            final isTablet = size.shortestSide >= 600;
            final isPhoneLandscape = isLandscape && !isTablet;
            final compact =
                isPhoneLandscape ||
                (!isLandscape && constraints.maxHeight < 760);
            final content = _QuestionContent(
              state: state,
              question: question,
              hint: null,
              displaySeconds: _displaySeconds,
              compact: compact,
              onSelectAnswer: (index) =>
                  context.read<HexaIQAppState>().selectAnswer(index),
              onPrevious: state.questionIndex == 0
                  ? null
                  : () {
                      final appState = context.read<HexaIQAppState>();
                      _recordElapsed(appState);
                      appState.previousQuestion();
                    },
              onNext: () async {
                final appState = context.read<HexaIQAppState>();
                _recordElapsed(appState);
                final shouldShowAd = appState
                    .consumeMidAdBreakForCurrentQuestion();
                appState.nextQuestion();
                if (shouldShowAd && context.mounted) {
                  await _adService.showInterstitialAd(context);
                }
              },
              onSubmit: () async {
                final appState = context.read<HexaIQAppState>();
                _recordElapsed(appState);
                final proceed = await _runSubmitAdFlow(context, appState);
                if (!proceed) {
                  return;
                }
                if (context.mounted) {
                  Navigator.of(
                    context,
                  ).pushReplacementNamed(AppRoutes.reportSummary);
                }
              },
            );

            return Padding(
              padding: EdgeInsets.all(compact ? 10 : 16),
              child: Column(children: [Expanded(child: content)]),
            );
          },
        ),
      ),
    );
  }

  Future<bool> _runSubmitAdFlow(
    BuildContext context,
    HexaIQAppState appState,
  ) async {
    await appState.submitTest();
    if (!context.mounted) {
      return false;
    }
    final adCount = switch (appState.selectedTestType) {
      TestType.basic => 0,
      TestType.quickIq => 1,
      TestType.advanced => 1,
      TestType.professional => 0,
    };
    for (var index = 0; index < adCount; index++) {
      if (!context.mounted) {
        return false;
      }
      final watched = await _adService.showRewardAd(context);
      if (!watched || !context.mounted) {
        return false;
      }
      await appState.completeRewardAd();
      if (!context.mounted) {
        return false;
      }
    }
    return true;
  }
}

class _QuestionContent extends StatelessWidget {
  const _QuestionContent({
    required this.state,
    required this.question,
    required this.displaySeconds,
    required this.compact,
    required this.onSelectAnswer,
    required this.onNext,
    required this.onSubmit,
    this.hint,
    this.onPrevious,
  });

  final HexaIQAppState state;
  final TestQuestion question;
  final String? hint;
  final int displaySeconds;
  final bool compact;
  final ValueChanged<int> onSelectAnswer;
  final VoidCallback? onPrevious;
  final Future<void> Function() onNext;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final selectedAnswer = state.selectedAnswerForCurrentQuestion;
    final progressPercent = (state.testProgress * 100).round();
    final isLastQuestion = state.isLastQuestion;
    final reference = _hasReferenceContent(question, displaySeconds)
        ? _QuestionReferenceBody(
            question: question,
            displaySeconds: displaySeconds,
            compact: compact,
          )
        : null;
    return Column(
      children: [
        LinearProgressIndicator(value: state.testProgress, minHeight: 3),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 8),
          child: CompactProgressHeader(
            questionNumber: state.questionIndex + 1,
            totalQuestions: state.totalQuestionCount,
            progressPercent: progressPercent,
            elapsedText: _formatElapsed(displaySeconds),
            difficultyLabel: question.difficulty.labelKo,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 8),
          child: _DomainProgressStrip(state: state, compact: compact),
        ),
        SizedBox(height: compact ? 6 : 10),
        QuestionScrollArea(
          children: [
            QuestionCard(
              prompt: _displayPromptFor(question, displaySeconds),
              reference: reference,
            ),
            AnswerChoiceArea.text(
              choices: question.choices,
              selectedIndex: selectedAnswer,
              onSelect: onSelectAnswer,
            ),
            if (hint != null) const SizedBox.shrink(),
          ],
        ),
        BottomActionArea(
          onPrevious: onPrevious,
          nextLabel: isLastQuestion ? '?쒖텧' : '?ㅼ쓬',
          onNext: isLastQuestion
              ? () => unawaited(onSubmit())
              : () => unawaited(onNext()),
        ),
      ],
    );
  }

  String _formatElapsed(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '$minutes분 ${remaining.toString().padLeft(2, '0')}초';
  }
}

String _displayPromptFor(TestQuestion question, int displaySeconds) {
  final memoryPrompt = _memoryPromptFor(question);
  if (_isMemoryPreview(question, displaySeconds) && memoryPrompt != null) {
    final remainingSeconds = _remainingMemorySeconds(question, displaySeconds);
    return '?ㅼ쓬 ??ぉ??$remainingSeconds珥??숈븞 湲곗뼲?섏꽭??\n$memoryPrompt';
  }
  return question.prompt;
}

String? _memoryPromptFor(TestQuestion question) {
  return question.stimulus ?? question.variables['memoryPrompt'] as String?;
}

int _memoryDurationSecondsFor(TestQuestion question) {
  return question.stimulusDuration?.inSeconds ??
      ((question.variables['memoryDurationMs'] as int?) ?? 3000) ~/ 1000;
}

bool _isMemoryPreview(TestQuestion question, int displaySeconds) {
  final memoryPrompt = _memoryPromptFor(question);
  return question.requiresMemoryPhase &&
      question.domain == IntelligenceDomain.memory &&
      memoryPrompt != null &&
      displaySeconds < _memoryDurationSecondsFor(question);
}

int _remainingMemorySeconds(TestQuestion question, int displaySeconds) {
  final durationSeconds = _memoryDurationSecondsFor(question);
  return (durationSeconds - displaySeconds).clamp(1, durationSeconds);
}

bool _hasReferenceContent(TestQuestion question, int displaySeconds) {
  final usesPattern = switch (question.domain) {
    IntelligenceDomain.spatial ||
    IntelligenceDomain.logic ||
    IntelligenceDomain.memory ||
    IntelligenceDomain.processing => true,
    IntelligenceDomain.numerical || IntelligenceDomain.verbal => false,
  };
  return usesPattern ||
      (question.domain == IntelligenceDomain.spatial &&
          question.variables['requiresCanvas'] == true) ||
      question.domain == IntelligenceDomain.processing ||
      _isMemoryPreview(question, displaySeconds);
}

class _DomainProgressStrip extends StatelessWidget {
  const _DomainProgressStrip({required this.state, required this.compact});

  final HexaIQAppState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final progress = state.domainProgress;
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (
            var index = 0;
            index < state.activeDomainSequence.length;
            index++
          )
            Padding(
              padding: EdgeInsets.only(right: compact ? 6 : 8),
              child: _DomainStepChip(
                index: index + 1,
                label: state.activeDomainSequence[index].shortLabel,
                status:
                    progress[state.activeDomainSequence[index]] ??
                    DomainProgressStatus.pending,
                colorScheme: colorScheme,
              ),
            ),
        ],
      ),
    );
  }
}

class _DomainStepChip extends StatelessWidget {
  const _DomainStepChip({
    required this.index,
    required this.label,
    required this.status,
    required this.colorScheme,
  });

  final int index;
  final String label;
  final DomainProgressStatus status;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final selected = status == DomainProgressStatus.current;
    final completed = status == DomainProgressStatus.completed;
    return Chip(
      avatar: completed
          ? Icon(Icons.check_circle, size: 18, color: colorScheme.primary)
          : CircleAvatar(
              child: Text('$index', style: const TextStyle(fontSize: 11)),
            ),
      label: Text(label),
      backgroundColor: selected
          ? colorScheme.primaryContainer
          : completed
          ? colorScheme.secondaryContainer
          : colorScheme.surfaceContainerHighest,
      side: BorderSide(
        color: selected ? colorScheme.primary : colorScheme.outlineVariant,
      ),
    );
  }
}

class _QuestionReferenceBody extends StatelessWidget {
  const _QuestionReferenceBody({
    required this.question,
    required this.displaySeconds,
    required this.compact,
  });

  final TestQuestion question;
  final int displaySeconds;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final memoryPrompt = _memoryPromptFor(question);
    final isMemoryPreview = _isMemoryPreview(question, displaySeconds);
    final remainingSeconds = _remainingMemorySeconds(question, displaySeconds);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_usesPatternGrid(question)) ...[
          PatternQuestionWidget(
            pattern: _patternFor(question),
            compact: compact,
            showChoices: false,
          ),
          SizedBox(height: compact ? 10 : 14),
        ],
        if (question.domain == IntelligenceDomain.spatial &&
            question.variables['requiresCanvas'] == true) ...[
          SpatialCanvas(pattern: _spatialPattern(question.prompt)),
          SizedBox(height: compact ? 10 : 14),
        ],
        if (question.domain == IntelligenceDomain.processing) ...[
          SpeedInteractionPanel(
            elapsedSeconds: displaySeconds,
            timeLimit: question.timeLimit,
          ),
          SizedBox(height: compact ? 10 : 14),
        ],
        if (isMemoryPreview) ...[
          MemoryInteraction(
            stimulus: memoryPrompt ?? '',
            remainingSeconds: remainingSeconds,
            isPreview: true,
          ),
          SizedBox(height: compact ? 10 : 14),
        ],
        if (isMemoryPreview && (memoryPrompt == null || memoryPrompt.isEmpty))
          Text(
            '?쒖떆 ??ぉ???щ씪吏???蹂닿린媛 ?쒖떆?⑸땲??',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
      ],
    );
  }

  String _spatialPattern(String prompt) {
    final symbols = RegExp(r'[?꿎뼹?졻뼞?녳뾿?년뼺?뗢뿈]').allMatches(prompt);
    final pattern = symbols.map((match) => match.group(0)!).join();
    if (pattern.isEmpty) {
      return '?꿎뼹?졻뼞';
    }
    final end = pattern.length > 8 ? 8 : pattern.length;
    return pattern.substring(0, end);
  }

  bool _usesPatternGrid(TestQuestion question) {
    return switch (question.domain) {
      IntelligenceDomain.spatial ||
      IntelligenceDomain.logic ||
      IntelligenceDomain.memory ||
      IntelligenceDomain.processing => true,
      IntelligenceDomain.numerical || IntelligenceDomain.verbal => false,
    };
  }

  PatternQuestionPattern _patternFor(TestQuestion question) {
    final rule = switch (question.domain) {
      IntelligenceDomain.spatial => PatternRule.rotation,
      IntelligenceDomain.logic => PatternRule.shape,
      IntelligenceDomain.memory => PatternRule.missingBlock,
      IntelligenceDomain.processing => PatternRule.color,
      IntelligenceDomain.numerical ||
      IntelligenceDomain.verbal => PatternRule.movement,
    };
    final size = switch (question.domain) {
      IntelligenceDomain.processing => 2,
      IntelligenceDomain.memory => 3,
      IntelligenceDomain.spatial || IntelligenceDomain.logic => 3,
      IntelligenceDomain.numerical || IntelligenceDomain.verbal => 3,
    };
    return const PatternGenerator().question(
      seed: question.seed == 0 ? question.id.hashCode : question.seed,
      rule: rule,
      size: size,
    );
  }
}

class DomainCompleteScreenRedirect extends StatelessWidget {
  const DomainCompleteScreenRedirect({super.key});

  @override
  Widget build(BuildContext context) {
    Future<void>.microtask(() {
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.reportSummary);
      }
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
