enum AnalyticsEventType {
  testStarted,
  questionViewed,
  answerSelected,
  questionSkipped,
  hintViewed,
  memoOpened,
  adStarted,
  adCompleted,
  testCompleted,
  resultViewed,
  pdfGenerated,
  paymentStarted,
  paymentCompleted,
  paymentFailed,
}

extension AnalyticsEventTypeName on AnalyticsEventType {
  String get eventName {
    return switch (this) {
      AnalyticsEventType.testStarted => 'test_started',
      AnalyticsEventType.questionViewed => 'question_viewed',
      AnalyticsEventType.answerSelected => 'answer_selected',
      AnalyticsEventType.questionSkipped => 'question_skipped',
      AnalyticsEventType.hintViewed => 'hint_viewed',
      AnalyticsEventType.memoOpened => 'memo_opened',
      AnalyticsEventType.adStarted => 'ad_started',
      AnalyticsEventType.adCompleted => 'ad_completed',
      AnalyticsEventType.testCompleted => 'test_completed',
      AnalyticsEventType.resultViewed => 'result_viewed',
      AnalyticsEventType.pdfGenerated => 'pdf_generated',
      AnalyticsEventType.paymentStarted => 'payment_started',
      AnalyticsEventType.paymentCompleted => 'payment_completed',
      AnalyticsEventType.paymentFailed => 'payment_failed',
    };
  }
}

class AnalyticsEvent {
  const AnalyticsEvent({
    required this.type,
    required this.timestamp,
    this.properties = const {},
  });

  final AnalyticsEventType type;
  final DateTime timestamp;
  final Map<String, Object?> properties;

  Map<String, Object?> toJson() {
    return {
      'event': type.eventName,
      'timestamp': timestamp.toIso8601String(),
      'properties': sanitizedProperties,
    };
  }

  Map<String, Object?> get sanitizedProperties {
    return {
      for (final entry in properties.entries)
        if (!_isSensitiveKey(entry.key)) entry.key: entry.value,
    };
  }

  static bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase();
    return normalized.contains('memo') ||
        normalized.contains('name') ||
        normalized.contains('email') ||
        normalized.contains('token') ||
        normalized.contains('card') ||
        normalized.contains('paymentinfo');
  }
}

abstract class AnalyticsService {
  void record(
    AnalyticsEventType type, {
    Map<String, Object?> properties = const {},
  });
}

class InMemoryAnalyticsService implements AnalyticsService {
  final List<AnalyticsEvent> _events = [];

  @override
  void record(
    AnalyticsEventType type, {
    Map<String, Object?> properties = const {},
  }) {
    _events.add(
      AnalyticsEvent(
        type: type,
        timestamp: DateTime.now(),
        properties: properties,
      ),
    );
  }

  List<AnalyticsEvent> get events => List.unmodifiable(_events);

  List<Map<String, Object?>> get payloads {
    return [for (final event in _events) event.toJson()];
  }
}
