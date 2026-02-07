import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:taskflow_pro/features/tasks/presentation/screens/home_screen.dart';


class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool isSending = false;

  Future<void> _resendVerification() async {
    setState(() => isSending = true);

    await FirebaseAuth.instance.currentUser!.sendEmailVerification();

    setState(() => isSending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Verification email sent")),
    );
  }

  Future<void> _checkVerification() async {
    await FirebaseAuth.instance.currentUser!.reload();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email not verified yet")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Email")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_read, size: 80),
            const SizedBox(height: 20),
            const Text(
              "We’ve sent a verification link to your email.\nPlease verify to continue.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            FilledButton(
              onPressed: isSending ? null : _resendVerification,
              child: const Text("Resend Email"),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _checkVerification,
              child: const Text("I have verified"),
            ),
          ],
        ),
      ),
    );
  }
}
