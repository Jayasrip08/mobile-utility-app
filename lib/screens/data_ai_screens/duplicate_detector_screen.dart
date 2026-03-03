import 'package:flutter/material.dart';
import '../../services/ai_executor.dart';

class DuplicateDetectorScreen extends StatefulWidget {
  const DuplicateDetectorScreen({super.key});

  @override
  State<DuplicateDetectorScreen> createState() =>
      _DuplicateDetectorScreenState();
}

class _DuplicateDetectorScreenState extends State<DuplicateDetectorScreen> {
  final TextEditingController _dataController = TextEditingController();
  List<Map<String, dynamic>> _records = [];
  Map<String, dynamic> _result = {};
  bool _loading = false;
  String _error = '';
  double _similarityThreshold = 0.8;
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    // Sample records with duplicates
    _dataController.text = '''Name: John Doe, Age: 30, City: New York
Name: Jane Smith, Age: 25, City: Los Angeles
Name: John Doe, Age: 30, City: New York
Name: John Doe, Age: 30, City: New York
Name: Jane Smith, Age: 26, City: Los Angeles
Name: Bob Johnson, Age: 35, City: Chicago''';
    _parseData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Duplicate Record Detector')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detect Duplicate Records',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Find duplicate or similar records in your data',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),

                    // Data Format Instructions
                    ExpansionTile(
                      title: const Text('Data Format Instructions'),
                      initiallyExpanded: false,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Format each record on a new line:'),
                              const SizedBox(height: 8),
                              const Text(
                                  'field1: value1, field2: value2, field3: value3'),
                              const SizedBox(height: 8),
                              const Text('Example:'),
                              const SizedBox(height: 4),
                              Text(
                                'Name: John Doe, Age: 30, City: New York',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Data Input
                    TextField(
                      controller: _dataController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        labelText: 'Enter Records',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'Enter records in the format shown above...',
                      ),
                      onChanged: (_) => _parseData(),
                    ),

                    const SizedBox(height: 12),

                    // Advanced Settings
                    Row(
                      children: [
                        Checkbox(
                          value: _showAdvanced,
                          onChanged: (value) {
                            setState(() {
                              _showAdvanced = value ?? false;
                            });
                          },
                        ),
                        const Text('Advanced Settings'),
                      ],
                    ),

                    if (_showAdvanced) ...[
                      const SizedBox(height: 12),
                      const Text('Similarity Threshold:',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      Slider(
                        value: _similarityThreshold,
                        min: 0.5,
                        max: 1.0,
                        divisions: 10,
                        label: _similarityThreshold.toStringAsFixed(2),
                        onChanged: (value) {
                          setState(() {
                            _similarityThreshold = value;
                          });
                        },
                      ),
                      Text(
                        'Threshold: ${_similarityThreshold.toStringAsFixed(2)} '
                        '(Higher = stricter duplicate detection)',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Statistics
                    if (_records.isNotEmpty) ...[
                      Row(
                        children: [
                          Chip(
                            label: Text('${_records.length} records'),
                            backgroundColor: const Color(0xFFE3F2FD),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text('${_countDuplicates()} unique'),
                            backgroundColor: const Color(0xFFE8F5E9),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                                '${_records.length - _countDuplicates()} potential duplicates'),
                            backgroundColor: Colors.orange.shade50,
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Action Button
                    ElevatedButton(
                      onPressed: _records.isEmpty || _loading
                          ? null
                          : _detectDuplicates,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text('Detect Duplicates'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Quick Examples
            const Text(
              'Example Datasets:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Exact Duplicates'),
                  onPressed: () {
                    _dataController.text = '''Name: Alice, Age: 25, City: Boston
Name: Bob, Age: 30, City: Chicago
Name: Alice, Age: 25, City: Boston
Name: Charlie, Age: 35, City: Denver
Name: Bob, Age: 30, City: Chicago''';
                    _parseData();
                  },
                ),
                ActionChip(
                  label: const Text('Similar Records'),
                  onPressed: () {
                    _dataController.text =
                        '''Name: John Smith, Age: 30, City: NYC
Name: Jon Smith, Age: 30, City: New York
Name: John S., Age: 31, City: New York City
Name: Jane Doe, Age: 25, City: LA
Name: J. Doe, Age: 25, City: Los Angeles''';
                    _parseData();
                  },
                ),
                ActionChip(
                  label: const Text('Mixed Data'),
                  onPressed: () {
                    _dataController.text =
                        '''Product: Laptop, Price: 999.99, Category: Electronics
Product: Laptop, Price: 999.99, Category: Electronics
Product: Laptop, Price: 1099.99, Category: Electronics
Product: Phone, Price: 699.99, Category: Electronics
Product: Phone, Price: 699.99, Category: Electronics''';
                    _parseData();
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Error Display
            if (_error.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error)),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Results Display
            if (_result.isNotEmpty) ...[
              const Text(
                'Duplicate Detection Results',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detection Summary',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Total Duplicates',
                              _result['count']?.toString() ?? '0',
                              Colors.red,
                              Icons.warning,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Duplicate %',
                              '${_result['percentage'] ?? '0'}',
                              Colors.orange,
                              Icons.percent,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Duplicate Groups',
                              _result['uniqueDuplicates']?.toString() ?? '0',
                              Colors.blue,
                              Icons.group,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Method',
                              _result['method']?.toString().split(' ').first ??
                                  'N/A',
                              Colors.green,
                              Icons.auto_awesome,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Severity Indicator
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _getSeverityBorderColor()),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getSeverityIcon(),
                              color: _getSeverityIconColor(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Severity: ${(_result['severity'] ?? 'low').toString().toUpperCase()}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getSeverityTextColor(),
                                    ),
                                  ),
                                  if (_result.containsKey('analysis'))
                                    Text(
                                      _result['analysis'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _getSeverityTextColor(),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Duplicate Groups Card
              if (_result.containsKey('groups') &&
                  (_result['groups'] as List).isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Duplicate Groups Found',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ...(_result['groups'] as List)
                            .asMap()
                            .entries
                            .map((entry) {
                          int groupIndex = entry.key;
                          List<int> group = List<int>.from(entry.value);

                          return ExpansionTile(
                            title: Text(
                                'Group ${groupIndex + 1}: ${group.length} duplicate records'),
                            children: group.map((recordIndex) {
                              if (recordIndex < _records.length) {
                                return _buildRecordCard(
                                    _records[recordIndex], recordIndex);
                              }
                              return const SizedBox();
                            }).toList(),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Method Comparison Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detection Methods Used',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (_result.containsKey('exactMatches'))
                        _buildMethodResult(
                            'Exact Match', _result['exactMatches']),
                      if (_result.containsKey('similarMatches'))
                        _buildMethodResult(
                            'Similarity-Based', _result['similarMatches']),
                      if (_result.containsKey('fuzzyMatches'))
                        _buildMethodResult(
                            'Fuzzy Matching', _result['fuzzyMatches']),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Patterns Card
              if (_result.containsKey('patterns'))
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Duplicate Patterns',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (_result['patterns'].containsKey('fieldDuplicates'))
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Fields Causing Most Duplicates:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              ...(_result['patterns']['fieldDuplicates'] as Map)
                                  .entries
                                  .map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(entry.key),
                                      ),
                                      Chip(
                                        label: Text('${entry.value} groups'),
                                        backgroundColor:
                                            const Color(0xFFE3F2FD),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        if (_result['patterns'].containsKey('groupSizes'))
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              const Text(
                                'Group Size Distribution:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Chip(
                                    label: Text(
                                        'Largest: ${_result['patterns']['maxGroupSize']}'),
                                    backgroundColor: const Color(0xFFFFEBEE),
                                  ),
                                  const SizedBox(width: 8),
                                  Chip(
                                    label: Text(
                                        'Average: ${_result['patterns']['avgGroupSize']?.toStringAsFixed(1)}'),
                                    backgroundColor: const Color(0xFFE8F5E9),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Recommendations Card
              if (_result.containsKey('recommendations'))
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recommendations',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ...(_result['recommendations'] as List)
                            .map<Widget>((rec) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.arrow_right,
                                    size: 16, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(child: Text(rec)),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Clean Data Button
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Data Cleaning',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Remove detected duplicates from your data:',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _removeDuplicates,
                        icon: const Icon(Icons.cleaning_services),
                        label: const Text('Remove Duplicates'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Record ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_result.containsKey('consensusOutliers') &&
                    (_result['consensusOutliers'] as List).contains(index))
                  const Chip(
                    label: Text('Duplicate'),
                    backgroundColor: Colors.red,
                    labelStyle: TextStyle(color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...record.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${entry.key}:',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value.toString(),
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodResult(String method, dynamic result) {
    int count = 0;
    if (result is Map && result.containsKey('count')) {
      count = result['count'];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              method,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Chip(
            label: Text('$count duplicates'),
            backgroundColor:
                count > 0 ? Colors.orange.shade50 : const Color(0xFFE8F5E9),
            labelStyle: TextStyle(
              color:
                  count > 0 ? Colors.orange.shade900 : const Color(0xFF1B5E20),
            ),
          ),
        ],
      ),
    );
  }

  int _countDuplicates() {
    // Simple duplicate count based on string representation
    Set<String> unique = {};
    for (var record in _records) {
      unique.add(record.toString());
    }
    return unique.length;
  }

  Color _getSeverityColor() {
    String severity = _result['severity'] ?? 'low';
    switch (severity) {
      case 'critical':
        return const Color(0xFFFFEBEE);
      case 'high':
        return Colors.orange.shade50;
      case 'moderate':
        return Colors.yellow.shade50;
      case 'low':
        return const Color(0xFFE8F5E9);
      default:
        return const Color(0xFFFAFAFA);
    }
  }

  Color _getSeverityBorderColor() {
    String severity = _result['severity'] ?? 'low';
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'moderate':
        return Colors.yellow;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getSeverityIconColor() {
    String severity = _result['severity'] ?? 'low';
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'moderate':
        return Colors.yellow.shade700;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getSeverityTextColor() {
    String severity = _result['severity'] ?? 'low';
    switch (severity) {
      case 'critical':
        return const Color(0xFFB71C1C);
      case 'high':
        return Colors.orange.shade900;
      case 'moderate':
        return Colors.yellow.shade900;
      case 'low':
        return const Color(0xFF1B5E20);
      default:
        return const Color(0xFF212121);
    }
  }

  IconData _getSeverityIcon() {
    String severity = _result['severity'] ?? 'low';
    switch (severity) {
      case 'critical':
        return Icons.error;
      case 'high':
        return Icons.warning;
      case 'moderate':
        return Icons.info;
      case 'low':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  void _parseData() {
    setState(() {
      _error = '';
      String text = _dataController.text.trim();

      if (text.isEmpty) {
        _records = [];
        return;
      }

      try {
        List<String> lines = text.split('\n');
        _records = [];

        for (String line in lines) {
          line = line.trim();
          if (line.isEmpty) continue;

          Map<String, dynamic> record = {};
          List<String> parts = line.split(',');

          for (String part in parts) {
            part = part.trim();
            if (part.contains(':')) {
              List<String> keyValue = part.split(':');
              if (keyValue.length >= 2) {
                String key = keyValue[0].trim();
                String value = keyValue.sublist(1).join(':').trim();

                // Try to parse as number if possible
                if (RegExp(r'^-?\d+(\.\d+)?$').hasMatch(value)) {
                  record[key] = double.tryParse(value) ?? value;
                } else {
                  record[key] = value;
                }
              }
            }
          }

          if (record.isNotEmpty) {
            _records.add(record);
          }
        }

        if (_records.isEmpty) {
          _error = 'No valid records found';
        }
      } catch (e) {
        _error = 'Error parsing data: $e';
        _records = [];
      }
    });
  }

  Future<void> _detectDuplicates() async {
    if (_records.isEmpty) {
      setState(() => _error = 'Please enter some data');
      return;
    }

    setState(() {
      _loading = true;
      _result = {};
    });

    try {
      final result = await AIExecutor.runTool(
        toolName: 'Duplicate Record Detector',
        module: 'Data AI',
        input: {
          'records': _records,
          'similarityThreshold': _similarityThreshold,
        },
      );

      setState(() {
        _result = result as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error detecting duplicates: $e';
        _loading = false;
      });
    }
  }

  void _removeDuplicates() {
    if (!_result.containsKey('consensusOutliers')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No duplicates to remove')),
      );
      return;
    }

    List<int> duplicateIndices = List<int>.from(_result['consensusOutliers']);
    duplicateIndices
        .sort((a, b) => b.compareTo(a)); // Remove from end to beginning

    List<Map<String, dynamic>> newRecords = List.from(_records);

    for (int index in duplicateIndices) {
      if (index < newRecords.length) {
        newRecords.removeAt(index);
      }
    }

    // Update the data controller
    String newText = '';
    for (var record in newRecords) {
      List<String> parts = [];
      record.forEach((key, value) {
        parts.add('$key: $value');
      });
      newText += '${parts.join(', ')}\n';
    }

    _dataController.text = newText.trim();
    _parseData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Removed ${duplicateIndices.length} duplicate records')),
    );
  }

  @override
  void dispose() {
    _dataController.dispose();
    super.dispose();
  }
}

