import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_history_model.dart';

class LocalCacheService {
  static const _key = 'pending_ai_history';

  static final LocalCacheService instance = LocalCacheService._init();

  LocalCacheService._init();

  Future<List<AIHistory>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((s) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        return AIHistory(
          id: map['id'] as String?,
          toolName: map['toolName'] as String,
          result: jsonDecode(map['result'] as String),
          timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
          module: map['module'] as String?,
          input: map['input'] as String?,
          output: map['output'] as String?,
        );
      } catch (_) {
        return AIHistory(
          id: null,
          toolName: 'unknown',
          result: {},
          timestamp: DateTime.now(),
        );
      }
    }).toList();
  }

  Future<void> saveHistory(AIHistory history) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];

    final map = <String, dynamic>{
      'id': history.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'toolName': history.toolName,
      'result': jsonEncode(history.result),
      'timestamp': history.timestamp.millisecondsSinceEpoch,
      'module': history.module,
      'input': history.input,
      'output': history.output,
    };

    list.insert(0, jsonEncode(map));
    await prefs.setStringList(_key, list);
  }

  Future<void> deleteHistory(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    final updated = list.where((s) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        return map['id'] != id;
      } catch (_) {
        return true;
      }
    }).toList();
    await prefs.setStringList(_key, updated);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<List<AIHistory>> drainAll() async {
    final items = await getHistory();
    await clearHistory();
    return items;
  }
}
