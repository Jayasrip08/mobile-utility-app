class YesNoPredictor {
  static String predict(String question, Map<String, dynamic> context) {
    question = question.toLowerCase();

    // Keyword-based prediction
    final positiveKeywords = [
      'should',
      'can',
      'will',
      'good',
      'benefit',
      'advantage',
      'profit'
    ];
    final negativeKeywords = [
      'bad',
      'risk',
      'danger',
      'problem',
      'issue',
      'lose',
      'failure'
    ];

    int positiveScore = 0;
    int negativeScore = 0;

    for (var word in question.split(' ')) {
      if (positiveKeywords.contains(word)) positiveScore++;
      if (negativeKeywords.contains(word)) negativeScore++;
    }

    // Context analysis
    if (context['confidence'] == 'high') positiveScore += 2;
    if (context['urgency'] == 'low') positiveScore += 1;
    if (context['complexity'] == 'simple') positiveScore += 1;

    // Decision logic
    if (positiveScore > negativeScore) {
      return "YES - Probability: ${((positiveScore / (positiveScore + negativeScore)) * 100).toStringAsFixed(1)}%\n"
          "The factors indicate a positive outcome is likely.";
    } else if (negativeScore > positiveScore) {
      return "NO - Probability: ${((negativeScore / (positiveScore + negativeScore)) * 100).toStringAsFixed(1)}%\n"
          "The analysis suggests this may not be favorable.";
    } else {
      return "MAYBE - 50/50 chance\n"
          "The decision is balanced. Consider more information.";
    }
  }
}
