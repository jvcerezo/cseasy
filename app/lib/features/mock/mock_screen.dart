import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/quiz/mock_exam.dart';
import '../../core/strings.dart';
import '../../shared/widgets/choice_tile.dart';
import '../../shared/widgets/question_parts.dart';
import 'mock_controller.dart';
import 'mock_results_view.dart';

class MockScreen extends ConsumerWidget {
  final MockExamSpec spec;

  const MockScreen({super.key, required this.spec});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = mockControllerProvider(spec);
    final session = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(spec.label)),
        body: const Center(child: Text(Strings.loadError)),
      );
    }
    if (session.isSubmitted) {
      return Scaffold(
        appBar: AppBar(title: Text(spec.label)),
        body: MockResultsView(session: session, onDone: () => Navigator.of(context).pop()),
      );
    }

    final flagged = session.flagged.contains(session.index);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmLeave(context);
        if (leave && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${session.index + 1} / ${session.length}'),
          actions: [
            Center(child: _Countdown(endsAt: session.endsAt, onExpired: controller.submit)),
            IconButton(
              tooltip: Strings.flag,
              icon: Icon(flagged ? Icons.flag : Icons.outlined_flag),
              onPressed: controller.toggleFlag,
            ),
            IconButton(
              tooltip: Strings.allItems,
              icon: const Icon(Icons.grid_view),
              onPressed: () => _showGrid(context, session, controller),
            ),
          ],
        ),
        body: _MockQuestion(
          key: ValueKey(session.index),
          session: session,
          onSelect: controller.select,
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: session.index == 0 ? null : () => controller.goTo(session.index - 1),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    child: const Text(Strings.previous),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: session.index == session.length - 1
                      ? FilledButton(
                          onPressed: () => _confirmSubmit(context, session, controller),
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                          child: const Text(Strings.submit),
                        )
                      : FilledButton(
                          onPressed: () => controller.goTo(session.index + 1),
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                          child: const Text(Strings.next),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<bool> _confirmLeave(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Strings.leaveExam),
        content: const Text(Strings.leaveExamBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text(Strings.stay)),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text(Strings.leave)),
        ],
      ),
    );
    return leave ?? false;
  }

  static Future<void> _confirmSubmit(
    BuildContext context,
    MockSession session,
    MockController controller,
  ) async {
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Strings.submitExam),
        content: Text(Strings.unansweredWarning(session.unansweredCount)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(Strings.keepAnswering),
          ),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text(Strings.submit)),
        ],
      ),
    );
    if (submit ?? false) controller.submit();
  }

  static void _showGrid(BuildContext context, MockSession session, MockController controller) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 56,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: session.length,
                  itemBuilder: (_, i) => _GridCell(
                    number: i + 1,
                    answered: session.selections[i] != null,
                    flagged: session.flagged.contains(i),
                    current: i == session.index,
                    onTap: () {
                      controller.goTo(i);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _confirmSubmit(context, session, controller);
                  },
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: const Text(Strings.submit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockQuestion extends StatelessWidget {
  final MockSession session;
  final ValueChanged<int> onSelect;

  const _MockQuestion({super.key, required this.session, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final question = session.current;
    final selection = session.selections[session.index];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          question.section.label,
          style: textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(height: 8),
        Text(question.stem, style: textTheme.titleLarge),
        if (question.table case final table?) ...[
          const SizedBox(height: 16),
          QuestionTableView(table: table),
        ],
        const SizedBox(height: 20),
        for (var i = 0; i < question.choices.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ChoiceTile(
              letter: String.fromCharCode(65 + i),
              text: question.choices[i],
              state: selection == i ? ChoiceState.selected : ChoiceState.idle,
              onTap: () => onSelect(i),
            ),
          ),
      ],
    );
  }
}

class _GridCell extends StatelessWidget {
  final int number;
  final bool answered;
  final bool flagged;
  final bool current;
  final VoidCallback onTap;

  const _GridCell({
    required this.number,
    required this.answered,
    required this.flagged,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: answered ? scheme.primaryContainer : scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: current ? BorderSide(color: scheme.primary, width: 2) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Center(child: Text('$number')),
            if (flagged)
              Positioned(top: 2, right: 2, child: Icon(Icons.flag, size: 14, color: scheme.error)),
          ],
        ),
      ),
    );
  }
}

/// Ticks once a second on its own, so the exam screen doesn't rebuild.
class _Countdown extends StatefulWidget {
  final DateTime endsAt;
  final VoidCallback onExpired;

  const _Countdown({required this.endsAt, required this.onExpired});

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  Timer? _timer;
  late Duration _left = widget.endsAt.difference(DateTime.now());

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    // Never submit during the first build, even if time has already run out.
    WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    final left = widget.endsAt.difference(DateTime.now());
    if (left <= Duration.zero) {
      _timer?.cancel();
      widget.onExpired();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Strings.timeUp)));
      }
      return;
    }
    setState(() => _left = left);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _left.inHours;
    final m = (_left.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_left.inSeconds % 60).toString().padLeft(2, '0');
    final low = _left < const Duration(minutes: 5);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        h > 0 ? '$h:$m:$s' : '$m:$s',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              color: low ? Theme.of(context).colorScheme.error : null,
            ),
      ),
    );
  }
}
