/// Sentence Counter using punctuation pattern analysis (Classical AI)
class SentenceCounter {
  /// Counts sentences using rule-based boundary detection
  static int countSentences(String text) {
    if (text.trim().isEmpty) {
      return 0;
    }

    // Classical AI: Rule-based sentence boundary detection

    // Step 1: Normalize text
    String normalizedText = text.replaceAll('\n', ' ').replaceAll('\r', ' ');

    // Step 2: Handle common abbreviations that shouldn't end sentences
    final abbreviations = {
      'dr.',
      'mr.',
      'mrs.',
      'ms.',
      'prof.',
      'rev.',
      'hon.',
      'st.',
      'jr.',
      'sr.',
      'ph.d.',
      'm.d.',
      'b.a.',
      'm.a.',
      'd.d.s.',
      'etc.',
      'e.g.',
      'i.e.',
      'vs.',
      'fig.',
      'no.',
      'vol.',
      'p.',
      'ch.',
      'sec.',
      'secs.',
      'min.',
      'mins.',
      'hr.',
      'hrs.',
      'jan.',
      'feb.',
      'mar.',
      'apr.',
      'jun.',
      'jul.',
      'aug.',
      'sep.',
      'oct.',
      'nov.',
      'dec.',
      'mon.',
      'tue.',
      'wed.',
      'thu.',
      'fri.',
      'sat.',
      'sun.'
    };

    // Temporarily replace abbreviations to avoid false sentence breaks
    for (var abbr in abbreviations) {
      normalizedText = normalizedText.replaceAll(
          RegExp(r'\b' + RegExp.escape(abbr) + r'\b', caseSensitive: false),
          abbr.replaceAll('.', '_ABBR_'));
    }

    // Step 3: Split by sentence-ending punctuation
    final sentences = normalizedText.split(RegExp(r'[.!?]+')).where((s) {
      return s.trim().isNotEmpty;
    }).toList();

    // Step 4: Restore abbreviations
    final restoredSentences = sentences.map((s) {
      String restored = s;
      for (var abbr in abbreviations) {
        restored = restored.replaceAll(abbr.replaceAll('.', '_ABBR_'), abbr);
      }
      return restored.trim();
    }).toList();

    return restoredSentences.length;
  }

  /// Analyzes sentence structure using heuristic rules
  static Map<String, dynamic> analyzeSentenceStructure(String text) {
    final sentenceCount = countSentences(text);
    if (sentenceCount == 0) {
      return {
        'sentenceCount': 0,
        'avgWordsPerSentence': 0,
        'avgCharsPerSentence': 0,
        'sentenceComplexity': 'N/A',
        'structureAnalysis': 'No sentences found'
      };
    }

    // Get individual sentences
    final sentences = _extractSentences(text);

    // Calculate statistics
    final wordCounts = sentences.map((s) => _countWordsInSentence(s)).toList();
    final charCounts = sentences.map((s) => s.length).toList();

    final avgWords = wordCounts.reduce((a, b) => a + b) / sentenceCount;
    final avgChars = charCounts.reduce((a, b) => a + b) / sentenceCount;

    // Analyze sentence complexity using heuristic rules
    String complexity = _analyzeComplexity(sentences, avgWords);

    // Structure analysis
    String structure = _analyzeStructure(sentences);

    return {
      'sentenceCount': sentenceCount,
      'avgWordsPerSentence': avgWords.toStringAsFixed(2),
      'avgCharsPerSentence': avgChars.toStringAsFixed(2),
      'sentenceComplexity': complexity,
      'structureAnalysis': structure,
      'shortestSentence': _findShortestSentence(sentences),
      'longestSentence': _findLongestSentence(sentences),
      'wordCounts': wordCounts,
    };
  }

  /// Extract individual sentences
  static List<String> _extractSentences(String text) {
    if (text.trim().isEmpty) return [];

    String normalizedText = text.replaceAll('\n', ' ').replaceAll('\r', ' ');

    // Handle abbreviations
    final abbreviations = {
      'dr.',
      'mr.',
      'mrs.',
      'ms.',
      'prof.',
      'etc.',
      'e.g.',
      'i.e.'
    };
    for (var abbr in abbreviations) {
      normalizedText = normalizedText.replaceAll(
          RegExp(r'\b' + RegExp.escape(abbr) + r'\b', caseSensitive: false),
          abbr.replaceAll('.', '_ABBR_'));
    }

    final sentences = normalizedText.split(RegExp(r'[.!?]+')).where((s) {
      return s.trim().isNotEmpty;
    }).map((s) {
      String restored = s;
      for (var abbr in abbreviations) {
        restored = restored.replaceAll(abbr.replaceAll('.', '_ABBR_'), abbr);
      }
      return restored.trim();
    }).toList();

    return sentences;
  }

  /// Count words in a single sentence
  static int _countWordsInSentence(String sentence) {
    return sentence.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  /// Analyze sentence complexity using heuristic rules
  static String _analyzeComplexity(List<String> sentences, double avgWords) {
    if (sentences.isEmpty) return 'N/A';

    // Count complex sentences (based on multiple heuristics)
    int complexCount = 0;
    for (var sentence in sentences) {
      // Heuristic 1: Sentence length > 25 words
      if (_countWordsInSentence(sentence) > 25) complexCount++;

      // Heuristic 2: Contains multiple clauses (and, but, because, although)
      final clauseMarkers = [
        ' and ',
        ' but ',
        ' because ',
        ' although ',
        ' while ',
        ' since '
      ];
      int clauseCount = 0;
      for (var marker in clauseMarkers) {
        if (sentence.toLowerCase().contains(marker)) clauseCount++;
      }
      if (clauseCount >= 2) complexCount++;

      // Heuristic 3: Contains parentheses or semicolons
      if (sentence.contains('(') || sentence.contains(';')) complexCount++;
    }

    final complexityRatio = complexCount / sentences.length;

    if (complexityRatio > 0.5) return 'High';
    if (complexityRatio > 0.2) return 'Medium';
    return 'Low';
  }

  /// Analyze sentence structure patterns
  static String _analyzeStructure(List<String> sentences) {
    if (sentences.isEmpty) return 'No sentences to analyze';

    // Check for variety in sentence beginnings
    final beginnings = sentences.map((s) {
      final words = s.split(' ');
      return words.isNotEmpty ? words[0].toLowerCase() : '';
    }).toSet();

    // Check for variety in sentence length
    final lengths = sentences.map((s) => _countWordsInSentence(s)).toList();
    final lengthVariety = lengths.toSet().length / sentences.length;

    if (beginnings.length < sentences.length * 0.3 && lengthVariety < 0.5) {
      return 'Sentence structure shows limited variety. Consider varying sentence beginnings and lengths.';
    }

    return 'Good sentence structure variety detected.';
  }

  static String _findShortestSentence(List<String> sentences) {
    if (sentences.isEmpty) return '';
    return sentences.reduce((a, b) => a.length < b.length ? a : b);
  }

  static String _findLongestSentence(List<String> sentences) {
    if (sentences.isEmpty) return '';
    return sentences.reduce((a, b) => a.length > b.length ? a : b);
  }
}
