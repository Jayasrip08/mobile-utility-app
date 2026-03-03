class DecisionSupportSystem {
  static String analyzeDecision(Map<String, dynamic> factors) {
    int score = 0;

    // Financial factors
    if (factors['budget'] == 'adequate') score += 20;
    if (factors['roi'] == 'high') score += 15;

    // Risk factors
    if (factors['risk'] == 'low') score += 15;
    if (factors['experience'] == 'high') score += 10;

    // Time factors
    if (factors['timeline'] == 'reasonable') score += 10;
    if (factors['resources'] == 'available') score += 10;

    // Market factors
    if (factors['demand'] == 'high') score += 10;
    if (factors['competition'] == 'low') score += 10;

    // Decision logic
    if (score >= 70) {
      return "STRONGLY RECOMMENDED - Score: $score/100\n"
          "All critical factors are favorable. High probability of success.";
    } else if (score >= 50) {
      return "RECOMMENDED WITH CAUTION - Score: $score/100\n"
          "Most factors are positive but some areas need attention.";
    } else if (score >= 30) {
      return "NOT RECOMMENDED - Score: $score/100\n"
          "Multiple risk factors present. Requires significant improvements.";
    } else {
      return "STRONGLY NOT RECOMMENDED - Score: $score/100\n"
          "High risk with multiple unfavorable factors.";
    }
  }
}
