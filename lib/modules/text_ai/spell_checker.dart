/// Dictionary-based Spell Checker using Classical AI
class SpellChecker {
  /// Common English words dictionary
  static final Set<String> dictionary = {
    'the',
    'be',
    'to',
    'of',
    'and',
    'a',
    'in',
    'that',
    'have',
    'i',
    'it',
    'for',
    'not',
    'on',
    'with',
    'he',
    'as',
    'you',
    'do',
    'at',
    'this',
    'but',
    'his',
    'by',
    'from',
    'they',
    'we',
    'say',
    'her',
    'she',
    'or',
    'an',
    'will',
    'my',
    'one',
    'all',
    'would',
    'there',
    'their',
    'what',
    'so',
    'up',
    'out',
    'if',
    'about',
    'who',
    'get',
    'which',
    'go',
    'me',
    'when',
    'make',
    'can',
    'like',
    'time',
    'no',
    'just',
    'him',
    'know',
    'take',
    'people',
    'into',
    'year',
    'your',
    'good',
    'some',
    'could',
    'them',
    'see',
    'other',
    'than',
    'then',
    'now',
    'look',
    'only',
    'come',
    'its',
    'over',
    'think',
    'also',
    'back',
    'after',
    'use',
    'two',
    'how',
    'our',
    'work',
    'first',
    'well',
    'way',
    'even',
    'new',
    'want',
    'because',
    'any',
    'these',
    'give',
    'day',
    'most',
    'us',
    'is',
    'are',
    'was',
    'were',
    'been',
    'has',
    'had',
    'did',
    'does',
    'doing',
    'said',
    'says',
    'goes',
    'went',
    'gone',
    'got',
    'gotten',
    'made',
    'making',
    'took',
    'taken',
    'saw',
    'seen',
    'came',
    'coming',
    'thought',
    'knew',
    'known',
    'gave',
    'given',
    'find',
    'found',
    'tell',
    'told',
    'become',
    'became',
    'show',
    'showed',
    'shown',
    'leave',
    'left',
    'feel',
    'felt',
    'put',
    'puts',
    'bring',
    'brought',
    'begin',
    'began',
    'begun',
    'keep',
    'kept',
    'hold',
    'held',
    'write',
    'wrote',
    'written',
    'stand',
    'stood',
    'hear',
    'heard',
    'let',
    'lets',
    'mean',
    'meant',
    'set',
    'sets',
    'meet',
    'met',
    'run',
    'ran',
    'pay',
    'paid',
    'sit',
    'sat',
    'speak',
    'spoke',
    'spoken',
    'lie',
    'lay',
    'lain',
    'lead',
    'led',
    'read',
    'grow',
    'grew',
    'grown',
    'lose',
    'lost',
    'fall',
    'fell',
    'fallen',
    'send',
    'sent',
    'build',
    'built',
    'understand',
    'understood',
    'draw',
    'drew',
    'drawn',
    'break',
    'broke',
    'broken',
    'spend',
    'spent',
    'cut',
    'rise',
    'rose',
    'risen',
    'drive',
    'drove',
    'driven',
    'buy',
    'bought',
    'wear',
    'wore',
    'worn',
    'choose',
    'chose',
    'chosen',
    'eat',
    'ate',
    'eaten',
    'drink',
    'drank',
    'drunk',
    'fly',
    'flew',
    'flown',
    'throw',
    'threw',
    'thrown',
    'swim',
    'swam',
    'swum',
    'sing',
    'sang',
    'sung',
  };

  /// Checks spelling using dictionary lookup (Classical AI: Knowledge-based system)
  static List<String> checkSpelling(String text) {
    List<String> mistakes = [];

    if (text.trim().isEmpty) {
      return mistakes;
    }

    // Extract words from text
    final words =
        text.split(RegExp(r'\W+')).where((w) => w.isNotEmpty).toList();

    for (var word in words) {
      final cleanWord = word.toLowerCase();

      // Skip if word is in dictionary
      if (dictionary.contains(cleanWord)) {
        continue;
      }

      // Check if word is a number
      if (double.tryParse(cleanWord) != null) {
        continue;
      }

      // Check if word is a common contraction
      final contractions = {
        'i\'m': 'i am',
        'you\'re': 'you are',
        'he\'s': 'he is',
        'she\'s': 'she is',
        'it\'s': 'it is',
        'we\'re': 'we are',
        'they\'re': 'they are',
        'that\'s': 'that is',
        'who\'s': 'who is',
        'what\'s': 'what is',
        'where\'s': 'where is',
        'when\'s': 'when is',
        'why\'s': 'why is',
        'how\'s': 'how is',
        'i\'ll': 'i will',
        'you\'ll': 'you will',
        'he\'ll': 'he will',
        'she\'ll': 'she will',
        'it\'ll': 'it will',
        'we\'ll': 'we will',
        'they\'ll': 'they will',
        'i\'ve': 'i have',
        'you\'ve': 'you have',
        'we\'ve': 'we have',
        'they\'ve': 'they have',
        'i\'d': 'i would',
        'you\'d': 'you would',
        'he\'d': 'he would',
        'she\'d': 'she would',
        'it\'d': 'it would',
        'we\'d': 'we would',
        'they\'d': 'they would',
        'isn\'t': 'is not',
        'aren\'t': 'are not',
        'wasn\'t': 'was not',
        'weren\'t': 'were not',
        'haven\'t': 'have not',
        'hasn\'t': 'has not',
        'hadn\'t': 'had not',
        'won\'t': 'will not',
        'wouldn\'t': 'would not',
        'don\'t': 'do not',
        'doesn\'t': 'does not',
        'didn\'t': 'did not',
        'can\'t': 'cannot',
        'couldn\'t': 'could not',
        'shouldn\'t': 'should not',
        'mightn\'t': 'might not',
        'mustn\'t': 'must not'
      };

      if (contractions.containsKey(cleanWord)) {
        continue;
      }

      // Check for common misspellings using pattern matching
      final suggestions = _getSuggestions(cleanWord);
      if (suggestions.isNotEmpty) {
        mistakes.add("'$word': Did you mean ${suggestions.join(' or ')}?");
      } else {
        mistakes.add("'$word' might be misspelled");
      }
    }

    return mistakes;
  }

  /// Classical AI: Pattern matching for spelling suggestions
  static List<String> _getSuggestions(String word) {
    final suggestions = <String>[];

    // Common misspellings dictionary
    final commonMisspellings = Map.fromEntries([
      MapEntry('recieve', 'receive'),
      MapEntry('wierd', 'weird'),
      MapEntry('acheive', 'achieve'),
      MapEntry('definately', 'definitely'),
      MapEntry('seperate', 'separate'),
      MapEntry('occured', 'occurred'),
      MapEntry('untill', 'until'),
      MapEntry('occurence', 'occurrence'),
      MapEntry('refered', 'referred'),
      MapEntry('comming', 'coming'),
      MapEntry('truely', 'truly'),
      MapEntry('arguement', 'argument'),
      MapEntry('judgement', 'judgment'),
      MapEntry('maintainence', 'maintenance'),
      MapEntry('neccessary', 'necessary'),
      MapEntry('pronounciation', 'pronunciation'),
      MapEntry('restaraunt', 'restaurant'),
      MapEntry('seige', 'siege'),
      MapEntry('thier', 'their'),
      MapEntry('tomorow', 'tomorrow'),
      MapEntry('tounge', 'tongue'),
      MapEntry('vacum', 'vacuum'),
      MapEntry('writting', 'writing'),
    ]);

    if (commonMisspellings.containsKey(word)) {
      suggestions.add(commonMisspellings[word]!);
    }

    // Simple pattern-based suggestions
    if (word.endsWith('er') &&
        dictionary.contains(word.substring(0, word.length - 1))) {
      suggestions.add(word.substring(0, word.length - 1));
    }

    if (word.endsWith('ed') &&
        dictionary.contains(word.substring(0, word.length - 1))) {
      suggestions.add(word.substring(0, word.length - 1));
    }

    if (word.endsWith('ing') &&
        dictionary.contains(word.substring(0, word.length - 3))) {
      suggestions.add(word.substring(0, word.length - 3));
    }

    return suggestions;
  }
}
