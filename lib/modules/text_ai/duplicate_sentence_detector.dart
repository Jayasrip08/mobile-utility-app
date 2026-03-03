import 'dart:math';

/// Duplicate Sentence Detector using Classical AI: Pattern matching and similarity algorithms
class DuplicateSentenceDetector {
  /// Finds duplicate or near-duplicate sentences using similarity analysis
  static List<String> findDuplicates(String text,
      {double similarityThreshold = 0.8}) {
    if (text.trim().isEmpty) {
      return [];
    }

    // Extract sentences
    final sentences = _extractSentences(text);
    if (sentences.length < 2) {
      return [];
    }

    // Find duplicates using multiple methods
    final exactDuplicates = _findExactDuplicates(sentences);
    final similarDuplicates =
        _findSimilarSentences(sentences, similarityThreshold);

    // Combine results
    final allDuplicates = {...exactDuplicates, ...similarDuplicates};

    return allDuplicates.toList()..sort();
  }

  /// Advanced duplicate detection with detailed analysis
  static Map<String, dynamic> analyzeDuplicates(String text,
      {double similarityThreshold = 0.7}) {
    if (text.trim().isEmpty) {
      return {
        'totalSentences': 0,
        'duplicateCount': 0,
        'duplicatePercentage': 0,
        'exactDuplicates': [],
        'similarDuplicates': [],
        'similarityMatrix': [],
        'recommendations': 'No text to analyze'
      };
    }

    final sentences = _extractSentences(text);
    final totalSentences = sentences.length;

    if (totalSentences < 2) {
      return {
        'totalSentences': totalSentences,
        'duplicateCount': 0,
        'duplicatePercentage': 0,
        'exactDuplicates': [],
        'similarDuplicates': [],
        'similarityMatrix': [],
        'recommendations': 'Need at least 2 sentences for duplicate analysis'
      };
    }

    // Find different types of duplicates
    final exactDuplicates = _findExactDuplicates(sentences);
    final similarDuplicates =
        _findSimilarSentences(sentences, similarityThreshold);

    // Calculate similarity matrix
    final similarityMatrix = _calculateSimilarityMatrix(sentences);

    // Calculate statistics
    final duplicateCount = exactDuplicates.length + similarDuplicates.length;
    final duplicatePercentage =
        totalSentences > 0 ? (duplicateCount / totalSentences * 100) : 0;

    // Generate recommendations
    final recommendations = _generateRecommendations(
        exactDuplicates, similarDuplicates, duplicatePercentage.toDouble());

    return {
      'totalSentences': totalSentences,
      'duplicateCount': duplicateCount,
      'duplicatePercentage': duplicatePercentage.toStringAsFixed(1),
      'exactDuplicates': exactDuplicates,
      'similarDuplicates': similarDuplicates,
      'similarityMatrix': similarityMatrix,
      'recommendations': recommendations,
      'mostSimilarPair': _findMostSimilarPair(similarityMatrix, sentences),
      'uniqueSentenceCount': totalSentences - duplicateCount,
    };
  }

  /// Extract sentences from text
  static List<String> _extractSentences(String text) {
    // Normalize text
    String normalized = text.replaceAll('\n', ' ').replaceAll('\r', ' ');

    // Handle abbreviations to avoid false splits
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
      normalized = normalized.replaceAll(
          RegExp(r'\b' + RegExp.escape(abbr) + r'\b', caseSensitive: false),
          abbr.replaceAll('.', '_ABBR_'));
    }

    // Split sentences
    final rawSentences = normalized
        .split(RegExp(r'[.!?]+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    // Restore abbreviations and clean
    return rawSentences.map((sentence) {
      String restored = sentence;
      for (var abbr in abbreviations) {
        restored = restored.replaceAll(abbr.replaceAll('.', '_ABBR_'), abbr);
      }
      return restored.trim();
    }).toList();
  }

  /// Find exact duplicate sentences
  static List<String> _findExactDuplicates(List<String> sentences) {
    final seen = <String>{};
    final duplicates = <String>{};

    for (var sentence in sentences) {
      final normalized = _normalizeSentence(sentence);
      if (seen.contains(normalized)) {
        duplicates.add(sentence);
      } else {
        seen.add(normalized);
      }
    }

    return duplicates.toList();
  }

  /// Find similar sentences using cosine similarity
  static List<String> _findSimilarSentences(
      List<String> sentences, double threshold) {
    final similarSentences = <String>{};

    for (int i = 0; i < sentences.length; i++) {
      for (int j = i + 1; j < sentences.length; j++) {
        final similarity =
            _calculateSentenceSimilarity(sentences[i], sentences[j]);
        if (similarity >= threshold) {
          similarSentences.add(sentences[i]);
          similarSentences.add(sentences[j]);
        }
      }
    }

    return similarSentences.toList();
  }

  /// Calculate cosine similarity between two sentences
  static double _calculateSentenceSimilarity(
      String sentence1, String sentence2) {
    // Classical AI: Vector space model with cosine similarity

    // Tokenize and normalize
    final tokens1 = _tokenizeSentence(sentence1);
    final tokens2 = _tokenizeSentence(sentence2);

    // Create vocabulary
    final vocabulary = {...tokens1.keys, ...tokens2.keys};

    // Create vectors
    final vector1 = vocabulary.map((word) => tokens1[word] ?? 0).toList();
    final vector2 = vocabulary.map((word) => tokens2[word] ?? 0).toList();

    // Calculate cosine similarity
    double dotProduct = 0;
    double magnitude1 = 0;
    double magnitude2 = 0;

    for (int i = 0; i < vocabulary.length; i++) {
      dotProduct += vector1[i] * vector2[i];
      magnitude1 += vector1[i] * vector1[i];
      magnitude2 += vector2[i] * vector2[i];
    }

    if (magnitude1 == 0 || magnitude2 == 0) {
      return 0;
    }

    return dotProduct / (sqrt(magnitude1) * sqrt(magnitude2));
  }

  /// Tokenize sentence into word frequency map
  static Map<String, int> _tokenizeSentence(String sentence) {
    // Convert to lowercase and split into words
    final words = sentence
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((w) => w.isNotEmpty)
        .toList();

    // Count frequencies
    final frequency = <String, int>{};
    for (var word in words) {
      frequency[word] = (frequency[word] ?? 0) + 1;
    }

    return frequency;
  }

  /// Normalize sentence for exact comparison
  static String _normalizeSentence(String sentence) {
    return sentence.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Calculate similarity matrix for all sentence pairs
  static List<List<double>> _calculateSimilarityMatrix(List<String> sentences) {
    final matrix = List.generate(
        sentences.length, (_) => List.filled(sentences.length, 0.0));

    for (int i = 0; i < sentences.length; i++) {
      for (int j = i; j < sentences.length; j++) {
        if (i == j) {
          matrix[i][j] = 1.0; // Sentence is identical to itself
        } else {
          final similarity =
              _calculateSentenceSimilarity(sentences[i], sentences[j]);
          matrix[i][j] = similarity;
          matrix[j][i] = similarity; // Matrix is symmetric
        }
      }
    }

    return matrix;
  }

  /// Find the most similar pair of sentences
  static Map<String, dynamic> _findMostSimilarPair(
      List<List<double>> matrix, List<String> sentences) {
    if (sentences.length < 2) {
      return {'sentence1': '', 'sentence2': '', 'similarity': 0};
    }

    double maxSimilarity = 0;
    int bestI = 0, bestJ = 1;

    for (int i = 0; i < sentences.length; i++) {
      for (int j = i + 1; j < sentences.length; j++) {
        if (matrix[i][j] > maxSimilarity) {
          maxSimilarity = matrix[i][j];
          bestI = i;
          bestJ = j;
        }
      }
    }

    return {
      'sentence1': sentences[bestI],
      'sentence2': sentences[bestJ],
      'similarity': maxSimilarity.toStringAsFixed(3),
    };
  }

  /// Generate recommendations based on duplicate analysis
  static String _generateRecommendations(List<String> exactDuplicates,
      List<String> similarDuplicates, double duplicatePercentage) {
    final recommendations = <String>[];

    if (exactDuplicates.isNotEmpty) {
      recommendations.add(
          'Found ${exactDuplicates.length} exact duplicate sentences. Consider removing or rephrasing them.');
    }

    if (similarDuplicates.isNotEmpty) {
      recommendations.add(
          'Found ${similarDuplicates.length} similar sentences. Vary your sentence structure and vocabulary.');
    }

    if (duplicatePercentage > 30) {
      recommendations.add(
          'High duplication rate (${duplicatePercentage.toStringAsFixed(1)}%). Consider diversifying your content.');
    } else if (duplicatePercentage > 10) {
      recommendations.add(
          'Moderate duplication detected. Some repetition is acceptable for emphasis.');
    } else if (duplicatePercentage > 0) {
      recommendations
          .add('Minimal duplication detected. Your text has good variety.');
    } else {
      recommendations
          .add('No duplicates found. Your text has excellent variety.');
    }

    return recommendations.join('\n\n');
  }

  /// Find and highlight duplicate sentences in text
  static String highlightDuplicates(String text,
      {double similarityThreshold = 0.8}) {
    if (text.trim().isEmpty) {
      return text;
    }

    final duplicates =
        findDuplicates(text, similarityThreshold: similarityThreshold);

    if (duplicates.isEmpty) {
      return text;
    }

    String highlightedText = text;

    for (var duplicate in duplicates) {
      // Escape special regex characters
      final escaped = RegExp.escape(duplicate);
      // Highlight duplicate sentences
      highlightedText =
          highlightedText.replaceAll(RegExp(escaped), '⚠️$duplicate⚠️');
    }

    return highlightedText;
  }
}
