/// Automatic tag generator using pattern matching and classification
class AutoTag {
  /// Generate tags based on input content
  static String generate(dynamic input) {
    if (input is String) {
      return _generateFromText(input);
    } else if (input is Map<String, dynamic>) {
      return _generateFromMap(input);
    } else if (input is List) {
      return _generateFromList(input);
    } else {
      return "General";
    }
  }

  /// Generate tags from text content
  static String _generateFromText(String text) {
    text = text.toLowerCase();
    Set<String> tags = {};

    // Content type detection
    if (text.length > 500) {
      tags.add('Long-Text');
    } else if (text.length > 100) {
      tags.add('Medium-Text');
    } else {
      tags.add('Short-Text');
    }

    // Topic detection
    final topicKeywords = {
      'technology': [
        'code',
        'program',
        'software',
        'app',
        'system',
        'tech',
        'computer'
      ],
      'business': [
        'business',
        'company',
        'market',
        'sales',
        'profit',
        'revenue',
        'customer'
      ],
      'health': [
        'health',
        'medical',
        'doctor',
        'hospital',
        'medicine',
        'fitness',
        'exercise'
      ],
      'education': [
        'learn',
        'study',
        'school',
        'university',
        'course',
        'education',
        'student'
      ],
      'finance': [
        'money',
        'bank',
        'investment',
        'stock',
        'finance',
        'budget',
        'expense'
      ],
      'travel': [
        'travel',
        'trip',
        'vacation',
        'hotel',
        'flight',
        'destination',
        'tour'
      ],
    };

    for (var topic in topicKeywords.keys) {
      for (var keyword in topicKeywords[topic]!) {
        if (text.contains(keyword)) {
          tags.add(topic[0].toUpperCase() + topic.substring(1));
          break;
        }
      }
    }

    // Sentiment detection
    final positiveWords = [
      'good',
      'great',
      'excellent',
      'happy',
      'positive',
      'success',
      'win'
    ];
    final negativeWords = [
      'bad',
      'poor',
      'terrible',
      'sad',
      'negative',
      'fail',
      'problem'
    ];

    int positiveCount = 0;
    int negativeCount = 0;

    for (var word in text.split(' ')) {
      if (positiveWords.contains(word)) positiveCount++;
      if (negativeWords.contains(word)) negativeCount++;
    }

    if (positiveCount > negativeCount && positiveCount > 0) {
      tags.add('Positive');
    } else if (negativeCount > positiveCount && negativeCount > 0) {
      tags.add('Negative');
    } else if (positiveCount == negativeCount && positiveCount > 0) {
      tags.add('Neutral');
    }

    // Urgency detection
    final urgentWords = [
      'urgent',
      'immediate',
      'asap',
      'emergency',
      'critical',
      'important'
    ];
    for (var word in urgentWords) {
      if (text.contains(word)) {
        tags.add('Urgent');
        break;
      }
    }

    // Format detection
    if (text.contains('@') && text.contains('.com')) {
      tags.add('Email-Related');
    }

    if (text.contains('http://') || text.contains('https://')) {
      tags.add('Web-Related');
    }

    if (text.contains('\n') && text.split('\n').length > 5) {
      tags.add('Structured-Content');
    }

    // Return formatted tags
    if (tags.isEmpty) {
      return "General, Text";
    } else {
      return tags.join(', ');
    }
  }

  /// Generate tags from map data
  static String _generateFromMap(Map<String, dynamic> data) {
    Set<String> tags = {};

    // Based on data structure
    tags.add('Structured-Data');

    // Based on keys present
    if (data.containsKey('timestamp') || data.containsKey('date')) {
      tags.add('Time-Stamped');
    }

    if (data.containsKey('location') || data.containsKey('coordinates')) {
      tags.add('Location-Based');
    }

    if (data.containsKey('value') && data['value'] is num) {
      tags.add('Numeric-Data');
      double value = (data['value'] as num).toDouble();
      if (value > 1000) tags.add('Large-Value');
      if (value < 0) tags.add('Negative-Value');
    }

    if (data.containsKey('status')) {
      String status = data['status'].toString().toLowerCase();
      if (status.contains('active') || status.contains('running')) {
        tags.add('Active-Status');
      } else if (status.contains('error') || status.contains('failed')) {
        tags.add('Error-Status');
      } else if (status.contains('pending') || status.contains('waiting')) {
        tags.add('Pending-Status');
      }
    }

    // Based on data size
    int keyCount = data.keys.length;
    if (keyCount > 10) {
      tags.add('Complex-Structure');
    } else if (keyCount > 5) {
      tags.add('Detailed-Structure');
    } else {
      tags.add('Simple-Structure');
    }

    return tags.join(', ');
  }

  /// Generate tags from list data
  static String _generateFromList(List<dynamic> items) {
    Set<String> tags = {};

    tags.add('List-Data');

    // Size-based tags
    if (items.length > 100) {
      tags.add('Large-List');
    } else if (items.length > 20) {
      tags.add('Medium-List');
    } else {
      tags.add('Small-List');
    }

    // Content type detection
    if (items.isNotEmpty) {
      var firstItem = items.first;

      if (firstItem is String) {
        tags.add('String-List');
        // Check if it looks like text data
        if (items.length > 5 && (items[0] as String).length > 50) {
          tags.add('Text-Data');
        }
      } else if (firstItem is num) {
        tags.add('Numeric-List');
        // Check for data patterns
        if (_isTimeSeries(items)) {
          tags.add('Time-Series');
        }
      } else if (firstItem is Map) {
        tags.add('Object-List');
      } else if (firstItem is List) {
        tags.add('Nested-List');
      }
    }

    // Pattern detection
    if (_hasDuplicates(items)) {
      tags.add('Has-Duplicates');
    }

    if (_isSorted(items)) {
      tags.add('Sorted-Data');
    }

    return tags.join(', ');
  }

  /// Helper: Check if list is time series data
  static bool _isTimeSeries(List<dynamic> items) {
    if (items.length < 3) return false;

    // Check if items are increasing (common in time series)
    for (int i = 1; i < items.length; i++) {
      if (items[i] is! num || items[i - 1] is! num) continue;
      if (items[i] <= items[i - 1]) return false;
    }

    return true;
  }

  /// Helper: Check for duplicates
  static bool _hasDuplicates(List<dynamic> items) {
    Set<dynamic> seen = {};
    for (var item in items) {
      if (seen.contains(item)) return true;
      seen.add(item);
    }
    return false;
  }

  /// Helper: Check if list is sorted
  static bool _isSorted(List<dynamic> items) {
    if (items.length < 2) return true;

    bool ascending = true;
    bool descending = true;

    for (int i = 1; i < items.length; i++) {
      if (items[i] is! Comparable || items[i - 1] is! Comparable) continue;

      if ((items[i] as Comparable).compareTo(items[i - 1]) < 0) {
        ascending = false;
      }
      if ((items[i] as Comparable).compareTo(items[i - 1]) > 0) {
        descending = false;
      }
    }

    return ascending || descending;
  }

  /// Suggest related tags
  static List<String> suggestRelatedTags(String baseTag, [int count = 5]) {
    final tagRelations = {
      'Technology': ['Software', 'Hardware', 'Programming', 'AI', 'Data'],
      'Business': ['Finance', 'Marketing', 'Sales', 'Management', 'Strategy'],
      'Health': ['Fitness', 'Nutrition', 'Medical', 'Wellness', 'Therapy'],
      'Education': ['Learning', 'Teaching', 'Research', 'Academic', 'Training'],
      'Finance': ['Investment', 'Banking', 'Accounting', 'Budget', 'Tax'],
      'Travel': ['Tourism', 'Adventure', 'Hotel', 'Transport', 'Destination'],
      'Positive': [
        'Optimistic',
        'Successful',
        'Achievement',
        'Growth',
        'Improvement'
      ],
      'Negative': ['Critical', 'Problem', 'Issue', 'Challenge', 'Risk'],
      'Urgent': [
        'Important',
        'Critical',
        'Priority',
        'Time-Sensitive',
        'Immediate'
      ],
    };

    baseTag = baseTag.toLowerCase();

    for (var key in tagRelations.keys) {
      if (key.toLowerCase() == baseTag || baseTag.contains(key.toLowerCase())) {
        return tagRelations[key]!.take(count).toList();
      }
    }

    // Default related tags
    return ['General', 'Important', 'Review', 'Action', 'Follow-up'];
  }

  /// Get tag confidence score
  static Map<String, dynamic> analyzeTagConfidence(String content, String tag) {
    content = content.toLowerCase();
    tag = tag.toLowerCase();

    int score = 0;
    int maxScore = 100;
    List<String> evidence = [];

    // Keyword matching
    final keywordWeights = {
      'technology': 20,
      'business': 15,
      'health': 15,
      'education': 15,
      'finance': 15,
      'urgent': 25,
      'important': 20,
      'positive': 15,
      'negative': 15,
    };

    // Check for exact tag match
    if (content.contains(tag)) {
      score += 30;
      evidence.add("Exact tag mention found");
    }

    // Check for related keywords
    for (var keyword in keywordWeights.keys) {
      if (content.contains(keyword)) {
        score += keywordWeights[keyword]!;
        evidence.add("Related keyword '$keyword' found");
      }
    }

    // Length-based confidence
    if (content.length > 200) {
      score += 10;
      evidence.add("Substantial content length");
    }

    // Format-based confidence
    if (content.contains('\n') && content.split('\n').length > 3) {
      score += 10;
      evidence.add("Structured content format");
    }

    // Calculate confidence percentage
    double confidence = (score / maxScore * 100).clamp(0, 100);

    return {
      'tag': tag,
      'confidence': confidence.toStringAsFixed(1),
      'score': score,
      'evidence': evidence,
      'recommendation':
          confidence >= 70 ? 'High confidence' : 'Medium confidence',
    };
  }
}
