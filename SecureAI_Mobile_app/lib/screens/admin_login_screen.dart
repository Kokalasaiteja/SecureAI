import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_text_field.dart';
import '../services/api_service.dart';

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
        Navigator.pushReplacementNamed(context, '/admin_dashboard');
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
      appBar: AppBar(
        title: const Text("Admin Portal"),
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
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.accentPink.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.accentPink.withOpacity(0.5)),
                        ),
                        child: const Icon(Icons.lock_person_rounded, color: AppTheme.accentPink, size: 32),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Admin Portal",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Management & User Control Console",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),

                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.accentRed.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.accentRed.withOpacity(0.4)),
                          ),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),

                      CustomTextField(
                        controller: _nameController,
                        label: "Admin Username",
                        hint: "Default: admin",
                        icon: Icons.admin_panel_settings_rounded,
                        validator: (v) => v == null || v.isEmpty ? "Enter admin username" : null,
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _passwordController,
                        label: "Admin Password",
                        hint: "Default: admin",
                        icon: Icons.key_rounded,
                        obscureText: true,
                        validator: (v) => v == null || v.isEmpty ? "Enter admin password" : null,
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleAdminLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentPink,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  "Login to Admin Console",
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
