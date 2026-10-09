import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_text_field.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService.userLogin(
      _nameController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (res['success'] == true) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      setState(() {
        _errorMessage = res['message'] ?? 'Login failed. Check credentials.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: GlassCard(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.accentGreen.withOpacity(0.5)),
                        ),
                        child: const Icon(Icons.login_rounded, color: AppTheme.accentGreen, size: 32),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "User Login",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Access your SecureAI Sentry Dashboard",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.accentRed.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.accentRed.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppTheme.accentRed, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),

                      CustomTextField(
                        controller: _nameController,
                        label: "Username",
                        hint: "Enter your username",
                        icon: Icons.person_outline_rounded,
                        validator: (v) => v == null || v.isEmpty ? "Enter username" : null,
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _passwordController,
                        label: "Password",
                        hint: "Enter your password",
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) => v == null || v.isEmpty ? "Enter password" : null,
                      ),

                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/forgot_password'),
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(color: AppTheme.accentPurple, fontSize: 13),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryIndigo,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 4,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.login_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      "Login to Dashboard",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? ", style: TextStyle(color: Colors.grey, fontSize: 14)),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/register'),
                            child: const Text(
                              "Register",
                              style: TextStyle(color: AppTheme.accentTeal, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 8),

                      TextButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/admin_login'),
                        icon: const Icon(Icons.admin_panel_settings_outlined, color: AppTheme.accentPink, size: 18),
                        label: const Text(
                          "Admin Login Portal",
                          style: TextStyle(color: AppTheme.accentPink, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
