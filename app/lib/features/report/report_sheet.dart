import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/content/content_providers.dart';
import '../../core/content/question.dart';
import '../../core/strings.dart';

/// Override with --dart-define=SUPPORT_EMAIL=... ; reporting is hidden if empty.
const supportEmail = String.fromEnvironment('SUPPORT_EMAIL', defaultValue: 'jetjetcerezo@gmail.com');

/// "Report a problem" link under an explanation. Reports go out as a
/// prefilled email carrying the question id and content version, so they
/// can be traced back to content/ without any backend.
class ReportButton extends StatelessWidget {
  final Question question;

  const ReportButton({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    if (supportEmail.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => _ReportSheet(question: question),
        ),
        icon: const Icon(Icons.flag_outlined, size: 18),
        label: const Text(Strings.reportProblem),
      ),
    );
  }
}

class _ReportSheet extends ConsumerStatefulWidget {
  final Question question;

  const _ReportSheet({required this.question});

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  static const _reasons = [
    Strings.reportWrongKey,
    Strings.reportTypo,
    Strings.reportUnclear,
    Strings.reportOutdated,
    Strings.reportOther,
  ];

  final _note = TextEditingController();
  String _reason = _reasons.first;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final version = ref.read(questionBankProvider).valueOrNull?.version ?? 'unknown';
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    final q = widget.question;
    final body = [
      'Question: ${q.id}',
      'Reason: $_reason',
      if (_note.text.trim().isNotEmpty) 'Details: ${_note.text.trim()}',
      '',
      'Content version: $version',
      'App version: ${info.version} (${info.buildNumber})',
    ].join('\n');
    // Build the query by hand: Uri.queryParameters encodes spaces as "+",
    // which many mail apps show literally.
    final uri = Uri.parse(
      'mailto:$supportEmail'
      '?subject=${Uri.encodeComponent('CSEasy report: ${q.id}')}'
      '&body=${Uri.encodeComponent(body)}',
    );
    // Grab these before awaiting and popping: the sheet's context goes away with it.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    bool opened;
    try {
      opened = await launchUrl(uri);
    } catch (_) {
      opened = false; // no app can handle mailto:
    }
    navigator.pop();
    if (!opened) {
      messenger.showSnackBar(const SnackBar(content: Text(Strings.reportNoEmailApp)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Scrollable so the keyboard can't push the send button off a small screen.
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Strings.reportTitle, style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(widget.question.id, style: textTheme.bodySmall),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: _reason,
            onChanged: (value) => setState(() => _reason = value ?? _reason),
            child: Column(
              children: [
                for (final reason in _reasons)
                  RadioListTile<String>(value: reason, title: Text(reason), contentPadding: EdgeInsets.zero),
              ],
            ),
          ),
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: Strings.reportNoteHint,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _send,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text(Strings.reportSend),
          ),
        ],
      ),
    );
  }
}
