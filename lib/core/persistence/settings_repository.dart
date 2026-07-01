import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'hexa_iq_database.dart';

abstract class SettingsRepository {
  Future<ThemeMode> loadThemeMode();
  Future<void> saveThemeMode(ThemeMode mode);
}

class InMemorySettingsRepository implements SettingsRepository {
  ThemeMode themeMode;

  InMemorySettingsRepository({this.themeMode = ThemeMode.dark});

  @override
  Future<ThemeMode> loadThemeMode() async => themeMode;

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    themeMode = mode;
  }
}

class SQLiteSettingsRepository implements SettingsRepository {
  const SQLiteSettingsRepository(this.database);

  final HexaIQDatabase database;

  @override
  Future<ThemeMode> loadThemeMode() async {
    final db = await database.open();
    final rows = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['theme_mode'],
      limit: 1,
    );
    if (rows.isEmpty) {
      return ThemeMode.dark;
    }
    return switch (rows.single['value'] as String) {
      'system' => ThemeMode.system,
      'light' => ThemeMode.light,
      _ => ThemeMode.dark,
    };
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    final db = await database.open();
    await db.insert('settings', {
      'key': 'theme_mode',
      'value': mode.name,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
