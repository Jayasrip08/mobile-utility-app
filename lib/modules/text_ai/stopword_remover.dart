/// Stop Word Remover using Classical AI pattern filtering
class StopwordRemover {
  /// Comprehensive list of English stop words
  static final Set<String> _stopWords = {
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

  /// Removes stop words from text using Classical AI: Pattern filtering
  static String removeStopWords(String text) {
    if (text.trim().isEmpty) {
      return '';
    }

    // Split text into words while preserving punctuation
    final words = text.split(' ');
    final filteredWords = <String>[];

    for (var word in words) {
      // Clean the word (remove surrounding punctuation)
      final cleanWord = _cleanWord(word);

      // Check if it's a stop word (case insensitive)
      if (!_isStopWord(cleanWord)) {
        filteredWords.add(word);
      }
    }

    return filteredWords.join(' ');
  }

  /// Removes stop words and returns statistics
  static Map<String, dynamic> removeStopWordsWithStats(String text) {
    if (text.trim().isEmpty) {
      return {
        'filteredText': '',
        'originalWordCount': 0,
        'filteredWordCount': 0,
        'removedWordCount': 0,
        'removedPercentage': 0,
        'removedWords': [],
      };
    }

    final originalWords = text.split(' ');
    final filteredWords = <String>[];
    final removedWords = <String>[];

    for (var word in originalWords) {
      final cleanWord = _cleanWord(word);

      if (_isStopWord(cleanWord)) {
        removedWords.add(word);
      } else {
        filteredWords.add(word);
      }
    }

    final originalCount = originalWords.length;
    final filteredCount = filteredWords.length;
    final removedCount = removedWords.length;
    final removedPercentage =
        originalCount > 0 ? (removedCount / originalCount * 100) : 0;

    return {
      'filteredText': filteredWords.join(' '),
      'originalWordCount': originalCount,
      'filteredWordCount': filteredCount,
      'removedWordCount': removedCount,
      'removedPercentage': removedPercentage.toStringAsFixed(1),
      'removedWords': removedWords,
      'compressionRatio': originalCount > 0
          ? (filteredCount / originalCount).toStringAsFixed(2)
          : '0',
    };
  }

  /// Get frequency analysis of stop words in text
  static Map<String, dynamic> analyzeStopWordFrequency(String text) {
    if (text.trim().isEmpty) {
      return {
        'totalStopWords': 0,
        'uniqueStopWords': 0,
        'stopWordFrequency': {},
        'mostCommonStopWords': [],
      };
    }

    final words = text
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final stopWordFrequency = <String, int>{};
    int totalStopWords = 0;

    for (var word in words) {
      if (_isStopWord(word)) {
        stopWordFrequency[word] = (stopWordFrequency[word] ?? 0) + 1;
        totalStopWords++;
      }
    }

    // Sort by frequency descending
    final sortedEntries = stopWordFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final mostCommon =
        sortedEntries.take(10).map((e) => '${e.key} (${e.value})').toList();

    return {
      'totalStopWords': totalStopWords,
      'uniqueStopWords': stopWordFrequency.length,
      'stopWordFrequency': stopWordFrequency,
      'mostCommonStopWords': mostCommon,
      'stopWordPercentage': words.isNotEmpty
          ? ((totalStopWords / words.length) * 100).toStringAsFixed(1)
          : '0',
    };
  }

  /// Clean a word by removing surrounding punctuation
  static String _cleanWord(String word) {
    // Remove leading/trailing punctuation but keep internal punctuation (like apostrophes)
    return word
        .replaceAll(RegExp(r"^[^\p{L}']+|[^\p{L}']+$", unicode: true), '')
        .toLowerCase();
  }

  /// Check if a word is a stop word
  static bool _isStopWord(String word) {
    return _stopWords.contains(word.toLowerCase());
  }

  /// Get the complete list of stop words (for display purposes)
  static List<String> getStopWordList() {
    return _stopWords.toList()..sort();
  }

  /// Categorize stop words by type
  static Map<String, List<String>> getCategorizedStopWords() {
    return {
      'Articles': ['a', 'an', 'the'],
      'Pronouns': [
        'i',
        'me',
        'my',
        'myself',
        'we',
        'us',
        'our',
        'ours',
        'ourselves',
        'you',
        'your',
        'yours',
        'yourself',
        'yourselves',
        'he',
        'him',
        'his',
        'himself',
        'she',
        'her',
        'hers',
        'herself',
        'it',
        'its',
        'itself',
        'they',
        'them',
        'their',
        'theirs',
        'themselves'
      ],
      'Prepositions': [
        'about',
        'above',
        'across',
        'after',
        'against',
        'along',
        'among',
        'around',
        'at',
        'before',
        'behind',
        'below',
        'beneath',
        'beside',
        'between',
        'beyond',
        'by',
        'down',
        'during',
        'for',
        'from',
        'in',
        'inside',
        'into',
        'near',
        'of',
        'off',
        'on',
        'onto',
        'out',
        'outside',
        'over',
        'through',
        'to',
        'toward',
        'under',
        'up',
        'upon',
        'with',
        'within',
        'without'
      ],
      'Conjunctions': [
        'and',
        'but',
        'or',
        'nor',
        'for',
        'so',
        'yet',
        'although',
        'because',
        'since',
        'unless',
        'while'
      ],
      'Verbs': [
        'am',
        'is',
        'are',
        'was',
        'were',
        'be',
        'been',
        'being',
        'have',
        'has',
        'had',
        'having',
        'do',
        'does',
        'did',
        'doing',
        'will',
        'would',
        'shall',
        'should',
        'may',
        'might',
        'must',
        'can',
        'could'
      ],
      'Common Adverbs': [
        'very',
        'too',
        'quite',
        'rather',
        'somewhat',
        'almost',
        'enough',
        'just',
        'still',
        'already',
        'yet',
        'even',
        'only',
        'also',
        'here',
        'there',
        'where',
        'when',
        'why',
        'how',
        'now',
        'then',
        'today',
        'yesterday',
        'tomorrow',
        'soon',
        'later',
        'always',
        'never',
        'sometimes',
        'often',
        'usually',
        'rarely',
        'seldom'
      ],
    };
  }
}
