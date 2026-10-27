import 'package:flutter/material.dart';
import '../widgets/copyright_footer.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/constellation_background.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/secure_ai_app_bar.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
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

  Future<void> _handleAdminLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService.adminLogin(
      _nameController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (res['success'] == true) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/admin_home');
      }
    } else {
      setState(() {
        _errorMessage = res['message'] ?? 'Admin login failed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/admin_login'),
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
                            // Header matching admin_login.html
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.lock_rounded,
                                  color: Color(0xFF818CF8), // text-indigo-400
                                  size: 26,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "Admin Login",
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

                            // 1. Admin Name Field
                            CustomTextField(
                              controller: _nameController,
                              label: "Admin Name",
                              hint: "Enter admin name",
                              icon: Icons.shield_rounded,
                              validator: (v) => v == null || v.trim().isEmpty ? "Enter admin name" : null,
                            ),
                            const SizedBox(height: 16),

                            // 2. Password Field
                            CustomTextField(
                              controller: _passwordController,
                              label: "Password",
                              hint: "Enter password",
                              icon: Icons.key_rounded,
                              obscureText: true,
                              validator: (v) => v == null || v.isEmpty ? "Enter password" : null,
                            ),
                            const SizedBox(height: 24),

                            // Submit Button matching btn-3d with icon
                            PrimaryButton(
                              text: "Admin Login",
                              icon: const Icon(Icons.login_rounded, color: Colors.white, size: 18),
                              isLoading: _isLoading,
                              onPressed: _handleAdminLogin,
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
