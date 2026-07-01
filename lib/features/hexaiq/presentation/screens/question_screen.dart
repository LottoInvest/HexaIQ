import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/domain/intelligence_domain.dart';
import '../../../../core/domain/question_difficulty.dart';
import '../../../question/widgets/scratch_pad_widget.dart';
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
  static const _scratchPadConfig = ScratchPadConfig();

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  Timer? _hintTimer;
  int _displaySeconds = 0;
  String? _activeQuestionId;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _startQuestionTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hintTimer?.cancel();
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

  void _startHintTimer() {
    _hintTimer?.cancel();
    _showHint = false;
    _hintTimer = Timer(widget.hintDelay, () {
      if (mounted) {
        setState(() => _showHint = true);
      }
    });
  }

  void _recordElapsed(HexaIQAppState state, {bool restartHint = true}) {
    state.recordElapsedTime(_stopwatch.elapsed.inSeconds);
    _startQuestionTimer();
    if (restartHint) {
      _startHintTimer();
    }
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
      _startHintTimer();
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
            final showSplitLayout = isPhoneLandscape || isTablet;
            final showScratchPad =
                question.domain == IntelligenceDomain.numerical ||
                _scratchPadConfig.isEnabledFor(question.typeCode);
            final compact =
                isPhoneLandscape ||
                (!isLandscape && constraints.maxHeight < 760);
            final content = _QuestionContent(
              state: state,
              question: question,
              hint: _showHint ? _hintFor(question) : null,
              displaySeconds: _displaySeconds,
              compact: compact,
              useChoiceGrid: isPhoneLandscape,
              isTablet: isTablet,
              onSelectAnswer: (index) =>
                  context.read<HexaIQAppState>().selectAnswer(index),
              onPrevious: state.questionIndex == 0
                  ? null
                  : () {
                      final appState = context.read<HexaIQAppState>();
                      _recordElapsed(appState);
                      appState.previousQuestion();
                    },
              onNext: () {
                final appState = context.read<HexaIQAppState>();
                _recordElapsed(appState);
                appState.nextQuestion();
              },
              onSubmit: () async {
                final appState = context.read<HexaIQAppState>();
                _hintTimer?.cancel();
                _recordElapsed(appState, restartHint: false);
                await appState.submitTest();
                if (context.mounted) {
                  Navigator.of(
                    context,
                  ).pushReplacementNamed(AppRoutes.reportSummary);
                }
              },
            );

            if (showSplitLayout && showScratchPad) {
              final gap = isPhoneLandscape ? 8.0 : 16.0;
              return Padding(
                padding: EdgeInsets.all(gap),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: isPhoneLandscape ? 7 : 3, child: content),
                    SizedBox(width: gap),
                    Expanded(
                      flex: isPhoneLandscape ? 3 : 2,
                      child: ScratchPadWidget(
                        resetToken: question.id,
                        compact: isPhoneLandscape,
                      ),
                    ),
                  ],
                ),
              );
            }

            final scratchMinHeight = constraints.maxHeight < 520
                ? constraints.maxHeight * 0.22
                : 160.0;
            final scratchHeight = (constraints.maxHeight * 0.3).clamp(
              scratchMinHeight,
              constraints.maxHeight * 0.34,
            );
            return Padding(
              padding: EdgeInsets.all(compact ? 10 : 16),
              child: Column(
                children: [
                  Expanded(flex: showScratchPad ? 64 : 1, child: content),
                  if (showScratchPad) ...[
                    SizedBox(height: compact ? 8 : 12),
                    SizedBox(
                      height: scratchHeight,
                      child: ScratchPadWidget(
                        resetToken: question.id,
                        compact: compact,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _hintFor(TestQuestion question) {
    final hint = question.hint?.trim();
    if (hint != null && hint.isNotEmpty) {
      return hint;
    }
    return fallbackHintForType(question.typeCode);
  }
}

class _QuestionContent extends StatelessWidget {
  const _QuestionContent({
    required this.state,
    required this.question,
    required this.displaySeconds,
    required this.compact,
    required this.useChoiceGrid,
    required this.isTablet,
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
  final bool useChoiceGrid;
  final bool isTablet;
  final ValueChanged<int> onSelectAnswer;
  final VoidCallback? onPrevious;
  final VoidCallback onNext;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final selectedAnswer = state.selectedAnswerForCurrentQuestion;
    final progressPercent = (state.testProgress * 100).round();
    final isLastQuestion = state.isLastQuestion;
    return Column(
      children: [
        LinearProgressIndicator(value: state.testProgress, minHeight: 3),
        SizedBox(height: compact ? 6 : 12),
        Row(
          children: [
            Expanded(
              child: Text(
                '문제 ${state.questionIndex + 1} / ${state.totalQuestionCount}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            Text('$progressPercent%'),
            const SizedBox(width: 10),
            Text(_formatElapsed(displaySeconds)),
            const SizedBox(width: 10),
            Text(question.difficulty.labelKo),
          ],
        ),
        SizedBox(height: compact ? 6 : 10),
        Expanded(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(compact ? 10 : 16),
              child: _ScrollableQuestionBody(
                question: question,
                selectedAnswer: selectedAnswer,
                displaySeconds: displaySeconds,
                compact: compact,
                useChoiceGrid: useChoiceGrid,
                isTablet: isTablet,
                onSelectAnswer: onSelectAnswer,
              ),
            ),
          ),
        ),
        if (hint != null) ...[
          SizedBox(height: compact ? 6 : 8),
          _HintBanner(hint: hint!, compact: compact),
        ],
        SizedBox(height: compact ? 6 : 10),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
              label: const Text('이전'),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: isLastQuestion ? onSubmit : onNext,
              icon: Icon(isLastQuestion ? Icons.check : Icons.chevron_right),
              label: Text(isLastQuestion ? '제출' : '다음'),
            ),
          ],
        ),
      ],
    );
  }

  String _formatElapsed(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '${minutes}분 ${remaining.toString().padLeft(2, '0')}초';
  }
}

class _ScrollableQuestionBody extends StatelessWidget {
  const _ScrollableQuestionBody({
    required this.question,
    required this.selectedAnswer,
    required this.displaySeconds,
    required this.compact,
    required this.useChoiceGrid,
    required this.isTablet,
    required this.onSelectAnswer,
  });

  final TestQuestion question;
  final int? selectedAnswer;
  final int displaySeconds;
  final bool compact;
  final bool useChoiceGrid;
  final bool isTablet;
  final ValueChanged<int> onSelectAnswer;

  @override
  Widget build(BuildContext context) {
    final promptStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontSize: compact ? 18 : 22,
      height: compact ? 1.15 : 1.35,
    );
    final memoryPrompt =
        question.stimulus ?? question.variables['memoryPrompt'] as String?;
    final memoryDurationSeconds =
        question.stimulusDuration?.inSeconds ??
        ((question.variables['memoryDurationMs'] as int?) ?? 3000) ~/ 1000;
    final isMemoryPreview =
        question.requiresMemoryPhase &&
        question.domain == IntelligenceDomain.memory &&
        memoryPrompt != null &&
        displaySeconds < memoryDurationSeconds;
    final remainingSeconds = (memoryDurationSeconds - displaySeconds).clamp(
      1,
      memoryDurationSeconds,
    );
    final prompt = isMemoryPreview
        ? '다음 항목을 $remainingSeconds초 동안 기억하세요.\n$memoryPrompt'
        : question.prompt;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Text(prompt, style: promptStyle),
        SizedBox(height: compact ? 10 : 18),
        if (isMemoryPreview)
          Text(
            '제시 항목이 사라진 뒤 보기가 나타납니다.',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else if (useChoiceGrid)
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 5.8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < question.choices.length; i++)
                _ChoiceButton(
                  text: question.choices[i],
                  selected: selectedAnswer == i,
                  compact: compact,
                  isTablet: isTablet,
                  onPressed: () => onSelectAnswer(i),
                ),
            ],
          )
        else
          for (var i = 0; i < question.choices.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: compact ? 6 : 10),
              child: _ChoiceButton(
                text: question.choices[i],
                selected: selectedAnswer == i,
                compact: compact,
                isTablet: isTablet,
                onPressed: () => onSelectAnswer(i),
              ),
            ),
      ],
    );
  }
}

class _HintBanner extends StatelessWidget {
  const _HintBanner({required this.hint, required this.compact});

  final String hint;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 7 : 9,
        ),
        child: Text(
          hint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: compact ? 12 : 13,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.text,
    required this.selected,
    required this.compact,
    required this.isTablet,
    required this.onPressed,
  });

  final String text;
  final bool selected;
  final bool compact;
  final bool isTablet;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fontSize = isTablet
        ? 20.0
        : compact
        ? 16.0
        : 18.0;
    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
    );
    final style = ButtonStyle(
      alignment: Alignment.center,
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      minimumSize: WidgetStatePropertyAll(Size(40, compact ? 40 : 52)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: compact ? 12 : 16, vertical: 8),
      ),
      side: WidgetStatePropertyAll(
        BorderSide(
          color: selected ? colorScheme.primary : colorScheme.outline,
          width: selected ? 2 : 1.2,
        ),
      ),
      textStyle: WidgetStatePropertyAll(textStyle),
    );
    final child = Align(
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      ),
    );
    if (selected) {
      return FilledButton(style: style, onPressed: onPressed, child: child);
    }
    return OutlinedButton(style: style, onPressed: onPressed, child: child);
  }
}

String fallbackHintForType(String typeCode) {
  return switch (typeCode) {
    'NR01' => '인접한 두 수의 차이를 비교해 보세요.',
    'NR02' => '앞 숫자에 같은 비율이 적용되는지 살펴보세요.',
    'NR08' || 'NR09' => '숫자가 일정한 규칙으로 빠르게 증가하는지 확인해 보세요.',
    'NR15' || 'NR16' => '각 행과 열의 관계를 차례로 살펴보세요.',
    'NR17' => '대각선이나 묶음 안에서 반복되는 합계를 찾아보세요.',
    'NR18' => '양쪽에 같은 연산을 적용해 미지수를 남겨 보세요.',
    'NR20' => '왼쪽과 오른쪽 수 사이의 연결 규칙을 비교해 보세요.',
    _ => '문제의 규칙을 먼저 찾고, 보기와 하나씩 비교해 보세요.',
  };
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
