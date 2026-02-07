import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy Policy"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: const Text(
          '''
Privacy Policy for TaskFlow Pro

TaskFlow Pro respects your privacy.

1. Data We Collect
We collect only the data necessary to provide core features:
- Email address (for authentication)
- Task data created by the user

2. How Data Is Used
- To authenticate users
- To store and sync tasks securely
- To send task reminders (notifications)

3. Data Storage
All data is securely stored using Firebase services.

4. Data Sharing
We do not sell, trade, or share your personal data with third parties.

5. Account Deletion
Users can delete their account at any time from the Settings screen.
All associated data will be permanently deleted.

6. Contact
If you have questions, contact: support@taskflowpro.app

Last updated: 2025
''',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
      ),
    );
  }
}
