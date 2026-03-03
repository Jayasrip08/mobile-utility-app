/// Word Counter using pattern recognition (Classical AI)
class WordCounter {
  /// Counts words in text using regex pattern matching
  static int countWords(String text) {
    if (text.trim().isEmpty) {
      return 0;
    }

    // Classical AI: Pattern recognition using regex
    // Split by any non-word character (punctuation, spaces, etc.)
    final words = text.split(RegExp(r'\s+')).where((word) {
      // Filter out empty strings and pure punctuation
      return word.isNotEmpty && RegExp(r'\w').hasMatch(word);
    }).toList();

    return words.length;
  }

  /// Counts characters (including spaces)
  static int countCharacters(String text) {
    return text.length;
  }

  /// Counts characters (excluding spaces)
  static int countCharactersNoSpaces(String text) {
    return text.replaceAll(RegExp(r'\s+'), '').length;
  }

  /// Counts sentences using punctuation pattern matching
  static int countSentences(String text) {
    if (text.trim().isEmpty) {
      return 0;
    }

    // Classical AI: Pattern recognition for sentence boundaries
    final sentences = text.split(RegExp(r'[.!?]+')).where((s) {
      return s.trim().isNotEmpty;
    }).toList();

    return sentences.length;
  }

  /// Counts paragraphs
  static int countParagraphs(String text) {
    if (text.trim().isEmpty) {
      return 0;
    }

    // Split by double newlines or combination of newline and spaces
    final paragraphs = text.split(RegExp(r'\n\s*\n')).where((p) {
      return p.trim().isNotEmpty;
    }).toList();

    return paragraphs.length;
  }

  /// Advanced statistics using heuristic analysis
  static Map<String, dynamic> getAdvancedStats(String text) {
    final wordCount = countWords(text);
    final sentenceCount = countSentences(text);
    final paragraphCount = countParagraphs(text);

    double avgWordsPerSentence =
        sentenceCount > 0 ? wordCount / sentenceCount : 0;
    double avgSentencesPerParagraph =
        paragraphCount > 0 ? sentenceCount / paragraphCount : 0;
    double avgWordLength = _calculateAverageWordLength(text);

    return {
      'wordCount': wordCount,
      'sentenceCount': sentenceCount,
      'paragraphCount': paragraphCount,
      'characterCount': countCharacters(text),
      'characterCountNoSpaces': countCharactersNoSpaces(text),
      'avgWordsPerSentence': avgWordsPerSentence.toStringAsFixed(2),
      'avgSentencesPerParagraph': avgSentencesPerParagraph.toStringAsFixed(2),
      'avgWordLength': avgWordLength.toStringAsFixed(2),
      'readingTimeMinutes': _calculateReadingTime(text),
    };
  }

  /// Calculate average word length (heuristic)
  static double _calculateAverageWordLength(String text) {
    final words =
        text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return 0;

    final totalLength = words.fold(0, (sum, word) => sum + word.length);
    return totalLength / words.length;
  }

  /// Calculate reading time based on average reading speed (250 words/minute)
  static double _calculateReadingTime(String text) {
    final wordCount = countWords(text);
    return wordCount / 250.0; // 250 words per minute average
  }
}
