class LogicSolver {
  static String solveBooleanExpression(String expression) {
    expression = expression.toLowerCase().replaceAll(' ', '');

    // Handle AND operations
    if (expression.contains('and') || expression.contains('&&')) {
      List<String> parts = expression.contains('and')
          ? expression.split('and')
          : expression.split('&&');

      bool result = true;
      for (var part in parts) {
        if (part == 'false' || part == '0') {
          result = false;
          break;
        }
      }
      return result.toString();
    }

    // Handle OR operations
    if (expression.contains('or') || expression.contains('||')) {
      List<String> parts = expression.contains('or')
          ? expression.split('or')
          : expression.split('||');

      bool result = false;
      for (var part in parts) {
        if (part == 'true' || part == '1') {
          result = true;
          break;
        }
      }
      return result.toString();
    }

    // Handle NOT operations
    if (expression.contains('not') || expression.contains('!')) {
      expression = expression.replaceAll('not', '').replaceAll('!', '');
      if (expression == 'true' || expression == '1') return 'false';
      if (expression == 'false' || expression == '0') return 'true';
    }

    // Handle implication (if-then)
    if (expression.contains('=>') || expression.contains('implies')) {
      List<String> parts = expression.contains('=>')
          ? expression.split('=>')
          : expression.split('implies');

      if (parts.length == 2) {
        bool p = parts[0] == 'true' || parts[0] == '1';
        bool q = parts[1] == 'true' || parts[1] == '1';

        // p => q is equivalent to !p || q
        bool result = !p || q;
        return result.toString();
      }
    }

    // Handle equivalence
    if (expression.contains('<=>') || expression.contains('equiv')) {
      List<String> parts = expression.contains('<=>')
          ? expression.split('<=>')
          : expression.split('equiv');

      if (parts.length == 2) {
        bool p = parts[0] == 'true' || parts[0] == '1';
        bool q = parts[1] == 'true' || parts[1] == '1';

        bool result = p == q;
        return result.toString();
      }
    }

    // Simple true/false
    if (expression == 'true' || expression == '1') return 'true';
    if (expression == 'false' || expression == '0') return 'false';

    return 'Cannot parse expression';
  }

  static Map<String, bool> solveTruthTable(String expression) {
    Map<String, bool> results = {};

    // Simple variable analysis
    List<String> variables = [];
    for (var char in expression.split('')) {
      if (char.toLowerCase() != char.toUpperCase() && // is letter
          !variables.contains(char.toLowerCase())) {
        variables.add(char.toLowerCase());
      }
    }

    // Generate simple truth table for 2 variables max
    if (variables.length <= 2) {
      for (int i = 0; i < (1 << variables.length); i++) {
        String combination = '';
        bool p = (i & 1) == 1;
        bool q = variables.length > 1 ? ((i & 2) == 2) : false;

        // Substitute values
        String substituted = expression;
        if (variables.isNotEmpty) {
          substituted = substituted.replaceAll(variables[0], p.toString());
        }
        if (variables.length > 1) {
          substituted = substituted.replaceAll(variables[1], q.toString());
        }

        bool result = solveBooleanExpression(substituted) == 'true';
        combination = variables.length == 1
            ? '${p ? 'T' : 'F'}'
            : '${p ? 'T' : 'F'}, ${q ? 'T' : 'F'}';

        results[combination] = result;
      }
    }

    return results;
  }
}
