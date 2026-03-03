import 'dart:math';
class ReadabilityScore {
  /// Calculate readability score for text
  static double calculate(String text) {
    if (text.isEmpty) return 0.0;
    
    // Simple Flesch Reading Ease calculation
    int sentences = text.split(RegExp(r'[.!?]+')).length;
    int words = text.split(RegExp(r'\s+')).where((w) => w.trim().isNotEmpty).length;
    
    if (sentences == 0 || words == 0) return 0.0;
    
    // Count syllables (simplified)
    int syllables = text.toLowerCase().split(RegExp(r'[aeiou]+')).length;
    
    double score = 206.835 - 1.015 * (words / sentences) - 84.6 * (syllables / words);
    
    // Ensure score is between 0 and 100
    return score.clamp(0, 100);
  }
  
  // Other existing methods...
  
  /// Calculates multiple readability scores using classical formulas
  static Map<String, dynamic> calculateAllScores(String text) {
    if (text.trim().isEmpty) {
      return {
        'error': 'Text is empty',
        'fleschReadingEase': 0,
        'fleschKincaidGrade': 0,
        'gunningFog': 0,
        'smogIndex': 0,
        'colemanLiau': 0,
        'automatedReadability': 0,
        'overallReadability': 'N/A'
      };
    }
    
    // Basic statistics
    final wordCount = _countWords(text);
    final sentenceCount = _countSentences(text);
    final syllableCount = _countSyllables(text);
    final complexWordCount = _countComplexWords(text);
    
    // Calculate various readability scores
    final fleschReadingEase = _calculateFleschReadingEase(wordCount, sentenceCount, syllableCount);
    final fleschKincaidGrade = _calculateFleschKincaidGrade(wordCount, sentenceCount, syllableCount);
    final gunningFog = _calculateGunningFog(wordCount, sentenceCount, complexWordCount);
    final smogIndex = _calculateSMOG(wordCount, complexWordCount);
    final colemanLiau = _calculateColemanLiau(text, wordCount, sentenceCount);
    final automatedReadability = _calculateAutomatedReadability(wordCount, sentenceCount);
    
    // Determine overall readability level
    final overallReadability = _determineReadabilityLevel(fleschReadingEase);
    
    return {
      'fleschReadingEase': fleschReadingEase.toStringAsFixed(1),
      'fleschKincaidGrade': fleschKincaidGrade.toStringAsFixed(1),
      'gunningFog': gunningFog.toStringAsFixed(1),
      'smogIndex': smogIndex.toStringAsFixed(1),
      'colemanLiau': colemanLiau.toStringAsFixed(1),
      'automatedReadability': automatedReadability.toStringAsFixed(1),
      'overallReadability': overallReadability,
      'wordCount': wordCount,
      'sentenceCount': sentenceCount,
      'avgWordsPerSentence': sentenceCount > 0 ? (wordCount / sentenceCount).toStringAsFixed(1) : '0',
      'avgSyllablesPerWord': wordCount > 0 ? (syllableCount / wordCount).toStringAsFixed(1) : '0',
      'complexWordPercentage': wordCount > 0 ? ((complexWordCount / wordCount) * 100).toStringAsFixed(1) : '0',
    };
  }
  
  /// Classical AI: Flesch Reading Ease formula
  static double _calculateFleschReadingEase(int wordCount, int sentenceCount, int syllableCount) {
    if (wordCount == 0 || sentenceCount == 0) return 0;
    
    final avgSentenceLength = wordCount / sentenceCount;
    final avgSyllablesPerWord = syllableCount / wordCount;
    
    // Formula: 206.835 - 1.015 * (total words / total sentences) - 84.6 * (total syllables / total words)
    return 206.835 - (1.015 * avgSentenceLength) - (84.6 * avgSyllablesPerWord);
  }
  
  /// Classical AI: Flesch-Kincaid Grade Level formula
  static double _calculateFleschKincaidGrade(int wordCount, int sentenceCount, int syllableCount) {
    if (wordCount == 0 || sentenceCount == 0) return 0;
    
    final avgSentenceLength = wordCount / sentenceCount;
    final avgSyllablesPerWord = syllableCount / wordCount;
    
    // Formula: 0.39 * (total words / total sentences) + 11.8 * (total syllables / total words) - 15.59
    return (0.39 * avgSentenceLength) + (11.8 * avgSyllablesPerWord) - 15.59;
  }
  
  /// Classical AI: Gunning Fog Index formula
  static double _calculateGunningFog(int wordCount, int sentenceCount, int complexWordCount) {
    if (wordCount == 0 || sentenceCount == 0) return 0;
    
    final avgSentenceLength = wordCount / sentenceCount;
    final percentageComplexWords = (complexWordCount / wordCount) * 100;
    
    // Formula: 0.4 * [(words/sentences) + 100 * (complex words/words)]
    return 0.4 * (avgSentenceLength + percentageComplexWords);
  }
  
  /// Classical AI: SMOG (Simple Measure of Gobbledygook) formula
  static double _calculateSMOG(int wordCount, int complexWordCount) {
    if (wordCount < 30) return 0;
    
    // Formula: 1.0430 * sqrt(complex words * (30 / total words)) + 3.1291
    return 1.0430 * sqrt(complexWordCount * (30 / wordCount)) + 3.1291;
  }
  
  /// Classical AI: Coleman-Liau Index formula
  static double _calculateColemanLiau(String text, int wordCount, int sentenceCount) {
    if (wordCount == 0 || sentenceCount == 0) return 0;
    
    final letterCount = text.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    final avgLettersPer100Words = (letterCount / wordCount) * 100;
    final avgSentencesPer100Words = (sentenceCount / wordCount) * 100;
    
    // Formula: 0.0588 * L - 0.296 * S - 15.8
    return (0.0588 * avgLettersPer100Words) - (0.296 * avgSentencesPer100Words) - 15.8;
  }
  
  /// Classical AI: Automated Readability Index (ARI)
  static double _calculateAutomatedReadability(int wordCount, int sentenceCount) {
    if (wordCount == 0 || sentenceCount == 0) return 0;
    
    final characters = wordCount * 4.5; // Approximate average characters per word
    final avgSentenceLength = wordCount / sentenceCount;
    
    // Formula: 4.71 * (characters/words) + 0.5 * (words/sentences) - 21.43
    return (4.71 * (characters / wordCount)) + (0.5 * avgSentenceLength) - 21.43;
  }
  
  /// Determine readability level based on Flesch Reading Ease
  static String _determineReadabilityLevel(double fleschScore) {
    if (fleschScore >= 90) return 'Very Easy (5th grade)';
    if (fleschScore >= 80) return 'Easy (6th grade)';
    if (fleschScore >= 70) return 'Fairly Easy (7th grade)';
    if (fleschScore >= 60) return 'Standard (8th-9th grade)';
    if (fleschScore >= 50) return 'Fairly Difficult (10th-12th grade)';
    if (fleschScore >= 30) return 'Difficult (College)';
    return 'Very Difficult (College graduate)';
  }
  
  /// Helper methods
  static int _countWords(String text) {
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }
  
  static int _countSentences(String text) {
    // Simple sentence counting (can be improved)
    return text.split(RegExp(r'[.!?]+')).where((s) => s.trim().isNotEmpty).length;
  }
  
  static int _countSyllables(String text) {
    final words = text.toLowerCase().split(RegExp(r'\W+')).where((w) => w.isNotEmpty).toList();
    int totalSyllables = 0;
    
    for (var word in words) {
      totalSyllables += _countSyllablesInWord(word);
    }
    
    return totalSyllables;
  }
  
  static int _countSyllablesInWord(String word) {
    // Classical AI: Syllable counting using vowel pattern recognition
    word = word.toLowerCase();
    
    // Count vowel groups
    final vowelGroups = RegExp(r'[aeiouy]+').allMatches(word);
    int syllableCount = vowelGroups.length;
    
    // Adjustments based on common patterns
    if (word.endsWith('e') && !word.endsWith('le') && syllableCount > 1) {
      syllableCount--;
    }
    
    if (word.endsWith('ed') && !RegExp(r'[td]ed$').hasMatch(word)) {
      syllableCount--;
    }
    
    if (word.endsWith('es') && !RegExp(r'[szx]es$').hasMatch(word)) {
      syllableCount--;
    }
    
    // Minimum one syllable
    return syllableCount > 0 ? syllableCount : 1;
  }
  
  static int _countComplexWords(String text) {
    final words = text.toLowerCase().split(RegExp(r'\W+')).where((w) => w.isNotEmpty).toList();
    int complexCount = 0;
    
    for (var word in words) {
      if (_isComplexWord(word)) {
        complexCount++;
      }
    }
    
    return complexCount;
  }
  
  static bool _isComplexWord(String word) {
    // Classical AI: Complex word detection using syllable count and heuristic rules
    final syllableCount = _countSyllablesInWord(word);
    
    // Words with 3+ syllables are considered complex
    if (syllableCount >= 3) {
      return true;
    }
    
    // Specific complex word patterns
    final complexPatterns = [
      'ing\$', 'ed\$', 'ly\$', 'ment\$', 'tion\$', 'sion\$', 'ence\$', 'ance\$',
      'able\$', 'ible\$', 'ity\$', 'ty\$', 'ive\$', 'ative\$', 'itive\$',
      'al\$', 'ial\$', 'ual\$', 'ous\$', 'ious\$', 'eous\$', 'ful\$', 'less\$',
      'ness\$', 'ship\$', 'hood\$', 'dom\$', 'ism\$', 'ist\$', 'er\$', 'or\$',
      'ar\$', 'ant\$', 'ent\$', 'age\$', 'ary\$', 'ery\$', 'ory\$', 'ize\$',
      'ise\$', 'ify\$', 'ate\$', 'en\$'
    ];
    
    for (var pattern in complexPatterns) {
      if (RegExp(pattern).hasMatch(word)) {
        return true;
      }
    }
    
    return false;
  }
}


















