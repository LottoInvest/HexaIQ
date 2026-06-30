import '../domain/exposure_status.dart';

abstract class ExposureRepository {
  ExposureStatus load(String itemId);

  ExposureStatus update(
    String itemId, {
    bool? correct,
    Duration? responseTime,
    DateTime? usedAt,
  });

  void clear();

  List<ExposureStatus> statistics();
}
