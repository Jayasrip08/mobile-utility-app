class RuleChatbot {
  static final Map<String, String> responses = {
    // Greetings
    'hello': 'Hello! How can I help you today?',
    'hi': 'Hi there! What can I do for you?',
    'hey': 'Hey! I\'m your AI assistant.',

    // Questions about the app
    'what can you do':
        'I can help with 50 different AI tools including text analysis, image processing, data analysis, and decision support.',
    'tools':
        'We have tools in Text AI, Image AI, Audio AI, Data AI, Automation AI, and Logic & Decision AI categories.',
    'help':
        'You can ask me about the app features or use any of the 50 AI tools available.',

    // App info
    'who made you':
        'I was created as part of a final year project for an AI Tools App.',
    'purpose':
        'My purpose is to provide various AI tools using classical AI techniques without requiring internet.',
    'features':
        'Main features: 50+ tools, offline functionality, classical AI, and Firebase integration.',

    // Default response
    'default':
        'I\'m not sure I understand. Could you rephrase or ask about our AI tools?'
  };

  static String getResponse(String userInput) {
    userInput = userInput.toLowerCase();

    // Check for exact matches
    for (var key in responses.keys) {
      if (userInput.contains(key)) {
        return responses[key]!;
      }
    }

    // Check for partial matches
    if (userInput.contains('how') && userInput.contains('use')) {
      return 'Each tool has its own screen. Just select a tool from the home screen and follow the instructions.';
    }

    if (userInput.contains('offline')) {
      return 'Yes! All tools work offline using classical AI techniques. Results are saved to Firestore when online.';
    }

    if (userInput.contains('ai') || userInput.contains('artificial')) {
      return 'We use classical AI techniques like rule-based systems, pattern matching, and heuristic algorithms.';
    }

    return responses['default']!;
  }
}
