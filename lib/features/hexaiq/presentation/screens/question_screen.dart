import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_routes.dart';
import '../../domain/hexaiq_models.dart';
import '../state/hexaiq_app_state.dart';

class QuestionScreen extends StatelessWidget {
  const QuestionScreen({super.key});

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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            LinearProgressIndicator(value: state.testProgress),
            const SizedBox(height: 16),
            Text(
              '문항 ${state.questionIndex + 1} / ${state.questions.length}',
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
        ),
      ),
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
