/// Keyword Extractor using TF-IDF inspired Classical AI algorithm
class KeywordExtractor {
  /// Extracts keywords from text using frequency analysis (Classical AI: Statistical analysis)
  static List<String> extract(String text, {int maxKeywords = 10}) {
    if (text.trim().isEmpty) {
      return [];
    }

    // Convert to lowercase and split into words
    final words = text
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((w) => w.isNotEmpty)
        .toList();

    // Remove stop words
    final filteredWords = words.where((word) => !_isStopWord(word)).toList();

    // Calculate word frequencies
    final Map<String, int> frequencies = {};
    for (var word in filteredWords) {
      frequencies[word] = (frequencies[word] ?? 0) + 1;
    }

    // Calculate scores based on frequency and word length
    final Map<String, double> scores = {};
    for (var entry in frequencies.entries) {
      final word = entry.key;
      final frequency = entry.value;

      // Score = frequency * wordLengthFactor * positionFactor
      double score = frequency.toDouble();

      // Longer words often carry more meaning
      if (word.length > 5) {
        score *= 1.5;
      } else if (word.length > 3) {
        score *= 1.2;
      }

      // Proper nouns (capitalized in original text) get bonus
      if (_isProperNoun(word, text)) {
        score *= 2.0;
      }

      scores[word] = score;
    }

    // Sort by score descending
    final sortedEntries = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Return top keywords
    return sortedEntries.take(maxKeywords).map((e) => e.key).toList();
  }

  /// Classical AI: Stop word filtering using predefined list
  static bool _isStopWord(String word) {
    final stopWords = {
    'a', 'about', 'above', 'across', 'after', 'against', 'all', 'almost', 'along',
    'already', 'also', 'although', 'always', 'am', 'among', 'an', 'and', 'another',
    'any', 'anybody', 'anyone', 'anything', 'anywhere', 'are', 'aren\'t', 'around',
    'as', 'at', 'be', 'because', 'been', 'before', 'behind', 'being', 'below',
    'beneath', 'beside', 'between', 'beyond', 'both', 'but', 'by', 'can', 'can\'t',
    'cannot', 'could', 'couldn\'t', 'did', 'didn\'t', 'do', 'does', 'doesn\'t',
    'doing', 'don\'t', 'down', 'during', 'each', 'either', 'else', 'enough',
    'even', 'ever', 'every', 'everybody', 'everyone', 'everything', 'everywhere',
    'except', 'few', 'for', 'from', 'further', 'get', 'gets', 'got', 'had',
    'hadn\'t', 'has', 'hasn\'t', 'have', 'haven\'t', 'having', 'he', 'he\'d',
    'he\'ll', 'he\'s', 'hence', 'her', 'here', 'here\'s', 'hers', 'herself', 'him',
    'himself', 'his', 'how', 'how\'s', 'however', 'i', 'i\'d', 'i\'ll', 'i\'m',
    'i\'ve', 'if', 'in', 'inside', 'into', 'is', 'isn\'t', 'it', 'it\'d', 'it\'ll',
    'it\'s', 'its', 'itself', 'just', 'keep', 'keeps', 'kept', 'know', 'knows',
    'known', 'last', 'later', 'latter', 'latterly', 'least', 'less', 'let\'s',
    'like', 'liked', 'likely', 'little', 'look', 'looking', 'looks', 'made', 'make',
    'makes', 'many', 'may', 'me', 'mean', 'means', 'meant', 'meanwhile', 'might',
    'mightn\'t', 'more', 'moreover', 'most', 'mostly', 'much', 'must', 'mustn\'t',
    'my', 'myself', 'name', 'namely', 'near', 'neither', 'never', 'nevertheless',
    'next', 'no', 'nobody', 'none', 'noone', 'nor', 'not', 'nothing', 'now',
    'nowhere', 'of', 'off', 'often', 'on', 'once', 'one', 'only', 'onto', 'or',
    'other', 'others', 'otherwise', 'ought', 'oughtn\'t', 'our', 'ours',
    'ourselves', 'out', 'outside', 'over', 'overall', 'own', 'part', 'per',
    'perhaps', 'please', 'put', 'quite', 'rather', 're', 'same', 'see', 'seem',
    'seemed', 'seeming', 'seems', 'seldom', 'serious', 'several', 'shall', 'shan\'t',
    'she', 'she\'d', 'she\'ll', 'she\'s', 'should', 'shouldn\'t', 'show', 'shows',
    'side', 'since', 'so', 'some', 'somebody', 'someone', 'something', 'sometime',
    'sometimes', 'somewhere', 'soon', 'still', 'such', 'take', 'taken', 'than',
    'that', 'that\'s', 'the', 'their', 'theirs', 'them', 'themselves', 'then',
    'thence', 'there', 'there\'s', 'thereafter', 'thereby', 'therefore', 'therein',
    'thereupon', 'these', 'they', 'they\'d', 'they\'ll', 'they\'re', 'they\'ve',
    'this', 'those', 'though', 'through', 'throughout', 'thru', 'thus', 'to',
    'today', 'together', 'tomorrow', 'too', 'toward', 'towards', 'under', 'unless',
    'until', 'up', 'upon', 'us', 'used', 'uses', 'using', 'very', 'via', 'was',
    'wasn\'t', 'we', 'we\'d', 'we\'ll', 'we\'re', 'we\'ve', 'well', 'went', 'were',
    'weren\'t', 'what', 'what\'s', 'whatever', 'when', 'when\'s', 'whence',
    'whenever', 'where', 'where\'s', 'whereafter', 'whereas', 'whereby', 'wherein',
    'whereupon', 'wherever', 'whether', 'which', 'while', 'whither', 'who',
    'who\'s', 'whoever', 'whole', 'whom', 'whose', 'why', 'why\'s', 'will', 'with',
    'within', 'without', 'won\'t', 'would', 'wouldn\'t', 'yet', 'yesterday',
    'you', 'you\'d', 'you\'ll', 'you\'re', 'you\'ve', 'your', 'yours', 'yourself',
    'yourselves'
    };

    return stopWords.contains(word.toLowerCase());
  }

  /// Check if word appears as proper noun in original text
  static bool _isProperNoun(String word, String originalText) {
    // Find all occurrences of the word in original text
    final pattern =
        RegExp(r'\b' + RegExp.escape(word) + r'\b', caseSensitive: false);
    final matches = pattern.allMatches(originalText);

    // Check if any occurrence starts with uppercase
    for (var match in matches) {
      final matchedWord = originalText.substring(match.start, match.end);
      if (matchedWord.isNotEmpty &&
          matchedWord[0].toUpperCase() == matchedWord[0]) {
        return true;
      }
    }

    return false;
  }
}
