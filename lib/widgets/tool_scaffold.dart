import 'package:flutter/material.dart';

class ToolScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? action;

  const ToolScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> allActions = [];
    if (action != null) {
      allActions.add(action!);
    }
    if (actions != null) {
      allActions.addAll(actions!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: allActions.isNotEmpty ? allActions : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}
