import 'package:flutter/material.dart';
import '../widgets/copyright_footer.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/constellation_background.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/secure_ai_app_bar.dart';

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
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
      drawer: const AppDrawer(currentRoute: '/user_login'),
      appBar: SecureAIAppBar.public(title: "SecureAI"),
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header matching user_login.html
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.login_rounded,
                                  color: Color(0xFF818CF8), // text-indigo-400
                                  size: 26,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "User Login",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Error message if any
                            if (_errorMessage != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                margin: const EdgeInsets.only(bottom: 18),
                                decoration: BoxDecoration(
                                  color: const Color(0xCCDC2626), // bg-red-600 bg-opacity-80
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // 1. Name Field
                            CustomTextField(
                              controller: _nameController,
                              label: "Name",
                              hint: "Enter your username",
                              icon: Icons.person_rounded,
                              validator: (v) => v == null || v.trim().isEmpty ? "Enter username" : null,
                            ),
                            const SizedBox(height: 16),

                            // 2. Password Field
                            CustomTextField(
                              controller: _passwordController,
                              label: "Password",
                              hint: "Enter your password",
                              icon: Icons.lock_rounded,
                              obscureText: true,
                              validator: (v) => v == null || v.isEmpty ? "Enter password" : null,
                            ),
                            const SizedBox(height: 22),

                            // Submit Button matching btn-3d bg-indigo-600 with login icon
                            PrimaryButton(
                              text: "Login",
                              icon: const Icon(Icons.login_rounded, color: Colors.white, size: 18),
                              isLoading: _isLoading,
                              onPressed: _handleLogin,
                            ),
                            const SizedBox(height: 14),

                            // Forgot Password Link matching user_login.html
                            Center(
                              child: TextButton.icon(
                                onPressed: () => Navigator.pushNamed(context, '/forgot_password'),
                                icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF818CF8), size: 16),
                                label: const Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                    color: Color(0xFF818CF8),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            const Divider(color: Color(0x3364748B), height: 24),

                            // Don't have account? Register link
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushReplacementNamed(context, '/register');
                                },
                                child: RichText(
                                  text: const TextSpan(
                                    text: "Don't have an account? ",
                                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13.5),
                                    children: [
                                      TextSpan(
                                        text: "Register here",
                                        style: TextStyle(
                                          color: Color(0xFF818CF8),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const CopyrightFooter(),
                ],
              )
            ),
          ),
        ),
      ),
    );
  }
}
