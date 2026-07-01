class TestItem {
  const TestItem({
    required this.id,
    required this.domain,
    required this.type,
    required this.question,
    required this.choices,
    required this.answerIndex,
    required this.difficulty,
    required this.discrimination,
    required this.guessing,
    required this.estimatedTime,
    required this.explanation,
    this.tags = const [],
    this.subCategory = '',
    this.version = 'v0.9.4',
    this.usageCount = 0,
    this.lastUsed,
  });

  final String id;
  final String domain;
  final String type;
  final String question;
  final List<String> choices;
  final int answerIndex;
  final double difficulty;
  final double discrimination;
  final double guessing;
  final int estimatedTime;
  final String explanation;
  final List<String> tags;
  final String subCategory;
  final String version;
  final int usageCount;
  final DateTime? lastUsed;

  String get itemId => id;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'domain': domain,
      'type': type,
      'question': question,
      'choices': choices,
      'answerIndex': answerIndex,
      'difficulty': difficulty,
      'discrimination': discrimination,
      'guessing': guessing,
      'estimatedTime': estimatedTime,
      'explanation': explanation,
      'tags': tags,
      'subCategory': subCategory,
      'version': version,
      'usageCount': usageCount,
      'lastUsed': lastUsed?.toIso8601String(),
    };
  }

  factory TestItem.fromJson(Map<String, Object?> json) {
    final lastUsedValue = json['lastUsed'];
    return TestItem(
      id: json['id'] as String,
      domain: json['domain'] as String,
      type: json['type'] as String,
      question: json['question'] as String,
      choices: (json['choices'] as List).cast<String>(),
      answerIndex: json['answerIndex'] as int,
      difficulty: (json['difficulty'] as num).toDouble(),
      discrimination: (json['discrimination'] as num).toDouble(),
      guessing: (json['guessing'] as num).toDouble(),
      estimatedTime: json['estimatedTime'] as int,
      explanation: json['explanation'] as String,
      tags: ((json['tags'] as List?) ?? const []).cast<String>(),
      subCategory: json['subCategory'] as String? ?? '',
      version: json['version'] as String? ?? 'v0.9.4',
      usageCount: json['usageCount'] as int? ?? 0,
      lastUsed: lastUsedValue is String
          ? DateTime.tryParse(lastUsedValue)
          : null,
    );
  }

  TestItem copyWith({
    String? id,
    String? domain,
    String? type,
    String? question,
    List<String>? choices,
    int? answerIndex,
    double? difficulty,
    double? discrimination,
    double? guessing,
    int? estimatedTime,
    String? explanation,
    List<String>? tags,
    String? subCategory,
    String? version,
    int? usageCount,
    DateTime? lastUsed,
  }) {
    return TestItem(
      id: id ?? this.id,
      domain: domain ?? this.domain,
      type: type ?? this.type,
      question: question ?? this.question,
      choices: choices ?? this.choices,
      answerIndex: answerIndex ?? this.answerIndex,
      difficulty: difficulty ?? this.difficulty,
      discrimination: discrimination ?? this.discrimination,
      guessing: guessing ?? this.guessing,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      explanation: explanation ?? this.explanation,
      tags: tags ?? this.tags,
      subCategory: subCategory ?? this.subCategory,
      version: version ?? this.version,
      usageCount: usageCount ?? this.usageCount,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }
}
