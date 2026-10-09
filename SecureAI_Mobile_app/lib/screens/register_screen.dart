import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_text_field.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final res = await ApiService.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _mobileController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() {
      _isLoading = false;
      _isSuccess = res['success'] == true;
      _message = res['message'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.accentPurple.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.accentPurple.withOpacity(0.5)),
                        ),
                        child: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.accentPurple, size: 30),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "Join SecureAI",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Register for AI-Powered Attack Prevention",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),

                      if (_message != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: (_isSuccess ? AppTheme.accentGreen : AppTheme.accentRed).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (_isSuccess ? AppTheme.accentGreen : AppTheme.accentRed).withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            _message!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),

                      CustomTextField(
                        controller: _nameController,
                        label: "Username",
                        hint: "Choose a unique username",
                        icon: Icons.person_outline_rounded,
                        validator: (v) => v == null || v.isEmpty ? "Enter username" : null,
                      ),
                      const SizedBox(height: 14),

                      CustomTextField(
                        controller: _emailController,
                        label: "Email Address",
                        hint: "your.email@example.com",
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v == null || v.isEmpty ? "Enter email address" : null,
                      ),
                      const SizedBox(height: 14),

                      CustomTextField(
                        controller: _mobileController,
                        label: "Mobile Number",
                        hint: "10-digit mobile number",
                        icon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.phone,
                        validator: (v) => v == null || v.isEmpty ? "Enter mobile number" : null,
                      ),
                      const SizedBox(height: 14),

                      CustomTextField(
                        controller: _passwordController,
                        label: "Password",
                        hint: "Create a strong password",
                        icon: Icons.lock_outline_rounded,
                        obscureText: true,
                        validator: (v) => v == null || v.length < 6 ? "Password must be >= 6 chars" : null,
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryIndigo,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  "Create Account",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
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
