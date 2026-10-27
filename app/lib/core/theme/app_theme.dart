import 'package:flutter/material.dart';

const _seed = Color(0xFF1F5FBF);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    extensions: [
      brightness == Brightness.light ? QuizColors.light : QuizColors.dark,
    ],
  );
}

/// Right/wrong feedback colors; the color scheme has no semantic "success" slot.
@immutable
class QuizColors extends ThemeExtension<QuizColors> {
  final Color correct;
  final Color correctContainer;
  final Color wrong;
  final Color wrongContainer;

  const QuizColors({
    required this.correct,
    required this.correctContainer,
    required this.wrong,
    required this.wrongContainer,
  });

  static const light = QuizColors(
    correct: Color(0xFF1B7F3B),
    correctContainer: Color(0xFFD7F5DF),
    wrong: Color(0xFFB3261E),
    wrongContainer: Color(0xFFF9DEDC),
  );

  static const dark = QuizColors(
    correct: Color(0xFF7DDB98),
    correctContainer: Color(0xFF0F3D1E),
    wrong: Color(0xFFF2B8B5),
    wrongContainer: Color(0xFF601410),
  );

  static QuizColors of(BuildContext context) => Theme.of(context).extension<QuizColors>() ?? light;

  @override
  QuizColors copyWith({
    Color? correct,
    Color? correctContainer,
    Color? wrong,
    Color? wrongContainer,
  }) =>
      QuizColors(
        correct: correct ?? this.correct,
        correctContainer: correctContainer ?? this.correctContainer,
        wrong: wrong ?? this.wrong,
        wrongContainer: wrongContainer ?? this.wrongContainer,
      );

  @override
  QuizColors lerp(QuizColors? other, double t) {
    if (other == null) return this;
    return QuizColors(
      correct: Color.lerp(correct, other.correct, t) ?? correct,
      correctContainer: Color.lerp(correctContainer, other.correctContainer, t) ?? correctContainer,
      wrong: Color.lerp(wrong, other.wrong, t) ?? wrong,
      wrongContainer: Color.lerp(wrongContainer, other.wrongContainer, t) ?? wrongContainer,
    );
  }
}
