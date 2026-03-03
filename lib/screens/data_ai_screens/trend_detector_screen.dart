import 'package:flutter/material.dart';
import '../../services/ai_executor.dart';

class TrendDetectorScreen extends StatefulWidget {
  const TrendDetectorScreen({super.key});

  @override
  State<TrendDetectorScreen> createState() => _TrendDetectorScreenState();
}

class _TrendDetectorScreenState extends State<TrendDetectorScreen> {
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  List<double> _data = [];
  List<String> _timestamps = [];
  Map<String, dynamic> _result = {};
  bool _loading = false;
  String _error = '';
  bool _showTimestamps = false;

  @override
  void initState() {
    super.initState();
    // Sample time series data
    _dataController.text = '100, 105, 110, 108, 115, 120, 125, 130, 135, 140';
    _timeController.text = 'Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct';
    _parseData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trend Detector')),
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
                      'Detect Trends in Time Series',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Analyze patterns and trends in sequential data',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),

                    // Data Input
                    TextField(
                      controller: _dataController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Time Series Data',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'Enter numerical values in sequence...',
                      ),
                      onChanged: (_) => _parseData(),
                    ),

                    const SizedBox(height: 12),

                    // Timestamps Toggle
                    Row(
                      children: [
                        Checkbox(
                          value: _showTimestamps,
                          onChanged: (value) {
                            setState(() {
                              _showTimestamps = value ?? false;
                            });
                          },
                        ),
                        const Text('Add Timestamps'),
                      ],
                    ),

                    // Timestamps Input (conditional)
                    if (_showTimestamps)
                      Column(
                        children: [
                          const SizedBox(height: 12),
                          TextField(
                            controller: _timeController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Timestamps (optional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              hintText: 'Enter corresponding timestamps...',
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 12),

                    // Statistics
                    if (_data.isNotEmpty) ...[
                      Row(
                        children: [
                          Chip(
                            label: Text('${_data.length} points'),
                            backgroundColor: const Color(0xFFE3F2FD),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                                'Start: ${_data.first.toStringAsFixed(1)}'),
                            backgroundColor: const Color(0xFFE8F5E9),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label:
                                Text('End: ${_data.last.toStringAsFixed(1)}'),
                            backgroundColor: Colors.orange.shade50,
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Action Button
                    ElevatedButton(
                      onPressed:
                          _data.isEmpty || _loading ? null : _detectTrend,
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
                          : const Text('Analyze Trends'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Quick Examples
            const Text(
              'Example Patterns:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Increasing Trend'),
                  onPressed: () {
                    _dataController.text =
                        '10, 15, 20, 25, 30, 35, 40, 45, 50, 55';
                    _parseData();
                  },
                ),
                ActionChip(
                  label: const Text('Decreasing Trend'),
                  onPressed: () {
                    _dataController.text =
                        '100, 95, 90, 85, 80, 75, 70, 65, 60, 55';
                    _parseData();
                  },
                ),
                ActionChip(
                  label: const Text('Seasonal Pattern'),
                  onPressed: () {
                    _dataController.text =
                        '10, 30, 20, 40, 30, 50, 40, 60, 50, 70';
                    _parseData();
                  },
                ),
                ActionChip(
                  label: const Text('No Trend'),
                  onPressed: () {
                    _dataController.text =
                        '50, 52, 48, 51, 49, 53, 47, 52, 48, 51';
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
                'Trend Analysis Results',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Trend Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Trend Summary',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getTrendColor(),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _getTrendBorderColor()),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _getTrendIcon(),
                              size: 48,
                              color: _getTrendIconColor(),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              (_result['trend'] ?? 'Unknown')
                                  .toString()
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _getTrendTextColor(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Direction: ${_result['direction']}',
                              style: TextStyle(
                                color: _getTrendTextColor(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Confidence: ${(_result['confidence'] ?? 0).toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: _getTrendTextColor(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Trend Statistics
                      Row(
                        children: [
                          Expanded(
                            child: _buildTrendStat(
                              'Slope',
                              _result['slope']?.toStringAsFixed(4) ?? '0',
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTrendStat(
                              'R²',
                              _result['rSquared']?.toStringAsFixed(4) ?? '0',
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTrendStat(
                              'Strength',
                              _result['strength']?.toStringAsFixed(4) ?? '0',
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Detailed Analysis Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detailed Analysis',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      if (_result.containsKey('analysis'))
                        Text(
                          _result['analysis'],
                          style: const TextStyle(height: 1.5),
                        ),

                      const SizedBox(height: 16),

                      // Seasonality Detection
                      if (_result.containsKey('seasonality'))
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _result['seasonality'] == true
                                ? Colors.orange.shade50
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _result['seasonality'] == true
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _result['seasonality'] == true
                                    ? Icons.autorenew
                                    : Icons.trending_flat,
                                color: _result['seasonality'] == true
                                    ? Colors.orange
                                    : Colors.green,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _result['seasonality'] == true
                                      ? 'Seasonal pattern detected'
                                      : 'No significant seasonality',
                                  style: TextStyle(
                                    color: _result['seasonality'] == true
                                        ? Colors.orange.shade800
                                        : const Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Breakpoints
                      if (_result.containsKey('breakpoints') &&
                          (_result['breakpoints'] as List).isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            const Text(
                              'Structural Breakpoints:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: (_result['breakpoints'] as List)
                                  .map<Widget>(
                                      (bp) => Chip(label: Text('Point $bp')))
                                  .toList(),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Forecast Card
              if (_result.containsKey('forecast') &&
                  (_result['forecast'] as List).isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Forecast (Next 3 Periods)',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child:
                                  _buildForecastCard(1, _result['forecast'][0]),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child:
                                  _buildForecastCard(2, _result['forecast'][1]),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child:
                                  _buildForecastCard(3, _result['forecast'][2]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Note: Based on linear trend extrapolation',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
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

              // Visualization Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Trend Visualization',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 300,
                        child: _buildTrendChart(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Method Details Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Analysis Methods',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildMethodDetail('Linear Regression',
                          _result['rSquared']?.toStringAsFixed(4) ?? '0'),
                      const SizedBox(height: 8),
                      _buildMethodDetail('Mann-Kendall Test',
                          'p-value: ${_result['pValue']?.toStringAsFixed(4) ?? '0'}'),
                      const SizedBox(height: 8),
                      _buildMethodDetail('Moving Average',
                          _result['movingAverage']?.toString() ?? 'N/A'),
                      const SizedBox(height: 8),
                      _buildMethodDetail('Overall Method',
                          _result['method']?.toString() ?? 'Combined'),
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

  Widget _buildTrendStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              color: color,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastCard(int period, double value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple),
      ),
      child: Column(
        children: [
          Text(
            'Period +$period',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.purple,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 20,
              color: Colors.purple,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodDetail(String method, String result) {
    return Container(
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
          Text(
            result,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    if (_data.isEmpty) return const Center(child: Text('No data'));

    // Prepare data for chart
    List<Map<String, dynamic>> chartData = [];
    for (int i = 0; i < _data.length; i++) {
      String label = _showTimestamps && i < _timestamps.length
          ? _timestamps[i]
          : (i + 1).toString();

      chartData.add({
        'x': label,
        'y': _data[i],
        'index': i,
      });
    }

    // Calculate trend line if we have results
    List<Map<String, dynamic>> trendLine = [];
    if (_result.containsKey('slope') && _result.containsKey('intercept')) {
      double slope = _result['slope'] ?? 0;
      double intercept = _result['intercept'] ?? 0;

      for (int i = 0; i < _data.length; i++) {
        trendLine.add({
          'x': i.toString(),
          'y': intercept + slope * i,
        });
      }
    }

    // Simple custom chart
    return Column(
      children: [
        // Chart area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 20, top: 20, bottom: 30),
            child: Stack(
              children: [
                // Grid lines
                _buildChartGrid(),

                // Trend line
                if (trendLine.isNotEmpty)
                  CustomPaint(
                    size: Size(double.infinity, double.infinity),
                    painter: _TrendLinePainter(trendLine, _data),
                  ),

                // Data points
                ...chartData.map((point) {
                  double xPos = (point['index'] / (_data.length - 1)) * 100;
                  double yVal = point['y'];
                  double minY = _data.reduce((a, b) => a < b ? a : b);
                  double maxY = _data.reduce((a, b) => a > b ? a : b);
                  double rangeY = maxY - minY;
                  double yPos =
                      rangeY > 0 ? ((yVal - minY) / rangeY) * 100 : 50;

                  return Positioned(
                    left: xPos,
                    top: 100 - yPos,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),

        // X-axis labels
        SizedBox(
          height: 30,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _data.length,
            itemBuilder: (context, index) {
              return SizedBox(
                width: 60,
                child: Center(
                  child: Text(
                    _showTimestamps && index < _timestamps.length
                        ? _timestamps[index]
                        : (index + 1).toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              );
            },
          ),
        ),

        // Y-axis scale
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _data.reduce((a, b) => a > b ? a : b).toStringAsFixed(1),
                style: const TextStyle(fontSize: 10),
              ),
              Text(
                _data.reduce((a, b) => a < b ? a : b).toStringAsFixed(1),
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartGrid() {
    return Column(
      children: List.generate(5, (index) {
        return Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFE0E0E0),
                  width: 0.5,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Color _getTrendColor() {
    String trend = (_result['trend'] ?? 'stable').toString().toLowerCase();
    if (trend.contains('increasing')) return const Color(0xFFE8F5E9);
    if (trend.contains('decreasing')) return const Color(0xFFFFEBEE);
    if (trend.contains('peaking') || trend.contains('bottoming'))
      return Colors.orange.shade50;
    return const Color(0xFFFAFAFA);
  }

  Color _getTrendBorderColor() {
    String trend = (_result['trend'] ?? 'stable').toString().toLowerCase();
    if (trend.contains('increasing')) return Colors.green;
    if (trend.contains('decreasing')) return Colors.red;
    if (trend.contains('peaking') || trend.contains('bottoming'))
      return Colors.orange;
    return Colors.grey;
  }

  Color _getTrendIconColor() {
    String trend = (_result['trend'] ?? 'stable').toString().toLowerCase();
    if (trend.contains('increasing')) return Colors.green;
    if (trend.contains('decreasing')) return Colors.red;
    if (trend.contains('peaking') || trend.contains('bottoming'))
      return Colors.orange;
    return Colors.grey;
  }

  Color _getTrendTextColor() {
    String trend = (_result['trend'] ?? 'stable').toString().toLowerCase();
    if (trend.contains('increasing')) return const Color(0xFF1B5E20);
    if (trend.contains('decreasing')) return const Color(0xFFB71C1C);
    if (trend.contains('peaking') || trend.contains('bottoming'))
      return Colors.orange.shade900;
    return const Color(0xFF212121);
  }

  IconData _getTrendIcon() {
    String trend = (_result['trend'] ?? 'stable').toString().toLowerCase();
    if (trend.contains('increasing')) return Icons.trending_up;
    if (trend.contains('decreasing')) return Icons.trending_down;
    if (trend.contains('peaking')) return Icons.waves;
    if (trend.contains('bottoming')) return Icons.waves;
    return Icons.trending_flat;
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
        _data = parts
            .where((part) => part.trim().isNotEmpty)
            .map((part) => double.parse(part.trim()))
            .toList();

        if (_data.isEmpty) {
          _error = 'No valid numbers found';
        }
      } catch (e) {
        _error = 'Error parsing data: $e';
        _data = [];
      }

      // Parse timestamps if available
      if (_showTimestamps) {
        String timeText = _timeController.text;
        List<String> timeParts = timeText.split(RegExp(r'[,\s\n]+'));
        _timestamps =
            timeParts.where((part) => part.trim().isNotEmpty).toList();
      }
    });
  }

  Future<void> _detectTrend() async {
    if (_data.isEmpty) {
      setState(() => _error = 'Please enter some data');
      return;
    }

    setState(() {
      _loading = true;
      _result = {};
    });

    try {
      Map<String, dynamic> input = {'data': _data};
      if (_showTimestamps && _timestamps.isNotEmpty) {
        input['timestamps'] = _timestamps;
      }

      final result = await AIExecutor.runTool(
        toolName: 'Trend Detector',
        module: 'Data AI',
        input: input,
      );

      setState(() {
        _result = result as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error detecting trends: $e';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _dataController.dispose();
    _timeController.dispose();
    super.dispose();
  }
}

// Custom painter for trend line
class _TrendLinePainter extends CustomPainter {
  final List<Map<String, dynamic>> trendLine;
  final List<double> originalData;

  _TrendLinePainter(this.trendLine, this.originalData);

  @override
  void paint(Canvas canvas, Size size) {
    if (trendLine.length < 2) return;

    double minY = originalData.reduce((a, b) => a < b ? a : b);
    double maxY = originalData.reduce((a, b) => a > b ? a : b);
    double rangeY = maxY - minY;

    Paint paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    Path path = Path();

    for (int i = 0; i < trendLine.length; i++) {
      double x = (i / (trendLine.length - 1)) * size.width;
      double yVal = trendLine[i]['y'];
      double y = rangeY > 0
          ? size.height - ((yVal - minY) / rangeY) * size.height
          : size.height / 2;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

