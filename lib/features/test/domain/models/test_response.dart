class TestResponse {
  const TestResponse({
    required this.itemId,
    required this.domain,
    required this.selectedIndex,
    required this.isCorrect,
    required this.elapsedMs,
  });

  final String itemId;
  final String domain;
  final int selectedIndex;
  final bool isCorrect;
  final int elapsedMs;

  Map<String, Object?> toJson() {
    return {
      'itemId': itemId,
      'domain': domain,
      'selectedIndex': selectedIndex,
      'isCorrect': isCorrect,
      'elapsedMs': elapsedMs,
    };
  }

  factory TestResponse.fromJson(Map<String, Object?> json) {
    return TestResponse(
      itemId: json['itemId'] as String,
      domain: json['domain'] as String,
      selectedIndex: json['selectedIndex'] as int,
      isCorrect: json['isCorrect'] as bool,
      elapsedMs: json['elapsedMs'] as int,
    );
  }
}
