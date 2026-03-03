import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Last updated: January 2026',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 16),
            Text(
              '1. Introduction\n'
              'Welcome to Classical AI Tools. We respect your privacy and are committed to protecting your personal data.\n\n'
              '2. Data Collection\n'
              'We collect minimal personal information such as your name and email address when you sign up. We do not sell your personal data.\n\n'
              '3. Usage\n'
              'Your data is used solely for authentication and providing access to AI tools. Generated content is processed securely.\n\n'
              '4. Security\n'
              'We implement security measures to maintain the safety of your personal information.\n\n'
              '5. Contact Us\n'
              'If you have any questions about this Privacy Policy, please contact us.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
