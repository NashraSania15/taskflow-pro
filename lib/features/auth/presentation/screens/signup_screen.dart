import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

import '../../data/auth_service.dart';
import 'login_screen.dart';

import 'package:taskflow_pro/core/utils/transitions.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool showPassword = false; // 👁‍🗨 toggle
  bool showConfirm = false;  // 👁‍🗨 toggle

  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: SingleChildScrollView(
          child: FadeTransition(
            opacity: _fade,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  children: [
                    Icon(Icons.person_add_alt_rounded,
                        size: 80, color: scheme.primary),
                    const SizedBox(height: 12),

                    Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),

                    const SizedBox(height: 32),

                    Form(
                      key: formKey,
                      child: Column(
                        children: [
                          // ---------------- EMAIL ----------------
                          TextFormField(
                            controller: emailController,
                            decoration: const InputDecoration(
                              labelText: "Email",
                              prefixIcon: Icon(Icons.email_outlined),
                              filled: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Enter email";
                              }
                              if (!value.contains("@")) {
                                return "Enter valid email";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // ---------------- PASSWORD ----------------
                          TextFormField(
                            controller: passwordController,
                            obscureText: !showPassword,
                            decoration: InputDecoration(
                              labelText: "Password",
                              prefixIcon: const Icon(Icons.lock_outline),
                              filled: true,
                              suffixIcon: IconButton(
                                icon: Icon(showPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off),
                                onPressed: () =>
                                    setState(() => showPassword = !showPassword),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Enter password";
                              }
                              if (value.length < 6) {
                                return "Minimum 6 characters";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // ---------------- CONFIRM PASSWORD ----------------
                          TextFormField(
                            controller: confirmController,
                            obscureText: !showConfirm,
                            decoration: InputDecoration(
                              labelText: "Confirm Password",
                              prefixIcon: const Icon(Icons.lock_outline),
                              filled: true,
                              suffixIcon: IconButton(
                                icon: Icon(showConfirm
                                    ? Icons.visibility
                                    : Icons.visibility_off),
                                onPressed: () =>
                                    setState(() => showConfirm = !showConfirm),
                              ),
                            ),
                            validator: (value) {
                              if (value != passwordController.text) {
                                return "Passwords do not match";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 28),

                          // ---------------- SIGNUP BUTTON ----------------
                          isLoading
                              ? const CircularProgressIndicator()
                              : SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton(
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }

                                setState(() => isLoading = true);

                                final result = await AuthService().signup(
                                  emailController.text.trim(),
                                  passwordController.text.trim(),
                                );

                                setState(() => isLoading = false);

                                if (result == "success") {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "Account created successfully"),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          result ?? "Signup failed"),
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                FadeThroughTransitionPage(
                                    page: const LoginScreen()),
                              );
                            },
                            child: const Text("Already have an account? Login"),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
