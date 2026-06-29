import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_routes.dart';
import '../../../question/widgets/scratch_pad_widget.dart';
import '../../domain/hexaiq_models.dart';
import '../state/hexaiq_app_state.dart';

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  static const _scratchPadConfig = ScratchPadConfig();

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
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _displaySeconds = _stopwatch.elapsed.inSeconds;
      });
    });
  }

  void _recordElapsed(HexaIQAppState state) {
    final seconds = _stopwatch.elapsed.inSeconds;
    state.recordElapsedTime(seconds);
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
            final showSplitLayout = constraints.maxWidth >= 700;
            final showScratchPad = _scratchPadConfig.isEnabledFor(
              question.typeCode,
            );
            final content = _QuestionContent(
              state: state,
              question: question,
              displaySeconds: _displaySeconds,
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
                _recordElapsed(appState);
                await appState.submitTest();
                if (context.mounted) {
                  Navigator.of(
                    context,
                  ).pushReplacementNamed(AppRoutes.reportSummary);
                }
              },
            );

            if (showSplitLayout && showScratchPad) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 3, child: content),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ScratchPadWidget(resetToken: question.id),
                    ),
                  ],
                ),
              );
            }

            final scratchHeight = (constraints.maxHeight * 0.3).clamp(
              180.0,
              280.0,
            );
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                content,
                if (showScratchPad) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: scratchHeight,
                    child: ScratchPadWidget(resetToken: question.id),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QuestionContent extends StatelessWidget {
  const _QuestionContent({
    required this.state,
    required this.question,
    required this.displaySeconds,
    required this.onSelectAnswer,
    required this.onNext,
    required this.onSubmit,
    this.onPrevious,
  });

  final HexaIQAppState state;
  final TestQuestion question;
  final int displaySeconds;
  final ValueChanged<int> onSelectAnswer;
  final VoidCallback? onPrevious;
  final VoidCallback onNext;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final selectedAnswer = state.selectedAnswerForCurrentQuestion;
    final progressPercent = (state.testProgress * 100).round();
    final isLastQuestion = state.isLastQuestion;
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        LinearProgressIndicator(value: state.testProgress),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Question ${state.questionIndex + 1} / ${state.questions.length}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            Text('$progressPercent%'),
            const SizedBox(width: 12),
            Text(_formatElapsed(displaySeconds)),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.prompt,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                for (var i = 0; i < question.choices.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: selectedAnswer == i
                        ? FilledButton(
                            onPressed: () => onSelectAnswer(i),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(question.choices[i]),
                            ),
                          )
                        : OutlinedButton(
                            onPressed: () => onSelectAnswer(i),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(question.choices[i]),
                            ),
                          ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
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
