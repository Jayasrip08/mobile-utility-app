/// Rule-based Grammar Checker using Classical AI techniques
class GrammarChecker {
  /// Checks text for grammar errors using rule-based analysis
  /// Classical AI: Rule-based system with pattern matching
  static List<String> checkText(String text) {
    List<String> errors = [];

    if (text.trim().isEmpty) {
      errors.add("Text is empty");
      return errors;
    }

    // Rule 1: Check for missing capitalization at start
    if (text.isNotEmpty && !_isUpperCase(text[0])) {
      errors.add("Sentence should start with a capital letter");
    }

    // Rule 2: Check for missing ending punctuation
    if (!text.trim().endsWith('.') &&
        !text.trim().endsWith('!') &&
        !text.trim().endsWith('?')) {
      errors.add("Sentence should end with proper punctuation (. ! ?)");
    }

    // Rule 3: Check for double spaces
    if (text.contains('  ')) {
      errors.add("Multiple consecutive spaces detected");
    }

    // Rule 4: Check for common grammar patterns
    final commonMistakes = {
      'alot': 'a lot',
      'could of': 'could have',
      'should of': 'should have',
      'would of': 'would have',
      'their are': 'there are',
      'your welcome': 'you\'re welcome',
      'its good': 'it\'s good',
    };

    for (var mistake in commonMistakes.keys) {
      if (text.toLowerCase().contains(mistake)) {
        errors.add(
            "Consider replacing '$mistake' with '${commonMistakes[mistake]}'");
      }
    }

    // Rule 5: Check for repeated words
    final words = text.split(' ');
    for (int i = 0; i < words.length - 1; i++) {
      if (words[i].toLowerCase() == words[i + 1].toLowerCase()) {
        errors.add("Repeated word detected: '${words[i]}'");
      }
    }

    // Rule 6: Check for sentence length (heuristic)
    final sentences = text.split(RegExp(r'[.!?]'));
    for (var sentence in sentences) {
      final wordsInSentence =
          sentence.trim().split(' ').where((w) => w.isNotEmpty).length;
      if (wordsInSentence > 50) {
        errors.add(
            "Long sentence detected ($wordsInSentence words). Consider breaking it up.");
      }
    }

    return errors;
  }

  static bool _isUpperCase(String char) {
    return char == char.toUpperCase() && char != char.toLowerCase();
  }
}
