import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/ai_executor.dart';

class DataValidatorScreen extends StatefulWidget {
  const DataValidatorScreen({super.key});

  @override
  State<DataValidatorScreen> createState() => _DataValidatorScreenState();
}

class _DataValidatorScreenState extends State<DataValidatorScreen> {
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _constraintsController = TextEditingController();
  List<double> _data = [];
  Map<String, dynamic> _result = {};
  bool _loading = false;
  String _error = '';
  String _selectedDataType = 'general';
  bool _showConstraints = false;

  final Map<String, String> _dataTypes = {
    'general': 'General Numerical',
    'percentages': 'Percentages (0-100)',
    'probabilities': 'Probabilities (0-1)',
    'ratings': 'Ratings (1-10)',
    'financial': 'Financial Values',
    'measurements': 'Scientific Measurements',
    'integers': 'Integer Values',
    'positive': 'Positive Numbers Only',
  };

  @override
  void initState() {
    super.initState();
    // Sample data for validation
    _dataController.text = '10, 15, 20, 25, 30, 35, 40, 45, 50, 55';
    _constraintsController.text = '{"min": 0, "max": 100}';
    _parseData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Validation Engine')),
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
                      'Validate Data Quality',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Check data against quality rules and constraints',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),

                    // Data Type Selection
                    const Text('Data Type:',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                        initialValue: _selectedDataType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      items: _dataTypes.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDataType = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // Constraints Toggle
                    Row(
                      children: [
                        Checkbox(
                          value: _showConstraints,
                          onChanged: (value) {
                            setState(() {
                              _showConstraints = value ?? false;
                            });
                          },
                        ),
                        const Text('Add Custom Constraints'),
                      ],
                    ),

                    // Constraints Input (conditional)
                    if (_showConstraints)
                      Column(
                        children: [
                          const SizedBox(height: 12),
                          const Text('Constraints (JSON format):',
                              style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _constraintsController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              hintText:
                                  'e.g., {"min": 0, "max": 100, "requiredSum": 500}',
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // Data Input
                    TextField(
                      controller: _dataController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Data to Validate',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'Enter numerical data...',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _dataController.clear();
                            setState(() {
                              _data = [];
                              _result = {};
                            });
                          },
                        ),
                      ),
                      onChanged: (_) => _parseData(),
                    ),

                    const SizedBox(height: 12),

                    // Quick Statistics
                    if (_data.isNotEmpty) ...[
                      Row(
                        children: [
                          Chip(
                            label: Text('n = ${_data.length}'),
                            backgroundColor: const Color(0xFFE3F2FD),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text('Valid: ${_countValid()}'),
                            backgroundColor: const Color(0xFFE8F5E9),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label:
                                Text('Issues: ${_data.length - _countValid()}'),
                            backgroundColor: Colors.orange.shade50,
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Action Button
                    ElevatedButton(
                      onPressed:
                          _data.isEmpty || _loading ? null : _validateData,
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
                          : const Text('Validate Data'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Quick Examples
            const Text(
              'Validation Examples:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Clean Data'),
                  onPressed: () {
                    _dataController.text =
                        '10, 20, 30, 40, 50, 60, 70, 80, 90, 100';
                    _selectedDataType = 'general';
                    _parseData();
                  },
                ),
                ActionChip(
                  label: const Text('With Issues'),
                  onPressed: () {
                    _dataController.text =
                        '10, 20, NaN, 40, Infinity, 60, -5, 80, 90, 1000';
                    _selectedDataType = 'general';
                    _parseData();
                  },
                ),
                ActionChip(
                  label: const Text('Percentages'),
                  onPressed: () {
                    _dataController.text =
                        '85, 90, 95, 105, -5, 110, 75, 80, 85, 90';
                    _selectedDataType = 'percentages';
                    _parseData();
                  },
                ),
                ActionChip(
                  label: const Text('Probabilities'),
                  onPressed: () {
                    _dataController.text =
                        '0.1, 0.2, 0.3, 1.5, -0.1, 0.4, 0.5, 0.6, 0.7, 0.8';
                    _selectedDataType = 'probabilities';
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
                'Validation Results',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Validation Score Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Validation Score',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${(_result['score'] as double).toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getScoreColor(_result['score'] as double),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _result['qualityRating'] ?? 'Unknown',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: (_result['score'] as double) / 100,
                        backgroundColor: const Color(0xFFEEEEEE),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            _getScoreColor(_result['score'] as double)),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_result['passedCount']} of ${_result['totalTests']} tests passed',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Issues and Recommendations
              if ((_result['issues'] as List).isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              'Validation Issues',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...(_result['issues'] as List<dynamic>).map((issue) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.circle,
                                    size: 8, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    issue.toString(),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Recommendations
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Recommendations',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...(_result['recommendations'] as List<dynamic>)
                          .map((rec) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 16, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  rec.toString(),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Detailed Results
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detailed Test Results',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children:
                            (_result['detailedResults'] as Map<String, dynamic>)
                                .entries
                                .map((entry) {
                          bool passed = entry.value == 'PASS';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  passed ? Icons.check_circle : Icons.error,
                                  color: passed ? Colors.green : Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _formatTestName(entry.key),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: passed
                                        ? const Color(0xFFE8F5E9)
                                        : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    passed ? 'PASS' : 'ISSUE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          passed ? Colors.green : Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Statistical Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Statistical Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_result.containsKey('statistics'))
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          children: [
                            _buildStatCard(
                                'Count',
                                (_result['statistics']['count'] as num)
                                    .toString()),
                            _buildStatCard(
                                'Mean',
                                (_result['statistics']['mean'] as double)
                                    .toStringAsFixed(2)),
                            _buildStatCard(
                                'Std Dev',
                                (_result['statistics']['stdDev'] as double)
                                    .toStringAsFixed(2)),
                            _buildStatCard(
                                'Min',
                                (_result['statistics']['min'] as double)
                                    .toStringAsFixed(2)),
                            _buildStatCard(
                                'Max',
                                (_result['statistics']['max'] as double)
                                    .toStringAsFixed(2)),
                            _buildStatCard(
                                'Range',
                                (_result['statistics']['range'] as double)
                                    .toStringAsFixed(2)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Data Quality Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Data Quality Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getScoreColor(_result['score'] as double)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color:
                                  _getScoreColor(_result['score'] as double)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.analytics,
                                  color: _getScoreColor(
                                      _result['score'] as double),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Severity Level: ${_result['severity']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getScoreColor(
                                        _result['score'] as double),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _result['analysis'] ?? 'No analysis available',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
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

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBBDEFB)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.blue;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  String _formatTestName(String key) {
    // Convert camelCase to Title Case with spaces
    return key
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match[1]} ${match[2]}',
        )
        .replaceAllMapped(
          RegExp(r'^[a-z]'),
          (match) => match.group(0)!.toUpperCase(),
        );
  }

  int _countValid() {
    int validCount = 0;
    for (var value in _data) {
      if (!value.isNaN && !value.isInfinite) {
        validCount++;
      }
    }
    return validCount;
  }

  void _parseData() {
    setState(() {
      _error = '';
      String text = _dataController.text;

      if (text.isEmpty) {
        _data = [];
        return;
      }

      try {
        List<String> parts = text.split(RegExp(r'[,\s\n]+'));
        _data = parts.where((part) => part.trim().isNotEmpty).map((part) {
          if (part.toUpperCase() == 'NAN') return double.nan;
          if (part.toUpperCase() == 'INFINITY' || part.toUpperCase() == 'INF')
            return double.infinity;
          return double.parse(part.trim());
        }).toList();

        if (_data.isEmpty) {
          _error = 'No valid numbers found';
        }
      } catch (e) {
        _error = 'Error parsing data: $e';
        _data = [];
      }
    });
  }

  Future<void> _validateData() async {
    if (_data.isEmpty) {
      setState(() => _error = 'Please enter some data');
      return;
    }

    setState(() {
      _loading = true;
      _result = {};
    });

    try {
      Map<String, dynamic>? constraints;
      if (_showConstraints && _constraintsController.text.trim().isNotEmpty) {
        try {
          constraints = Map<String, dynamic>.from(
            jsonDecode(_constraintsController.text),
          );
        } catch (e) {
          setState(() {
            _error = 'Invalid JSON in constraints: $e';
            _loading = false;
          });
          return;
        }
      }

      final result = await AIExecutor.runTool(
        toolName: 'Data Validator',
        module: 'Data AI',
        input: {
          'data': _data,
          'dataType': _selectedDataType,
          'constraints': constraints,
        },
      );

      setState(() {
        _result = result as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error validating data: $e';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _dataController.dispose();
    _constraintsController.dispose();
    super.dispose();
  }
}

