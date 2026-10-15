import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/constellation_background.dart';
import '../widgets/secure_ai_app_bar.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  void _resetPassword() {
    if (_passwordController.text.length < 6) return;
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password updated successfully!")),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/user_login', (r) => false);
      }
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SecureAIAppBar.public(
        title: "SecureAI",
        showBackButton: true,
      ),
      body: ConstellationBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                      borderRadius: 18,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.lock_reset_rounded, color: Color(0xFF818CF8), size: 26),
                              SizedBox(width: 10),
                              Text(
                                "Set New Password",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Create a strong, unique password for your SecureAI account",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF), height: 1.4),
                          ),
                          const SizedBox(height: 24),

                          CustomTextField(
                            controller: _passwordController,
                            label: "New Password",
                            hint: "Enter new password (min. 6 characters)",
                            icon: Icons.lock_outline_rounded,
                            obscureText: true,
                          ),
                          const SizedBox(height: 16),

                          CustomTextField(
                            controller: _confirmController,
                            label: "Confirm Password",
                            hint: "Re-enter new password",
                            icon: Icons.lock_rounded,
                            obscureText: true,
                          ),
                          const SizedBox(height: 24),

                          PrimaryButton(
                            text: "Update Password",
                            icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                            isLoading: _isLoading,
                            onPressed: _resetPassword,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
