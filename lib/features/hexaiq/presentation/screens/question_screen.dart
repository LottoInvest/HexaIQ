import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_routes.dart';
import '../../../question/widgets/scratch_pad_widget.dart';
import '../../domain/hexaiq_models.dart';
import '../state/hexaiq_app_state.dart';

class QuestionScreen extends StatelessWidget {
  const QuestionScreen({super.key});

  static const _scratchPadConfig = ScratchPadConfig();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HexaIQAppState>();
    final question = state.currentQuestion;
    if (question == null) {
      return const DomainCompleteScreenRedirect();
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

            if (showSplitLayout && showScratchPad) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _QuestionContent(state: state, question: question),
                    ),
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
                _QuestionContent(state: state, question: question),
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
  const _QuestionContent({required this.state, required this.question});

  final HexaIQAppState state;
  final TestQuestion question;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        LinearProgressIndicator(value: state.testProgress),
        const SizedBox(height: 16),
        Text(
          'Question ${state.questionIndex + 1} / ${state.questions.length}',
          style: Theme.of(context).textTheme.labelLarge,
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
                    child: OutlinedButton(
                      onPressed: () {
                        final result = context
                            .read<HexaIQAppState>()
                            .submitAnswer(i);
                        if (result == SubmitResult.domainComplete) {
                          Navigator.of(
                            context,
                          ).pushReplacementNamed(AppRoutes.domainComplete);
                        }
                      },
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
      ],
    );
  }
}

class DomainCompleteScreenRedirect extends StatelessWidget {
  const DomainCompleteScreenRedirect({super.key});

  @override
  Widget build(BuildContext context) {
    Future<void>.microtask(() {
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.domainComplete);
      }
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
