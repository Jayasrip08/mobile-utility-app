import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../models/ai_history_model.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Clear All',
            onPressed: () => _confirmClearAll(context, firestoreService),
          ),
        ],
      ),
      body: StreamBuilder<List<AIHistory>>(
        stream: firestoreService.getUserHistoryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final history = snapshot.data ?? [];

          if (history.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No history yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your AI tool results will appear here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return HistoryCard(history: item);
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmClearAll(
      BuildContext context, FirestoreService service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History?'),
        content: const Text(
            'This action cannot be undone. All your history will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await service.clearAllHistory();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('History cleared')),
        );
      }
    }
  }
}

class HistoryCard extends StatelessWidget {
  final AIHistory history;

  const HistoryCard({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    final input = history.input ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    history.toolName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  onPressed: () => _deleteHistory(context, firestoreService),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(history.module ?? 'Unknown'),
                  backgroundColor: _getModuleColor(history.module ?? 'Unknown'),
                ),
                const Spacer(),
                Text(
                  history.getFormattedDate(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (input.isNotEmpty) ...[
              const Text(
                'Input:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                input.length > 100 ? '${input.substring(0, 100)}...' : input,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
            ],
            const Text(
              'Output:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              history.output ?? history.result?.toString() ?? '',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Color _getModuleColor(String module) {
    final colors = {
      'Text AI': const Color(0xFFBBDEFB),
      'Image AI': const Color(0xFFC8E6C9),
      'Audio AI': Colors.orange.shade100,
      'Data AI': Colors.purple.shade100,
      'Automation AI': const Color(0xFFFFCDD2),
      'Logic & Decision AI': Colors.teal.shade100,
    };
    return colors[module] ?? const Color(0xFFF5F5F5);
  }

  Future<void> _deleteHistory(
      BuildContext context, FirestoreService service) async {
    if (history.id != null) {
      await service.deleteHistory(history.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${history.toolName} deleted')),
        );
      }
    }
  }
}
