import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_text_field.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify OTP"),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.accentTeal.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.accentTeal.withOpacity(0.5)),
                      ),
                      child: const Icon(Icons.verified_user_rounded, color: AppTheme.accentTeal, size: 30),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Enter Verification Code",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Enter the passcode sent to your registered email",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    CustomTextField(
                      controller: _otpController,
                      label: "One-Time Password (OTP)",
                      hint: "Enter 6-digit OTP",
                      icon: Icons.lock_clock_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentTeal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Verify Passcode", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
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
