import 'package:sqflite/sqflite.dart';

import '../../../core/persistence/hexa_iq_database.dart';
import '../domain/calibration_profile.dart';
import '../domain/calibration_repository.dart';

class SQLiteCalibrationRepository implements CalibrationRepository {
  const SQLiteCalibrationRepository(this.database);

  final HexaIQDatabase database;

  @override
  Future<CalibrationProfile?> load(String itemId) async {
    final db = await database.open();
    final rows = await db.query(
      'calibration_profiles',
      where: 'item_id = ?',
      whereArgs: [itemId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return CalibrationProfile.fromMap(rows.single);
  }

  @override
  Future<List<CalibrationProfile>> loadAll() async {
    final db = await database.open();
    final rows = await db.query('calibration_profiles', orderBy: 'item_id ASC');
    return rows.map(CalibrationProfile.fromMap).toList(growable: false);
  }

  @override
  Future<void> save(CalibrationProfile profile) async {
    final db = await database.open();
    await db.insert(
      'calibration_profiles',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> clear() async {
    final db = await database.open();
    await db.delete('calibration_profiles');
  }
}
