import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        children: [
          const ExpansionTile(
            title: Text('How do I use the AI Tools?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Select a category from the home screen, then choose a specific tool. Follow the on-screen instructions to input your data and get results.'),
              ),
            ],
          ),
          const ExpansionTile(
            title: Text('Is my data safe?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Yes, we prioritize your data privacy. All processing is done securely.'),
              ),
            ],
          ),
          const ExpansionTile(
            title: Text('How do I reset my password?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Go to Settings -> Change Password if you are logged in. If you forgot your password, use the "Forgot Password" link on the login screen.'),
              ),
            ],
          ),
           const ExpansionTile(
            title: Text('Contact Support'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Email us at support@classicalaitools.com for further assistance.'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
