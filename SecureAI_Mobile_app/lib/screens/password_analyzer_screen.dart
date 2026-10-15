import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import '../widgets/constellation_background.dart';
import '../widgets/app_drawer.dart';
import '../services/api_service.dart';
import '../widgets/secure_ai_app_bar.dart';

class PasswordAnalyzerScreen extends StatefulWidget {
  const PasswordAnalyzerScreen({super.key});

  @override
  State<PasswordAnalyzerScreen> createState() => _PasswordAnalyzerScreenState();
}

class _PasswordAnalyzerScreenState extends State<PasswordAnalyzerScreen> {
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _errorMessage;

  Future<void> _analyze() async {
    final pwd = _passwordController.text;
    if (pwd.isEmpty) {
      setState(() {
        _errorMessage = "Please enter a password to analyze.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    final res = await ApiService.analyzePassword(pwd);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (res['success'] == true) {
        _result = res;
      } else {
        _errorMessage = res['message']?.toString() ?? "Analysis failed.";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String strength = _result?['strength']?.toString() ?? 'Moderate';
    final int breachCount = _result?['breach_count'] ?? 0;
    final bool hasLength = _result?['has_length'] ?? false;
    final bool hasUpper = _result?['has_upper'] ?? false;
    final bool hasLower = _result?['has_lower'] ?? false;
    final bool hasDigit = _result?['has_digit'] ?? false;
    final bool hasSpecial = _result?['has_special'] ?? false;

    Color strengthColor = const Color(0xFFEAB308); // yellow
    if (strength.toLowerCase() == 'strong') {
      strengthColor = const Color(0xFF22C55E); // green
    } else if (strength.toLowerCase() == 'weak') {
      strengthColor = const Color(0xFFEF4444); // red
    }

    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/password_analyzer'),
      appBar: SecureAIAppBar.user(title: "SecureAI Panel"),
      body: ConstellationBackground(
        gradientColors: const [
          Color(0xFFEAB308), // from-yellow-500
          Color(0xFFF97316), // via-orange-500
          Color(0xFFEF4444), // to-red-500
        ],
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title matching password_analyzer.html
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.shield_rounded, color: Color(0xFFFACC15), size: 26),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "Password Strength & Breach Analyzer",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Subtitle matching web
                  const Text(
                    "Enter a password to check its strength and see if it has been exposed in known data breaches.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFFD1D5DB), height: 1.4),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "(Uses k-Anonymity with Have I Been Pwned API; your password is secure).",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                  ),
                  const SizedBox(height: 22),

                  // Error if any
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                      ),
                      child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFFECACA), fontSize: 13)),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Password Input with Eye Icon
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827), // bg-gray-900
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF374151)), // border-gray-700
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: "Type a password to analyze...",
                        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: const Color(0xFF9CA3AF),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Button: Analyze Password (Amber/Gold bg-yellow-600)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _analyze,
                      icon: _isLoading
                          ? const SizedBox.shrink()
                          : const Icon(Icons.search_rounded, size: 20),
                      label: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                            )
                          : const Text(
                              "Analyze Password",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCA8A04), // bg-yellow-600
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                    ),
                  ),

                  // Results Section matching password_analyzer.html
                  if (_result != null) ...[
                    const SizedBox(height: 26),
                    const Divider(color: Color(0xFF374151)),
                    const SizedBox(height: 16),

                    const Text(
                      "Analysis Results",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Strength Rating Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827), // bg-gray-900
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          left: BorderSide(color: strengthColor, width: 4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.fitness_center_rounded, color: Color(0xFFFACC15), size: 16),
                              SizedBox(width: 8),
                              Text("Strength Rating", style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            strength,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: strengthColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Breach Exposure Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827), // bg-gray-900
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          left: BorderSide(
                            color: breachCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                            width: 4,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.storage_rounded, color: Color(0xFF60A5FA), size: 16),
                              SizedBox(width: 8),
                              Text("Breach Exposure", style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "$breachCount times",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: breachCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            breachCount > 0
                                ? "This password is highly vulnerable!"
                                : "Safe! Not found in known breaches.",
                            style: TextStyle(
                              fontSize: 12,
                              color: breachCount > 0 ? const Color(0xFFF87171) : const Color(0xFF4ADE80),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Characteristics Checklist Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827), // bg-gray-900
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1F2937)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.checklist_rounded, color: Color(0xFF2DD4BF), size: 18),
                              SizedBox(width: 8),
                              Text("Characteristics", style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildCharacteristicItem("8+ Characters", hasLength),
                          const SizedBox(height: 8),
                          _buildCharacteristicItem("Uppercase Letter", hasUpper),
                          const SizedBox(height: 8),
                          _buildCharacteristicItem("Lowercase Letter", hasLower),
                          const SizedBox(height: 8),
                          _buildCharacteristicItem("Number", hasDigit),
                          const SizedBox(height: 8),
                          _buildCharacteristicItem("Special Character", hasSpecial),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCharacteristicItem(String label, bool passed) {
    return Row(
      children: [
        Icon(
          passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: passed ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
          size: 18,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ],
    );
  }
}
