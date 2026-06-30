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
      if (!mounted) {
        return;
      }
      setState(() {
        _displaySeconds = _stopwatch.elapsed.inSeconds;
      });
    });
  }

  void _startHintTimer() {
    _hintTimer?.cancel();
    _showHint = false;
    _hintTimer = Timer(widget.hintDelay, () {
      if (!mounted) {
        return;
      }
      setState(() => _showHint = true);
    });
  }

  void _recordElapsed(HexaIQAppState state, {bool restartHint = true}) {
    final seconds = _stopwatch.elapsed.inSeconds;
    state.recordElapsedTime(seconds);
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
            final shortestSide = size.shortestSide;
            final isTablet = shortestSide >= 600;
            final isPhoneLandscape = isLandscape && !isTablet;
            final showSplitLayout = isPhoneLandscape || isTablet;
            final showScratchPad =
                question.domain == IntelligenceDomain.numerical ||
                _scratchPadConfig.isEnabledFor(question.typeCode);
            final isCompactPortrait =
                !isLandscape && constraints.maxHeight < 760;
            final compact = isPhoneLandscape || isCompactPortrait;
            final hint = _hintFor(question);
            final content = _QuestionContent(
              state: state,
              question: question,
              hint: _showHint ? hint : null,
              displaySeconds: _displaySeconds,
              compact: compact,
              useChoiceGrid: isPhoneLandscape,
              isTablet: isTablet,
              scrollable: true,
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
              final horizontalPadding = isPhoneLandscape ? 8.0 : 16.0;
              final gap = isPhoneLandscape ? 8.0 : 16.0;
              return Padding(
                padding: EdgeInsets.all(horizontalPadding),
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
    if (question.hint != null && question.hint!.trim().isNotEmpty) {
      return question.hint!;
    }
    return switch (question.typeCode) {
      'NR01' => '등차수열 문제입니다. 차이를 비교해보세요.',
      'NR02' => '등비수열 문제입니다. 곱해지는 비율을 찾아보세요.',
      'NR15' || 'NR16' => '각 행과 열의 규칙을 나누어 비교해보세요.',
      'NR17' => '마방진 합계 힌트입니다. 한 줄의 합을 먼저 확인해보세요.',
      'NR20' => '숫자 관계 힌트입니다. 왼쪽과 오른쪽 수의 연결을 찾아보세요.',
      _ => '문제 유형의 규칙을 먼저 찾고, 보기와 하나씩 비교해보세요.',
    };
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
    required this.scrollable,
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
  final bool scrollable;
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
                'Question ${state.questionIndex + 1} / ${state.totalQuestionCount}',
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
              label: const Text('Previous'),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: isLastQuestion ? onSubmit : onNext,
              icon: Icon(isLastQuestion ? Icons.check : Icons.chevron_right),
              label: Text(isLastQuestion ? 'Submit' : 'Next'),
            ),
          ],
        ),
      ],
    );
  }

  String _formatElapsed(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '${minutes}m ${remaining.toString().padLeft(2, '0')}s';
  }
}

class _ScrollableQuestionBody extends StatelessWidget {
  const _ScrollableQuestionBody({
    required this.question,
    required this.selectedAnswer,
    required this.compact,
    required this.useChoiceGrid,
    required this.isTablet,
    required this.onSelectAnswer,
  });

  final TestQuestion question;
  final int? selectedAnswer;
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
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Text(question.prompt, style: promptStyle),
        SizedBox(height: compact ? 10 : 18),
        if (useChoiceGrid)
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
