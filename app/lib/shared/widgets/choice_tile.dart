import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Visual state of an answer choice.
///
/// [selected] is the neutral "picked" look used before answers are revealed
/// (mock exams); the others show feedback after answering.
enum ChoiceState { idle, selected, correct, wrong, dimmed }

class ChoiceTile extends StatelessWidget {
  final String letter;
  final String text;
  final ChoiceState state;
  final VoidCallback? onTap;

  const ChoiceTile({
    super.key,
    required this.letter,
    required this.text,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final quiz = QuizColors.of(context);

    final (background, border, foreground, icon) = switch (state) {
      ChoiceState.idle => (
        scheme.surfaceContainerLow,
        scheme.outlineVariant,
        scheme.onSurface,
        null,
      ),
      ChoiceState.selected => (
        scheme.primaryContainer,
        scheme.primary,
        scheme.onPrimaryContainer,
        Icons.radio_button_checked,
      ),
      ChoiceState.correct => (
        quiz.correctContainer,
        quiz.correct,
        scheme.onSurface,
        Icons.check_circle,
      ),
      ChoiceState.wrong => (quiz.wrongContainer, quiz.wrong, scheme.onSurface, Icons.cancel),
      ChoiceState.dimmed => (
        scheme.surfaceContainerLow,
        scheme.outlineVariant,
        scheme.onSurfaceVariant,
        null,
      ),
    };
    final iconColor = switch (state) {
      ChoiceState.correct => quiz.correct,
      ChoiceState.selected => scheme.primary,
      _ => quiz.wrong,
    };

    final stateLabel = switch (state) {
      ChoiceState.selected => 'selected',
      ChoiceState.correct => 'correct answer',
      ChoiceState.wrong => 'your answer, wrong',
      _ => null,
    };

    return Semantics(
      button: onTap != null,
      selected: state == ChoiceState.selected,
      label: stateLabel == null ? 'Choice $letter: $text' : 'Choice $letter: $text, $stateLabel',
      excludeSemantics: true,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: state == ChoiceState.idle ? 1 : 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    letter,
                    style: TextStyle(fontWeight: FontWeight.w700, color: foreground),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(text, style: TextStyle(fontSize: 16, color: foreground)),
                  ),
                  if (icon != null) Icon(icon, color: iconColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
