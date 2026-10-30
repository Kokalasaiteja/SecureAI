import 'package:flutter/material.dart';
import '../widgets/copyright_footer.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/constellation_background.dart';
import '../widgets/secure_ai_app_bar.dart';
import '../services/api_service.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  String? _targetEmail;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.isNotEmpty && _targetEmail == null) {
      _targetEmail = args;
      _emailController.text = args;
    }
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    final email = (_targetEmail != null && _targetEmail!.isNotEmpty)
        ? _targetEmail!
        : _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email address is required."),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (otp.isEmpty || otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter the complete 6-digit OTP code."),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final res = await ApiService.verifyOtp(email, otp);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? "OTP verified successfully!"),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      final resetToken = res['reset_token']?.toString();
      Navigator.pushNamed(context, '/reset_password', arguments: {
        'email': email,
        'reset_token': resetToken,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? "Invalid OTP code! Please check and try again."),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _resendOtp() async {
    final email = (_targetEmail != null && _targetEmail!.isNotEmpty)
        ? _targetEmail!
        : _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email to resend OTP.")),
      );
      return;
    }

    setState(() => _isResending = true);
    final res = await ApiService.forgotPassword(email);
    if (!mounted) return;
    setState(() => _isResending = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("New OTP code dispatched to your email!"),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? "Failed to resend OTP."),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasEmailArg = _targetEmail != null && _targetEmail!.isNotEmpty;

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
                          Text(
                            hasEmailArg
                                ? "Enter the 6-digit verification code sent to: $_targetEmail"
                                : "Enter the 6-digit verification code sent to your registered email",
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF), height: 1.4),
                          ),
                          const SizedBox(height: 24),

                          if (!hasEmailArg) ...[
                            CustomTextField(
                              controller: _emailController,
                              label: "Email Address",
                              hint: "your.email@example.com",
                              icon: Icons.email_rounded,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                          ],

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
                          const SizedBox(height: 14),

                          TextButton.icon(
                            onPressed: _isResending ? null : _resendOtp,
                            icon: _isResending
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(color: Color(0xFF2DD4BF), strokeWidth: 1.8),
                                  )
                                : const Icon(Icons.refresh_rounded, color: Color(0xFF2DD4BF), size: 16),
                            label: const Text(
                              "Resend OTP",
                              style: TextStyle(
                                color: Color(0xFF2DD4BF),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
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
