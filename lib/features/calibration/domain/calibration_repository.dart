import 'calibration_profile.dart';

abstract class CalibrationRepository {
  Future<CalibrationProfile?> load(String itemId);
  Future<List<CalibrationProfile>> loadAll();
  Future<void> save(CalibrationProfile profile);
  Future<void> clear();
}

class InMemoryCalibrationRepository implements CalibrationRepository {
  final Map<String, CalibrationProfile> _profiles = {};

  @override
  Future<CalibrationProfile?> load(String itemId) async => _profiles[itemId];

  @override
  Future<List<CalibrationProfile>> loadAll() async => _profiles.values.toList();

  @override
  Future<void> save(CalibrationProfile profile) async {
    _profiles[profile.itemId] = profile;
  }

  @override
  Future<void> clear() async {
    _profiles.clear();
  }
}
