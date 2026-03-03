import 'package:flutter/material.dart';

class ToolScaffold extends StatelessWidget {
  final String title;
  final Widget? action;
  final List<Widget>? actions;
  final Widget child;
  final String? toolDescription;

  const ToolScaffold({
    super.key,
    required this.title,
    this.action,
    this.actions,
    required this.child,
    this.toolDescription,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade900,
                Colors.blue.shade600,
              ],
            ),
          ),
        ),
        actions: [
          if (toolDescription != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showInfo(context),
            ),
          if (actions != null) ...actions!,
          if (action != null) action!,
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Tool Header (Optional, for context)
              // Padding(
              //   padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              //   child: Text(
              //     title.toUpperCase(),
              //     style: TextStyle(
              //       fontSize: 12,
              //       fontWeight: FontWeight.bold,
              //       color: Colors.grey.shade500,
              //       letterSpacing: 1.2,
              //     ),
              //   ),
              // ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.info, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text('About Tool'),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              toolDescription!,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }
}
