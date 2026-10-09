import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_text_field.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.accentPurple.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.accentPurple.withOpacity(0.5)),
                      ),
                      child: const Icon(Icons.published_with_changes_rounded, color: AppTheme.accentPurple, size: 30),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Set New Password",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Create a new secure password for your account",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    CustomTextField(
                      controller: _passwordController,
                      label: "New Password",
                      hint: "At least 6 characters",
                      icon: Icons.key_rounded,
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _confirmController,
                      label: "Confirm Password",
                      hint: "Re-enter new password",
                      icon: Icons.key_rounded,
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryIndigo,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Update Password", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
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
