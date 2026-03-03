import 'dart:math';

/// Rule-based Text Summarizer using Classical AI techniques
class TextSummarizer {
  /// Summarizes text using extractive summarization (Classical AI: Statistical and heuristic methods)
  static String summarize(String text, {double compressionRatio = 0.3}) {
    if (text.trim().isEmpty) {
      return '';
    }

    compressionRatio = compressionRatio.clamp(0.1, 0.9);
    final sentences = _extractSentences(text);
    if (sentences.length <= 3) {
      return text;
    }

    final sentenceScores = _scoreSentences(sentences, text);
    final selectedSentences = _selectTopSentences(sentences, sentenceScores, compressionRatio);
    return _reconstructSummary(selectedSentences, sentences);
  }

  /// Advanced summarization with multiple algorithms
  static Map<String, dynamic> summarizeAdvanced(String text, {double compressionRatio = 0.3}) {
    if (text.trim().isEmpty) {
      return {
        'summary': '',
        'originalLength': 0,
        'summaryLength': 0,
        'compressionRate': 0,
        'algorithmUsed': 'N/A',
        'sentenceScores': [],
        'extractedSentences': [],
      };
    }

    compressionRatio = compressionRatio.clamp(0.1, 0.9);
    final sentences = _extractSentences(text);
    final originalLength = sentences.length;

    if (originalLength <= 3) {
      return {
        'summary': text,
        'originalLength': originalLength,
        'summaryLength': originalLength,
        'compressionRate': 100.0,
        'algorithmUsed': 'Original (too short to summarize)',
        'sentenceScores': [],
        'extractedSentences': sentences,
      };
    }

    final tfidfSummary = _summarizeUsingTFIDF(sentences, text, compressionRatio);
    final positionSummary = _summarizeUsingPosition(sentences, compressionRatio);
    final combinedSummary = _summarizeUsingCombined(sentences, text, compressionRatio);

    final tfidfScore = _evaluateSummary(tfidfSummary, text);
    final positionScore = _evaluateSummary(positionSummary, text);
    final combinedScore = _evaluateSummary(combinedSummary, text);

    String bestSummary;
    String algorithmUsed;

    if (combinedScore >= tfidfScore && combinedScore >= positionScore) {
      bestSummary = combinedSummary;
      algorithmUsed = 'Combined Heuristic';
    } else if (tfidfScore >= positionScore) {
      bestSummary = tfidfSummary;
      algorithmUsed = 'TF-IDF Based';
    } else {
      bestSummary = positionSummary;
      algorithmUsed = 'Position Based';
    }

    final summarySentences = _extractSentences(bestSummary);
    final summaryLength = summarySentences.length;
    final compressionRate = originalLength > 0 ? (1 - (summaryLength / originalLength)) * 100 : 0;
    final sentenceScores = _scoreSentences(sentences, text);

    return {
      'summary': bestSummary,
      'originalLength': originalLength,
      'summaryLength': summaryLength,
      'compressionRate': compressionRate.toStringAsFixed(1),
      'algorithmUsed': algorithmUsed,
      'sentenceScores': sentenceScores,
      'extractedSentences': summarySentences,
      'algorithmScores': {
        'TF-IDF': tfidfScore.toStringAsFixed(3),
        'Position': positionScore.toStringAsFixed(3),
        'Combined': combinedScore.toStringAsFixed(3),
      },
    };
  }

  static List<String> _extractSentences(String text) {
    String normalized = text.replaceAll('\n', ' ').replaceAll('\r', ' ');

    final abbreviations = {
      'dr.', 'mr.', 'mrs.', 'ms.', 'prof.', 'etc.', 'e.g.', 'i.e.',
      'fig.', 'vol.', 'no.', 'p.', 'ch.', 'sec.', 'vs.',
      'jan.', 'feb.', 'mar.', 'apr.', 'jun.', 'jul.', 'aug.',
      'sep.', 'oct.', 'nov.', 'dec.',
    };

    for (var abbr in abbreviations) {
      normalized = normalized.replaceAll(
        RegExp(r'\b' + RegExp.escape(abbr) + r'\b', caseSensitive: false),
        abbr.replaceAll('.', '_ABBR_'),
      );
    }

    final rawSentences = normalized
        .split(RegExp(r'[.!?]+'))
        .map((s) => s.replaceAll('_ABBR_', '.').trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return rawSentences;
  }

  static List<Map<String, dynamic>> _scoreSentences(List<String> sentences, String text) {
    final wordFrequencies = <String, int>{};
    final totalWords = <String>[];

    for (var sentence in sentences) {
      final tokens = _tokenizeSentence(sentence);
      tokens.forEach((word, count) {
        wordFrequencies[word] = (wordFrequencies[word] ?? 0) + count;
        for (int i = 0; i < count; i++) {
          totalWords.add(word);
        }
      });
    }

    final totalWordCount = totalWords.length;
    final idf = <String, double>{};
    for (var word in wordFrequencies.keys) {
      int containing = sentences.where((s) => s.toLowerCase().contains(word)).length;
      idf[word] = containing > 0 ? log(sentences.length / containing) : 0.0;
    }

    final scores = <Map<String, dynamic>>[];
    for (int i = 0; i < sentences.length; i++) {
      final sentence = sentences[i];
      final tokens = _tokenizeSentence(sentence);

      double tfidf = 0;
      tokens.forEach((word, count) {
        final tf = totalWordCount > 0 ? count / totalWordCount : 0;
        tfidf += tf * (idf[word] ?? 0);
      });

      final cueScore = _calculateCuePhraseScore(sentence);
      double positionScore = 0;
      if (i == 0 || i == sentences.length - 1) {
        positionScore = 1.0;
      } else {
        positionScore = 1 - (i / (sentences.length - 1));
      }

      final combined = tfidf * 0.5 + cueScore * 0.3 + positionScore * 0.2;
      scores.add({
        'index': i,
        'tfidf': tfidf,
        'cueScore': cueScore,
        'positionScore': positionScore,
        'normalizedScore': combined.toString(),
      });
    }
    return scores;
  }

  static Map<String, int> _tokenizeSentence(String sentence) {
    final tokens = <String, int>{};
    final words = sentence
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty);
    for (var word in words) {
      tokens[word] = (tokens[word] ?? 0) + 1;
    }
    return tokens;
  }

  static double _calculateCuePhraseScore(String sentence) {
    final cuePhrases = [
      'in conclusion', 'to summarize', 'the purpose', 'this paper', 'we propose',
      'important', 'significant', 'notably', 'specifically', 'in particular',
      'however', 'therefore', 'consequently', 'as a result', 'thus',
      'in summary', 'overall', 'in essence', 'the main', 'key finding'
    ];

    final sentenceLower = sentence.toLowerCase();
    for (var phrase in cuePhrases) {
      if (sentenceLower.contains(phrase)) {
        return 1.0;
      }
    }
    return 0.2;
  }

  static List<String> _selectTopSentences(
    List<String> sentences,
    List<Map<String, dynamic>> scores,
    double compressionRatio,
  ) {
    final targetCount = (sentences.length * compressionRatio).ceil().clamp(1, sentences.length);
    final sorted = List<Map<String, dynamic>>.from(scores)
      ..sort((a, b) => double.parse(b['normalizedScore'] ?? '0').compareTo(double.parse(a['normalizedScore'] ?? '0')));

    final topIndices = sorted.take(targetCount).map((s) => scores.indexOf(s)).toList();
    topIndices.sort();
    return topIndices.map((index) => sentences[index]).toList();
  }

  static String _reconstructSummary(List<String> selectedSentences, List<String> allSentences) {
    final summary = selectedSentences.join('. ');
    return summary + (summary.isNotEmpty && !summary.endsWith('.') ? '.' : '');
  }

  static String _summarizeUsingTFIDF(List<String> sentences, String text, double compressionRatio) {
    final scores = _scoreSentences(sentences, text);
    final selected = _selectTopSentences(sentences, scores, compressionRatio);
    return _reconstructSummary(selected, sentences);
  }

  static String _summarizeUsingPosition(List<String> sentences, double compressionRatio) {
    final targetCount = (sentences.length * compressionRatio).ceil().clamp(1, sentences.length);
    final selected = <String>[];

    if (targetCount >= 1) {
      selected.add(sentences[0]);
    }

    if (targetCount >= 2) {
      selected.add(sentences[sentences.length - 1]);
    }

    if (targetCount > 2) {
      final middleStart = (sentences.length / 3).floor();
      final middleEnd = (2 * sentences.length / 3).floor();

      for (int i = middleStart; i < middleEnd && selected.length < targetCount; i++) {
        if (!selected.contains(sentences[i])) {
          selected.add(sentences[i]);
        }
      }
    }

    selected.sort((a, b) => sentences.indexOf(a).compareTo(sentences.indexOf(b)));
    return _reconstructSummary(selected, sentences);
  }

  static String _summarizeUsingCombined(List<String> sentences, String text, double compressionRatio) {
    final scores = _scoreSentences(sentences, text);
    final selected = _selectTopSentences(sentences, scores, compressionRatio);
    return _reconstructSummary(selected, sentences);
  }

  static double _evaluateSummary(String summary, String original) {
    if (summary.isEmpty || original.isEmpty) return 0;

    final summarySentences = _extractSentences(summary);
    final originalSentences = _extractSentences(original);

    if (summarySentences.isEmpty || originalSentences.isEmpty) return 0;

    double coverage = 0;
    for (var sSentence in summarySentences) {
      for (var oSentence in originalSentences) {
        if (_calculateSentenceSimilarity(sSentence, oSentence) > 0.7) {
          coverage++;
          break;
        }
      }
    }
    coverage /= originalSentences.length;

    final compression = summarySentences.length / originalSentences.length;
    final compressionScore = 1 - (compression - 0.3).abs() / 0.7;

    double diversity = 0;
    if (summarySentences.length > 1) {
      double totalSimilarity = 0;
      int comparisons = 0;

      for (int i = 0; i < summarySentences.length; i++) {
        for (int j = i + 1; j < summarySentences.length; j++) {
          totalSimilarity += _calculateSentenceSimilarity(summarySentences[i], summarySentences[j]);
          comparisons++;
        }
      }

      diversity = comparisons > 0 ? 1 - (totalSimilarity / comparisons) : 1;
    } else {
      diversity = 1;
    }

    return (coverage * 0.4 + compressionScore * 0.3 + diversity * 0.3);
  }

  static double _calculateSentenceSimilarity(String s1, String s2) {
    final tokens1 = _tokenizeSentence(s1);
    final tokens2 = _tokenizeSentence(s2);

    final vocab = <String>{...tokens1.keys, ...tokens2.keys};
    if (vocab.isEmpty) return 0;

    double dot = 0, mag1 = 0, mag2 = 0;

    for (var word in vocab) {
      final v1 = tokens1[word] ?? 0;
      final v2 = tokens2[word] ?? 0;
      dot += v1 * v2;
      mag1 += v1 * v1;
      mag2 += v2 * v2;
    }

    return mag1 > 0 && mag2 > 0 ? dot / (sqrt(mag1) * sqrt(mag2)) : 0;
  }
}
















