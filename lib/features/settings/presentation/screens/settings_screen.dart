import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'privacy_policy_screen.dart';
import 'package:taskflow_pro/state/app_state.dart';
import 'package:taskflow_pro/features/splash/presentation/screens/splash_screen.dart';
import 'package:taskflow_pro/features/auth/data/auth_service.dart';
import 'package:permission_handler/permission_handler.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();

    if (status.isDenied || status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;


    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------------- PROFILE ----------------
          const Text(
            "Profile",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Card(
            child: ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text("Email"),
              subtitle: Text(user?.email ?? "Unknown"),
            ),
          ),

          const SizedBox(height: 24),

          // ---------------- APPEARANCE ----------------
          const Text(
            "Appearance",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text("Dark Mode"),
              value: context.watch<AppState>().isDark,
              onChanged: (_) {
                context.read<AppState>().toggleTheme();
              },
            ),
          ),

          const SizedBox(height: 24),

// ---------------- NOTIFICATIONS ----------------
          const Text(
            "Notifications",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text("Enable Reminders"),
              subtitle: const Text("Allow alarms & reminders permission"),
              onTap: () async {
                await _requestNotificationPermission();
              },

            ),
          ),



          const SizedBox(height: 24),

          // ---------------- SECURITY ----------------
          const Text(
            "Security",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text("Change Password"),
              subtitle: const Text("Use Forgot Password from login"),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Password reset is available from the login screen using ‘Forgot Password'.",
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // ---------------- PRIVACY ----------------
          const Text(
            "Privacy",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Card(
            child: ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text("Privacy Policy"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // ---------------- DANGER ZONE ----------------
          const Text(
            "Danger Zone",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            color: Colors.red.withOpacity(0.05),
            child: ListTile(
              leading:
              const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text(
                "Delete Account",
                style: TextStyle(color: Colors.red),
              ),
              subtitle: const Text("Permanently delete account and all data"),
              onTap: () => _confirmDelete(context),
            ),
          ),

          const SizedBox(height: 24),

          // ---------------- SESSION ----------------
          const Text(
            "Session",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const SplashScreen(),
                  ),
                      (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- DELETE CONFIRMATION ----------------
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "This will permanently delete your account and all tasks. "
              "This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final result = await AuthService().deleteAccount();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result ?? "Done")),
              );

              if (result == "success") {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const SplashScreen(),
                  ),
                      (route) => false,
                );
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
  void _showNotificationPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enable Reminders"),
        content: const Text(
          "To receive exact task reminders, please enable "
              "‘Alarms & reminders’ permission in system settings.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

}
