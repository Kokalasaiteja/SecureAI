import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/constellation_background.dart';
import '../widgets/app_drawer.dart';
import '../widgets/secure_ai_app_bar.dart';
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
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  String? _selectedFileName;
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _imageFile = picked;
          _selectedFileName = picked.name;
          _message = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error picking image: $e")),
        );
      }
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageFile == null) {
      setState(() {
        _isSuccess = false;
        _message = "Please choose a profile image to complete registration.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final res = await ApiService.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      mobile: _mobileController.text.trim(),
      password: _passwordController.text.trim(),
      imagePath: _imageFile?.path,
      imageName: _imageFile?.name,
    );

    setState(() {
      _isLoading = false;
      _isSuccess = res['success'] == true;
      _message = res['message'];
    });

    if (_isSuccess && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text("Registration successful! Redirecting to login...")),
            ],
          ),
          backgroundColor: AppTheme.accentGreen,
          duration: const Duration(seconds: 2),
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pushReplacementNamed(context, '/user_login');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/register'),
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
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                      borderRadius: 18,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header matching register.html
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.person_add_rounded,
                                  color: Color(0xFF818CF8), // text-indigo-400
                                  size: 26,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "User Registration",
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

                            // Alert message if any
                            if (_message != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                margin: const EdgeInsets.only(bottom: 18),
                                decoration: BoxDecoration(
                                  color: _isSuccess
                                      ? const Color(0xCC059669) // bg-green-600 bg-opacity-80
                                      : const Color(0xCCDC2626), // bg-red-600 bg-opacity-80
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _message!,
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
                              hint: "Enter your full name",
                              icon: Icons.person_rounded,
                              validator: (v) => v == null || v.trim().isEmpty ? "Enter name" : null,
                            ),
                            const SizedBox(height: 16),

                            // 2. Email Field
                            CustomTextField(
                              controller: _emailController,
                              label: "Email",
                              hint: "Enter your email address",
                              icon: Icons.email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => v == null || !v.contains('@') ? "Enter a valid email" : null,
                            ),
                            const SizedBox(height: 16),

                            // 3. Mobile Field
                            CustomTextField(
                              controller: _mobileController,
                              label: "Mobile",
                              hint: "Enter your mobile number",
                              icon: Icons.phone_rounded,
                              keyboardType: TextInputType.phone,
                              validator: (v) => v == null || v.trim().length < 10 ? "Enter 10-digit mobile number" : null,
                            ),
                            const SizedBox(height: 16),

                            // 4. Password Field
                            CustomTextField(
                              controller: _passwordController,
                              label: "Password",
                              hint: "Enter a strong password",
                              icon: Icons.lock_rounded,
                              obscureText: true,
                              validator: (v) => v == null || v.length < 6 ? "Password must be >= 6 characters" : null,
                            ),
                            const SizedBox(height: 16),

                            // 5. Profile Image Field matching register.html
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.image_rounded,
                                      size: 16,
                                      color: Color(0xFFA78BFA), // text-purple-400
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      "Profile Image",
                                      style: TextStyle(
                                        color: Color(0xFFD1D5DB),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF111827), // bg-gray-900
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF374151), width: 1.0),
                                  ),
                                  child: Row(
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: _pickImage,
                                        icon: const Icon(Icons.file_upload_outlined, size: 16),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: const Color(0xFF1F2937),
                                          side: const BorderSide(color: Color(0xFF4B5563)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                        label: const Text("Choose file", style: TextStyle(fontSize: 12)),
                                      ),
                                      const SizedBox(width: 12),
                                      if (_imageFile != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: Image.file(
                                            File(_imageFile!.path),
                                            width: 32,
                                            height: 32,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      if (_imageFile != null) const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _selectedFileName ?? "No file chosen",
                                          style: TextStyle(
                                            color: _imageFile != null ? const Color(0xFF818CF8) : const Color(0xFF9CA3AF),
                                            fontSize: 13,
                                            fontWeight: _imageFile != null ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Submit Button matching btn-3d bg-indigo-600 with rocket icon
                            PrimaryButton(
                              text: "Register",
                              icon: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 18),
                              isLoading: _isLoading,
                              onPressed: _handleRegister,
                            ),
                            const SizedBox(height: 18),

                            // Already have account? Login link
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushReplacementNamed(context, '/user_login');
                                },
                                child: RichText(
                                  text: const TextSpan(
                                    text: "Already have an account? ",
                                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13.5),
                                    children: [
                                      TextSpan(
                                        text: "Login here",
                                        style: TextStyle(
                                          color: Color(0xFF818CF8), // text-indigo-400
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
