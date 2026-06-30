import '../domain/exposure_status.dart';
import 'exposure_repository.dart';

class InMemoryExposureRepository implements ExposureRepository {
  final Map<String, ExposureStatus> _statuses = {};

  @override
  ExposureStatus load(String itemId) {
    return _statuses[itemId] ?? ExposureStatus(itemId: itemId);
  }

  @override
  ExposureStatus update(
    String itemId, {
    bool? correct,
    Duration? responseTime,
    DateTime? usedAt,
  }) {
    final current = load(itemId);
    final nextExposureCount = current.exposureCount + 1;
    final nextAverageTime = responseTime == null
        ? current.averageResponseTime
        : _average(
            current.averageResponseTime,
            current.exposureCount,
            responseTime,
          );
    final next = current.copyWith(
      exposureCount: nextExposureCount,
      correctCount: current.correctCount + (correct == true ? 1 : 0),
      wrongCount: current.wrongCount + (correct == false ? 1 : 0),
      averageResponseTime: nextAverageTime,
      lastUsed: usedAt ?? DateTime.now(),
    );
    _statuses[itemId] = next;
    return next;
  }

  @override
  void clear() {
    _statuses.clear();
  }

  @override
  List<ExposureStatus> statistics() {
    final values = _statuses.values.toList(growable: false);
    values.sort((a, b) {
      final countCompare = b.exposureCount.compareTo(a.exposureCount);
      if (countCompare != 0) {
        return countCompare;
      }
      return a.itemId.compareTo(b.itemId);
    });
    return values;
  }

  Duration _average(Duration current, int currentCount, Duration next) {
    if (currentCount <= 0) {
      return next;
    }
    final totalMicroseconds =
        current.inMicroseconds * currentCount + next.inMicroseconds;
    return Duration(
      microseconds: (totalMicroseconds / (currentCount + 1)).round(),
    );
  }
}
