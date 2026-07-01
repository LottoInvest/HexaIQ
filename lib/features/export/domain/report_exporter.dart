import 'dart:convert';

import '../../hexaiq/domain/hexaiq_models.dart';

enum ReportExportFormat { json, csv }

class ExportedReport {
  const ExportedReport({
    required this.format,
    required this.fileName,
    required this.content,
    required this.createdAt,
  });

  final ReportExportFormat format;
  final String fileName;
  final String content;
  final DateTime createdAt;
}

class ReportExporter {
  const ReportExporter();

  ExportedReport export({
    required ReportExportFormat format,
    required TestResultSummary result,
  }) {
    final createdAt = DateTime.now();
    final fileName = 'hexaiq_${result.id}.${format.name}';
    return ExportedReport(
      format: format,
      fileName: fileName,
      content: switch (format) {
        ReportExportFormat.json => _toJson(result),
        ReportExportFormat.csv => _toCsv(result),
      },
      createdAt: createdAt,
    );
  }

  String _toJson(TestResultSummary result) {
    return const JsonEncoder.withIndent('  ').convert({
      'id': result.id,
      'profileId': result.profileId,
      'completedAt': result.completedAt.toIso8601String(),
      'theta': result.theta,
      'standardError': result.standardError,
      'estimatedIQ': result.estimatedIQ,
      'percentile': result.percentile,
      'abilityLevel': result.abilityLevel,
      'averageDifficulty': result.averageDifficulty.name,
      'averageElapsedSeconds': result.averageElapsedSeconds,
      'questionCount': result.questionCount,
    });
  }

  String _toCsv(TestResultSummary result) {
    const headers = [
      'id',
      'profile_id',
      'completed_at',
      'theta',
      'standard_error',
      'estimated_iq',
      'percentile',
      'ability_level',
      'average_difficulty',
      'average_elapsed_seconds',
      'question_count',
    ];
    final values = [
      result.id,
      result.profileId,
      result.completedAt.toIso8601String(),
      result.theta.toStringAsFixed(4),
      result.standardError.toStringAsFixed(4),
      '${result.estimatedIQ}',
      '${result.percentile}',
      result.abilityLevel,
      result.averageDifficulty.name,
      '${result.averageElapsedSeconds}',
      '${result.questionCount}',
    ];
    return '${headers.join(',')}\n${values.map(_escapeCsv).join(',')}';
  }

  String _escapeCsv(String value) {
    if (!value.contains(',') && !value.contains('"') && !value.contains('\n')) {
      return value;
    }
    return '"${value.replaceAll('"', '""')}"';
  }
}
