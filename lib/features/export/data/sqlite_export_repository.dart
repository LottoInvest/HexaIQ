import 'package:sqflite/sqflite.dart';

import '../../../core/persistence/hexa_iq_database.dart';
import '../domain/report_exporter.dart';

class SQLiteExportRepository {
  const SQLiteExportRepository(this.database);

  final HexaIQDatabase database;

  Future<void> save(ExportedReport report) async {
    final db = await database.open();
    await db.insert('export_jobs', {
      'id': report.fileName,
      'format': report.format.name,
      'created_at': report.createdAt.toIso8601String(),
      'payload': report.content,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ExportedReport>> loadAll() async {
    final db = await database.open();
    final rows = await db.query('export_jobs', orderBy: 'created_at DESC');
    return [
      for (final row in rows)
        ExportedReport(
          format: ReportExportFormat.values.byName(row['format'] as String),
          fileName: row['id'] as String,
          content: row['payload'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
        ),
    ];
  }
}
