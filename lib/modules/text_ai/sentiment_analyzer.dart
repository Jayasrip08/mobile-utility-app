import 'dart:math';

/// Sentiment Analyzer using Classical AI: Rule-based and lexicon-based approaches
class SentimentAnalyzer {
  /// Sentiment lexicon (positive and negative words with weights)
  static final Map<String, double> _positiveLexicon = {
    'good': 1.0,
    'great': 1.2,
    'excellent': 1.5,
    'awesome': 1.3,
    'wonderful': 1.4,
    'fantastic': 1.4,
    'amazing': 1.3,
    'perfect': 1.5,
    'best': 1.2,
    'better': 1.0,
    'happy': 1.2,
    'joy': 1.3,
    'joyful': 1.3,
    'pleased': 1.1,
    'delighted': 1.3,
    'satisfied': 1.0,
    'content': 0.9,
    'glad': 1.0,
    'cheerful': 1.1,
    'jolly': 1.0,
    'love': 1.5,
    'adore': 1.4,
    'like': 0.8,
    'enjoy': 1.0,
    'appreciate': 1.0,
    'valuable': 1.1,
    'worthwhile': 1.0,
    'beneficial': 1.0,
    'helpful': 0.9,
    'supportive': 0.9,
    'encouraging': 0.9,
    'inspiring': 1.1,
    'motivating': 1.0,
    'success': 1.2,
    'successful': 1.2,
    'achieve': 1.0,
    'accomplish': 1.0,
    'win': 1.1,
    'winning': 1.1,
    'victory': 1.3,
    'triumph': 1.3,
    'beautiful': 1.2,
    'gorgeous': 1.3,
    'stunning': 1.3,
    'lovely': 1.1,
    'peaceful': 0.9,
    'calm': 0.8,
    'relaxed': 0.8,
    'comfortable': 0.8,
    'easy': 0.7,
    'simple': 0.6,
    'clear': 0.7,
    'understandable': 0.7,
    'smart': 1.0,
    'intelligent': 1.0,
    'brilliant': 1.3,
    'clever': 1.0,
    'kind': 1.0,
    'generous': 1.1,
    'compassionate': 1.1,
    'caring': 1.0,
    'honest': 1.0,
    'trustworthy': 1.0,
    'reliable': 0.9,
    'dependable': 0.9,
    'fun': 1.0,
    'funny': 1.0,
    'humorous': 1.0,
    'entertaining': 0.9,
    'exciting': 1.1,
    'thrilling': 1.2,
    'adventurous': 1.0,
    'interesting': 0.8,
    'hope': 1.0,
    'hopeful': 1.0,
    'optimistic': 1.0,
    'positive': 1.1,
    'confident': 1.0,
    'certain': 0.8,
    'sure': 0.7,
    'definite': 0.7,
    'fresh': 0.7,
    'new': 0.6,
    'innovative': 1.0,
    'creative': 1.0,
    'powerful': 1.0,
    'strong': 0.9,
    'mighty': 1.1,
    'forceful': 0.9,
    'safe': 0.8,
    'secure': 0.8,
    'protected': 0.8,
    'guarded': 0.7,
    'rich': 0.9,
    'wealthy': 0.9,
    'prosperous': 1.0,
    'affluent': 0.9,
    'healthy': 0.9,
    'fit': 0.8,
    'well': 0.7,
    'vibrant': 0.9,
    'thank': 0.8,
    'thanks': 0.8,
    'thankful': 0.9,
    'grateful': 1.0,
    'welcome': 0.7,
    'inviting': 0.8,
    'welcoming': 0.8,
    'friendly': 0.9,
    'polite': 0.8,
    'courteous': 0.8,
    'respectful': 0.9,
    'considerate': 0.9,
    'brave': 1.0,
    'courageous': 1.1,
    'bold': 0.9,
    'fearless': 1.0,
    'lucky': 0.8,
    'fortunate': 0.9,
    'blessed': 1.0,
    'favored': 0.8,
  };

  static final Map<String, double> _negativeLexicon = {
    'bad': 1.0,
    'terrible': 1.5,
    'awful': 1.4,
    'horrible': 1.5,
    'worst': 1.5,
    'poor': 1.0,
    'worse': 1.2,
    'pathetic': 1.4,
    'disappointing': 1.2,
    'sad': 1.2,
    'unhappy': 1.1,
    'miserable': 1.4,
    'depressed': 1.3,
    'angry': 1.3,
    'mad': 1.2,
    'furious': 1.5,
    'outraged': 1.4,
    'hate': 1.5,
    'despise': 1.4,
    'loathe': 1.5,
    'dislike': 1.0,
    'worthless': 1.4,
    'useless': 1.3,
    'pointless': 1.2,
    'meaningless': 1.2,
    'failure': 1.3,
    'failed': 1.2,
    'lose': 1.1,
    'losing': 1.1,
    'problem': 1.0,
    'issue': 0.9,
    'trouble': 1.0,
    'difficulty': 0.9,
    'dangerous': 1.2,
    'risky': 1.1,
    'harmful': 1.2,
    'damaging': 1.1,
    'painful': 1.2,
    'hurt': 1.1,
    'suffering': 1.3,
    'agony': 1.4,
    'stupid': 1.3,
    'dumb': 1.2,
    'idiotic': 1.4,
    'foolish': 1.1,
    'ugly': 1.2,
    'hideous': 1.4,
    'unattractive': 1.1,
    'repulsive': 1.3,
    'anxious': 1.1,
    'nervous': 1.0,
    'worried': 1.0,
    'scared': 1.1,
    'fear': 1.2,
    'afraid': 1.1,
    'terrified': 1.4,
    'frightened': 1.2,
    'tired': 0.9,
    'exhausted': 1.1,
    'fatigued': 1.0,
    'weary': 0.9,
    'boring': 1.1,
    'dull': 1.0,
    'tedious': 1.1,
    'monotonous': 1.0,
    'confusing': 1.0,
    'complicated': 0.9,
    'complex': 0.8,
    'difficult': 0.9,
    'expensive': 0.9,
    'costly': 0.9,
    'overpriced': 1.1,
    'waste': 1.0,
    'slow': 0.9,
    'delayed': 0.9,
    'late': 0.9,
    'behind': 0.8,
    'wrong': 1.0,
    'incorrect': 0.9,
    'mistaken': 0.9,
    'error': 0.9,
    'fake': 1.2,
    'false': 1.1,
    'fraud': 1.4,
    'deceptive': 1.2,
    'mean': 1.2,
    'cruel': 1.4,
    'evil': 1.5,
    'wicked': 1.4,
    'selfish': 1.2,
    'greedy': 1.2,
    'stingy': 1.1,
    'miserly': 1.1,
    'lonely': 1.2,
    'alone': 1.0,
    'isolated': 1.1,
    'abandoned': 1.3,
    'weak': 1.0,
    'feeble': 1.1,
    'fragile': 0.9,
    'vulnerable': 1.0,
    'sick': 1.1,
    'ill': 1.0,
    'unwell': 0.9,
    'diseased': 1.2,
    'dirty': 1.1,
    'filthy': 1.3,
    'grimy': 1.1,
    'unclean': 1.0,
    'noisy': 0.8,
    'loud': 0.7,
    'disturbing': 1.0,
    'annoying': 1.0,
    'stressful': 1.1,
    'tense': 1.0,
    'pressured': 0.9,
    'overwhelmed': 1.1,
    'confused': 0.9,
    'uncertain': 0.8,
    'doubtful': 0.8,
    'skeptical': 0.8,
    'jealous': 1.2,
    'envious': 1.1,
    'resentful': 1.2,
    'bitter': 1.1,
    'guilty': 1.1,
    'ashamed': 1.2,
    'embarrassed': 1.0,
    'humiliated': 1.3,
    'hopeless': 1.3,
    'desperate': 1.2,
    'helpless': 1.1,
    'powerless': 1.0,
  };

  /// Negation words that reverse sentiment
  static final Set<String> _negationWords = {
    'not',
    'no',
    'never',
    'none',
    'nothing',
    'nowhere',
    'neither',
    'nor',
    'cannot',
    'can\'t',
    'don\'t',
    'doesn\'t',
    'didn\'t',
    'isn\'t',
    'aren\'t',
    'wasn\'t',
    'weren\'t',
    'haven\'t',
    'hasn\'t',
    'hadn\'t',
    'won\'t',
    'wouldn\'t',
    'shouldn\'t',
    'couldn\'t',
    'mightn\'t',
    'mustn\'t'
  };

  /// Intensifier words that amplify sentiment
  static final Map<String, double> _intensifiers = {
    'very': 1.5,
    'extremely': 2.0,
    'absolutely': 2.0,
    'completely': 1.8,
    'totally': 1.8,
    'utterly': 2.0,
    'perfectly': 1.5,
    'entirely': 1.5,
    'really': 1.3,
    'truly': 1.3,
    'highly': 1.4,
    'greatly': 1.4,
    'deeply': 1.5,
    'strongly': 1.4,
    'particularly': 1.2,
    'especially': 1.2,
    'exceptionally': 1.8,
    'incredibly': 1.8,
    'remarkably': 1.6,
    'significantly': 1.5,
    'substantially': 1.5,
    'considerably': 1.4,
    'immensely': 1.8,
    'enormously': 1.8,
    'tremendously': 1.8,
    'extraordinarily': 1.9,
    'unusually': 1.5,
    'awfully': 1.7,
    'terribly': 1.7,
    'horribly': 1.8,
    'dreadfully': 1.8,
    'frightfully': 1.7,
    'exceedingly': 1.6,
    'intensely': 1.6,
  };

  /// Diminisher words that reduce sentiment
  static final Map<String, double> _diminishers = {
    'slightly': 0.5,
    'somewhat': 0.6,
    'moderately': 0.7,
    'fairly': 0.7,
    'quite': 0.8,
    'rather': 0.8,
    'relatively': 0.7,
    'comparatively': 0.7,
    'reasonably': 0.8,
    'acceptably': 0.8,
    'tolerably': 0.7,
    'partially': 0.6,
    'partly': 0.6,
    'halfway': 0.5,
    'incompletely': 0.4,
    'marginally': 0.4,
    'barely': 0.3,
    'hardly': 0.3,
    'scarcely': 0.3,
    'almost': 0.6,
    'nearly': 0.6,
    'practically': 0.7,
    'virtually': 0.7,
    'essentially': 0.8,
    'basically': 0.8,
    'fundamentally': 0.8,
    'minimally': 0.4,
    'negligibly': 0.3,
    'insignificantly': 0.3,
  };

  /// Analyze sentiment of text using Classical AI: Lexicon-based approach with rules
  static Map<String, dynamic> analyze(String text) {
    if (text.trim().isEmpty) {
      return {
        'sentiment': 'neutral',
        'score': 0.0,
        'confidence': 0.0,
        'positiveWords': [],
        'negativeWords': [],
        'analysis': 'Text is empty',
        'magnitude': 0.0,
      };
    }

    // Tokenize text
    final words = _tokenizeText(text);

    double totalScore = 0.0;
    final positiveWords = <String>[];
    final negativeWords = <String>[];

    // Analyze each word with context
    for (int i = 0; i < words.length; i++) {
      final word = words[i].toLowerCase();
      double wordScore = 0.0;
      double modifier = 1.0;

      // Check for sentiment words
      if (_positiveLexicon.containsKey(word)) {
        wordScore = _positiveLexicon[word]!;
        positiveWords.add(words[i]);
      } else if (_negativeLexicon.containsKey(word)) {
        wordScore = -_negativeLexicon[word]!;
        negativeWords.add(words[i]);
      }

      // Apply context rules (Classical AI: Rule-based context analysis)
      if (wordScore != 0) {
        // Check for negations in previous words
        for (int j = max(0, i - 3); j < i; j++) {
          if (_negationWords.contains(words[j].toLowerCase())) {
            wordScore = -wordScore; // Reverse sentiment
            break;
          }
        }

        // Check for intensifiers in previous words
        for (int j = max(0, i - 3); j < i; j++) {
          final prevWord = words[j].toLowerCase();
          if (_intensifiers.containsKey(prevWord)) {
            modifier *= _intensifiers[prevWord]!;
          } else if (_diminishers.containsKey(prevWord)) {
            modifier *= _diminishers[prevWord]!;
          }
        }

        // Apply modifier
        wordScore *= modifier;
        totalScore += wordScore;
      }
    }

    // Normalize score
    final normalizedScore = words.isNotEmpty ? totalScore / words.length : 0;

    // Determine sentiment category
    final sentiment = _categorizeSentiment(normalizedScore.toDouble());
    final confidence = _calculateConfidence(normalizedScore.toDouble(),
        positiveWords.length + negativeWords.length, words.length);
    final magnitude = _calculateMagnitude(totalScore, words.length);

    // Generate detailed analysis
    final analysis = _generateAnalysis(sentiment, normalizedScore.toDouble(),
        positiveWords.length, negativeWords.length, words.length);

    return {
      'sentiment': sentiment,
      'score': normalizedScore.toStringAsFixed(3),
      'confidence': confidence.toStringAsFixed(3),
      'positiveWords': positiveWords,
      'negativeWords': negativeWords,
      'analysis': analysis,
      'magnitude': magnitude.toStringAsFixed(3),
      'wordCount': words.length,
      'positiveCount': positiveWords.length,
      'negativeCount': negativeWords.length,
      'neutralCount':
          words.length - positiveWords.length - negativeWords.length,
      'positiveRatio': words.isNotEmpty
          ? (positiveWords.length / words.length).toStringAsFixed(3)
          : '0',
      'negativeRatio': words.isNotEmpty
          ? (negativeWords.length / words.length).toStringAsFixed(3)
          : '0',
    };
  }

  /// Advanced sentiment analysis with sentence-level breakdown
  static Map<String, dynamic> analyzeAdvanced(String text) {
    if (text.trim().isEmpty) {
      return {
        'overallSentiment': 'neutral',
        'overallScore': 0.0,
        'sentences': [],
        'emotionDistribution': {},
        'sentimentTrend': 'stable',
        'keyPhrases': [],
      };
    }

    final sentences = _splitIntoSentences(text);
    final sentenceAnalyses = <Map<String, dynamic>>[];
    double totalScore = 0.0;

    // Analyze each sentence
    for (int i = 0; i < sentences.length; i++) {
      final sentence = sentences[i];
      final analysis = analyze(sentence);

      sentenceAnalyses.add({
        'sentence': sentence,
        'index': i,
        'sentiment': analysis['sentiment'],
        'score': double.parse(analysis['score']),
        'positiveWords': analysis['positiveWords'],
        'negativeWords': analysis['negativeWords'],
        'wordCount': analysis['wordCount'],
      });

      totalScore += double.parse(analysis['score']);
    }

    // Calculate overall sentiment
    final overallScore =
        sentences.isNotEmpty ? totalScore / sentences.length : 0;
    final overallSentiment = _categorizeSentiment(overallScore.toDouble());

    // Analyze emotion distribution
    final emotionDistribution = _analyzeEmotionDistribution(sentenceAnalyses);

    // Analyze sentiment trend
    final sentimentTrend = _analyzeSentimentTrend(sentenceAnalyses);

    // Extract key phrases
    final keyPhrases = _extractKeyPhrases(text, sentenceAnalyses);

    return {
      'overallSentiment': overallSentiment,
      'overallScore': overallScore.toStringAsFixed(3),
      'sentenceCount': sentences.length,
      'sentences': sentenceAnalyses,
      'emotionDistribution': emotionDistribution,
      'sentimentTrend': sentimentTrend,
      'keyPhrases': keyPhrases,
      'mostPositiveSentence': _findMostPositiveSentence(sentenceAnalyses),
      'mostNegativeSentence': _findMostNegativeSentence(sentenceAnalyses),
      'sentimentConsistency': _calculateSentimentConsistency(sentenceAnalyses),
    };
  }

  /// Split text into sentences
  static List<String> _splitIntoSentences(String text) {
    // Simple sentence splitting
    return text
        .split(RegExp(r'[.!?]+'))
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .toList();
  }

  /// Tokenize text into words
  static List<String> _tokenizeText(String text) {
    return text.split(RegExp(r'\W+')).where((w) => w.isNotEmpty).toList();
  }

  /// Categorize sentiment based on score
  static String _categorizeSentiment(double score) {
    if (score > 0.2) return 'strongly positive';
    if (score > 0.05) return 'positive';
    if (score > -0.05) return 'neutral';
    if (score > -0.2) return 'negative';
    return 'strongly negative';
  }

  /// Calculate confidence in sentiment analysis
  static double _calculateConfidence(
      double score, int sentimentWords, int totalWords) {
    if (totalWords == 0) return 0;

    // Based on strength of score and proportion of sentiment words
    final strengthConfidence = (score.abs() * 2).clamp(0, 1);
    final coverageConfidence = (sentimentWords / totalWords * 3).clamp(0, 1);

    return (strengthConfidence * 0.6 + coverageConfidence * 0.4);
  }

  /// Calculate sentiment magnitude
  static double _calculateMagnitude(double totalScore, int wordCount) {
    return wordCount > 0 ? totalScore.abs() / wordCount : 0;
  }

  /// Generate analysis text
  static String _generateAnalysis(String sentiment, double score,
      int positiveCount, int negativeCount, int totalWords) {
    final positivePercent =
        totalWords > 0 ? (positiveCount / totalWords * 100) : 0;
    final negativePercent =
        totalWords > 0 ? (negativeCount / totalWords * 100) : 0;

    if (sentiment.contains('positive')) {
      if (positivePercent > 20) {
        return 'Very positive text with strong positive language ($positivePercent% positive words)';
      } else {
        return 'Generally positive text with some positive elements';
      }
    } else if (sentiment.contains('negative')) {
      if (negativePercent > 20) {
        return 'Very negative text with strong negative language ($negativePercent% negative words)';
      } else {
        return 'Generally negative text with some concerning elements';
      }
    } else {
      return 'Neutral text balanced between positive and negative elements';
    }
  }

  /// Analyze emotion distribution
  static Map<String, int> _analyzeEmotionDistribution(
      List<Map<String, dynamic>> sentenceAnalyses) {
    final distribution = <String, int>{
      'strongly positive': 0,
      'positive': 0,
      'neutral': 0,
      'negative': 0,
      'strongly negative': 0,
    };

    for (var analysis in sentenceAnalyses) {
      final sentiment = analysis['sentiment'] as String;
      distribution[sentiment] = (distribution[sentiment] ?? 0) + 1;
    }

    return distribution;
  }

  /// Analyze sentiment trend across sentences
  static String _analyzeSentimentTrend(
      List<Map<String, dynamic>> sentenceAnalyses) {
    if (sentenceAnalyses.length < 3) return 'insufficient data';

    // Calculate trend using linear regression (simplified)
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

    for (int i = 0; i < sentenceAnalyses.length; i++) {
      final x = i.toDouble();
      final y = sentenceAnalyses[i]['score'] as double;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    final n = sentenceAnalyses.length.toDouble();
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);

    if (slope > 0.01) return 'improving';
    if (slope < -0.01) return 'declining';
    return 'stable';
  }

  /// Extract key phrases with strong sentiment
  static List<String> _extractKeyPhrases(
      String text, List<Map<String, dynamic>> sentenceAnalyses) {
    final keyPhrases = <String>[];

    for (var analysis in sentenceAnalyses) {
      final score = analysis['score'] as double;
      final positiveWords = analysis['positiveWords'] as List<String>;
      final negativeWords = analysis['negativeWords'] as List<String>;

      if (score.abs() > 0.15) {
        // Strong sentiment
        if (positiveWords.isNotEmpty) {
          keyPhrases.add('Positive: ${positiveWords.join(', ')}');
        }
        if (negativeWords.isNotEmpty) {
          keyPhrases.add('Negative: ${negativeWords.join(', ')}');
        }
      }
    }

    return keyPhrases.take(5).toList();
  }

  /// Find most positive sentence
  static Map<String, dynamic> _findMostPositiveSentence(
      List<Map<String, dynamic>> sentenceAnalyses) {
    if (sentenceAnalyses.isEmpty) return {};

    return sentenceAnalyses.reduce(
        (a, b) => (a['score'] as double) > (b['score'] as double) ? a : b);
  }

  /// Find most negative sentence
  static Map<String, dynamic> _findMostNegativeSentence(
      List<Map<String, dynamic>> sentenceAnalyses) {
    if (sentenceAnalyses.isEmpty) return {};

    return sentenceAnalyses.reduce(
        (a, b) => (a['score'] as double) < (b['score'] as double) ? a : b);
  }

  /// Calculate sentiment consistency
  static String _calculateSentimentConsistency(
      List<Map<String, dynamic>> sentenceAnalyses) {
    if (sentenceAnalyses.isEmpty) return 'N/A';

    int sameSentimentCount = 0;
    final firstSentiment = sentenceAnalyses.first['sentiment'];

    for (var analysis in sentenceAnalyses) {
      if (analysis['sentiment'] == firstSentiment) {
        sameSentimentCount++;
      }
    }

    final consistency = sameSentimentCount / sentenceAnalyses.length;

    if (consistency > 0.8) return 'high';
    if (consistency > 0.5) return 'medium';
    return 'low';
  }

  /// Get sentiment lexicon statistics
  static Map<String, dynamic> getLexiconStats() {
    return {
      'positiveWords': _positiveLexicon.length,
      'negativeWords': _negativeLexicon.length,
      'totalWords': _positiveLexicon.length + _negativeLexicon.length,
      'negationWords': _negationWords.length,
      'intensifiers': _intensifiers.length,
      'diminishers': _diminishers.length,
    };
  }

  /// Test sentiment analysis on sample text
  static Map<String, dynamic> testSentimentAnalysis() {
    final testCases = [
      'I love this product! It is absolutely amazing and works perfectly.',
      'This is the worst experience I have ever had. Terrible service and poor quality.',
      'The product is okay. It works but nothing special.',
      'I don\'t like this at all. It\'s not good and very disappointing.',
      'Very happy with the purchase. Excellent quality and great value.',
    ];

    final results = <Map<String, dynamic>>[];

    for (var testCase in testCases) {
      results.add({
        'text': testCase,
        'analysis': analyze(testCase),
      });
    }

    return {
      'testCases': results,
      'lexiconStats': getLexiconStats(),
    };
  }
}
