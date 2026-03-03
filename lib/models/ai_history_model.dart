import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AIHistory {
  final String? id;
  final String toolName;
  final dynamic result;
  final DateTime timestamp;
  final String? module;
  final String? input;
  final String? output;

  AIHistory({
    this.id,
    required this.toolName,
    required this.result,
    required this.timestamp,
    this.module,
    this.input,
    this.output,
  });

  factory AIHistory.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AIHistory(
      id: doc.id,
      toolName: data['toolName'] ?? '',
      result: data['result'],
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      module: data['module'] as String?,
      input: data['input'] as String?,
      output: data['output'] as String? ?? data['result']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'toolName': toolName,
      'result': result,
      'timestamp': Timestamp.fromDate(timestamp),
    };
    if (module != null) map['module'] = module;
    if (input != null) map['input'] = input;
    if (output != null) map['output'] = output;
    return map;
  }

  String getFormattedDate() {
    try {
      return DateFormat.yMMMd().add_jm().format(timestamp);
    } catch (_) {
      return timestamp.toIso8601String();
    }
  }
}
