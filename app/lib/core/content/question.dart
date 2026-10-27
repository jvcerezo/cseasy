enum Section {
  verbal('verbal', 'Verbal Ability'),
  numerical('numerical', 'Numerical Ability'),
  analytical('analytical', 'Analytical Ability'),
  generalInfo('general_info', 'General Information'),
  clerical('clerical', 'Clerical Operations');

  final String key;
  final String label;
  const Section(this.key, this.label);

  static Section fromKey(String key) => values.firstWhere(
        (s) => s.key == key,
        orElse: () => throw FormatException('Unknown section: $key'),
      );
}

/// One multiple-choice item, as shipped in assets/content/cse.json.
class Question {
  final String id;
  final Set<String> levels;
  final Section section;
  final String topic;
  final String stem;
  final List<String> choices;
  final int answer;
  final String explanation;

  /// Citation for grounded items (e.g. "RA 6713, Sec. 8"); null when computed.
  final String? source;
  final int difficulty;

  const Question({
    required this.id,
    required this.levels,
    required this.section,
    required this.topic,
    required this.stem,
    required this.choices,
    required this.answer,
    required this.explanation,
    required this.source,
    required this.difficulty,
  });

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'] as String,
        levels: (json['levels'] as List).cast<String>().toSet(),
        section: Section.fromKey(json['section'] as String),
        topic: json['topic'] as String,
        stem: json['stem'] as String,
        choices: List.unmodifiable((json['choices'] as List).cast<String>()),
        answer: json['answer'] as int,
        explanation: json['explanation'] as String,
        source: json['source'] as String?,
        difficulty: json['difficulty'] as int,
      );

  bool isCorrect(int choice) => choice == answer;
}
