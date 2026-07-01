import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../export/domain/pdf_export_service.dart';
import '../../hexaiq/presentation/state/hexaiq_app_state.dart';

class SamplePdfPreviewScreen extends StatelessWidget {
  const SamplePdfPreviewScreen({super.key});

  static const _pdfService = PdfExportService();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HexaIQAppState>();
    final preview = _pdfService.samplePreview(status: state.purchaseStatus);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(preview.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Stack(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HexaIQ 전문 리포트',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        const Text('추정 IQ 124'),
                        const Text('상위 비율 5%'),
                        const SizedBox(height: 16),
                        Container(
                          height: 160,
                          width: double.infinity,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: Icon(
                            Icons.hexagon_outlined,
                            size: 72,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(preview.content),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          icon: const Icon(Icons.download),
                          label: Text(
                            preview.canSave ? 'PDF 저장' : '구매 후 저장 가능',
                          ),
                          onPressed: preview.canSave ? () {} : null,
                        ),
                      ],
                    ),
                  ),
                ),
                if (preview.hasWatermark)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: Transform.rotate(
                          angle: -0.5,
                          child: Text(
                            '미리보기',
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.18,
                                  ),
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
