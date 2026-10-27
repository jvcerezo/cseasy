import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/strings.dart';

/// Wraps the root screen so one stray back press doesn't close the app:
/// the first press shows a hint, a second press within [window] exits.
class ExitGuard extends StatefulWidget {
  final Widget child;
  final Duration window;

  const ExitGuard({super.key, required this.child, this.window = const Duration(seconds: 2)});

  @override
  State<ExitGuard> createState() => _ExitGuardState();
}

class _ExitGuardState extends State<ExitGuard> {
  Timer? _armed;

  void _onBack() {
    if (_armed?.isActive ?? false) {
      SystemNavigator.pop();
      return;
    }
    _armed = Timer(widget.window, () {});
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: const Text(Strings.pressBackToExit), duration: widget.window));
  }

  @override
  void dispose() {
    _armed?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: widget.child,
    );
  }
}
