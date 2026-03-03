import 'dart:math';

class SmartCalculator {
  static String calculate(String expression) {
    try {
      // Remove whitespace
      expression = expression.replaceAll(' ', '');

      // Handle basic operations
      if (expression.contains('+')) {
        List<String> parts = expression.split('+');
        if (parts.length == 2) {
          double a = double.parse(parts[0]);
          double b = double.parse(parts[1]);
          return (a + b).toString();
        }
      }

      if (expression.contains('-')) {
        List<String> parts = expression.split('-');
        if (parts.length == 2) {
          double a = double.parse(parts[0]);
          double b = double.parse(parts[1]);
          return (a - b).toString();
        }
      }

      if (expression.contains('*')) {
        List<String> parts = expression.split('*');
        if (parts.length == 2) {
          double a = double.parse(parts[0]);
          double b = double.parse(parts[1]);
          return (a * b).toString();
        }
      }

      if (expression.contains('/')) {
        List<String> parts = expression.split('/');
        if (parts.length == 2) {
          double a = double.parse(parts[0]);
          double b = double.parse(parts[1]);
          if (b == 0) return 'Error: Division by zero';
          return (a / b).toStringAsFixed(4);
        }
      }

      if (expression.contains('^')) {
        List<String> parts = expression.split('^');
        if (parts.length == 2) {
          double a = double.parse(parts[0]);
          double b = double.parse(parts[1]);
          return pow(a, b).toString();
        }
      }

      // Handle percentage
      if (expression.contains('%')) {
        expression = expression.replaceAll('%', '');
        double value = double.parse(expression);
        return (value / 100).toString();
      }

      // Handle square root
      if (expression.toLowerCase().contains('sqrt')) {
        expression = expression
            .replaceAll('sqrt', '')
            .replaceAll('(', '')
            .replaceAll(')', '');
        double value = double.parse(expression);
        if (value < 0) return 'Error: Negative square root';
        return (value * value).toString(); // Simple square for demonstration
      }

      return 'Expression not recognized';
    } catch (e) {
      return 'Error: Invalid expression';
    }
  }

  static Map<String, dynamic> advancedCalculate(
      String operation, List<double> numbers) {
    switch (operation.toLowerCase()) {
      case 'average':
        double sum = numbers.reduce((a, b) => a + b);
        return {
          'result': (sum / numbers.length).toStringAsFixed(2),
          'operation': 'Average'
        };

      case 'sum':
        double sum = numbers.reduce((a, b) => a + b);
        return {'result': sum.toString(), 'operation': 'Sum'};

      case 'product':
        double product = numbers.reduce((a, b) => a * b);
        return {'result': product.toString(), 'operation': 'Product'};

      case 'max':
        double max = numbers.reduce((a, b) => a > b ? a : b);
        return {'result': max.toString(), 'operation': 'Maximum'};

      case 'min':
        double min = numbers.reduce((a, b) => a < b ? a : b);
        return {'result': min.toString(), 'operation': 'Minimum'};

      case 'range':
        double max = numbers.reduce((a, b) => a > b ? a : b);
        double min = numbers.reduce((a, b) => a < b ? a : b);
        return {'result': (max - min).toString(), 'operation': 'Range'};

      default:
        return {'result': 'Unknown operation', 'operation': 'Error'};
    }
  }
}
