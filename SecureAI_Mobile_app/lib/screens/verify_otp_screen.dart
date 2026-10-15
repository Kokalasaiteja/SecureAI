import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/constellation_background.dart';
import '../widgets/secure_ai_app_bar.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  void _verify() {
    if (_otpController.text.trim().length < 4) return;
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushNamed(context, '/reset_password');
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
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
                              Icon(Icons.verified_user_rounded, color: Color(0xFF2DD4BF), size: 26),
                              SizedBox(width: 10),
                              Text(
                                "Verify OTP Code",
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
                            "Enter the 6-digit verification code sent to your registered email",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF), height: 1.4),
                          ),
                          const SizedBox(height: 24),

                          CustomTextField(
                            controller: _otpController,
                            label: "Enter OTP Code",
                            hint: "6-digit OTP code",
                            icon: Icons.key_rounded,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 24),

                          PrimaryButton(
                            text: "Verify & Proceed",
                            icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                            isLoading: _isLoading,
                            onPressed: _verify,
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
