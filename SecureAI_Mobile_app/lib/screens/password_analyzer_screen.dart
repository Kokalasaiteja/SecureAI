import 'package:flutter/material.dart';
import '../widgets/copyright_footer.dart';
import '../widgets/glass_card.dart';
import '../widgets/constellation_background.dart';
import '../widgets/app_drawer.dart';
import '../services/api_service.dart';
import '../widgets/secure_ai_app_bar.dart';
import '../widgets/http_error_widget.dart';

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
  int? _errorStatusCode;

  Future<void> _analyze() async {
    final pwd = _passwordController.text;
    if (pwd.isEmpty) {
      setState(() {
        _errorMessage = "Please enter a password to analyze.";
        _errorStatusCode = 400;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _errorStatusCode = null;
      _result = null;
    });

    final res = await ApiService.analyzePassword(pwd);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (res['success'] == true) {
        _result = res;
        _errorMessage = null;
        _errorStatusCode = null;
      } else {
        _errorMessage = res['message']?.toString() ?? "Analysis failed.";
        _errorStatusCode = res['statusCode'] as int? ?? 500;
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
          Color(0xFFEAB308), // from-yellow-500 (color as before)
          Color(0xFFF97316), // via-orange-500
          Color(0xFFEF4444), // to-red-500
        ],
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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

                      // Error if any (Liquid Glass HttpErrorWidget)
                      if (_errorMessage != null) ...[
                        HttpErrorWidget(
                          statusCode: _errorStatusCode ?? 500,
                          message: _errorMessage,
                          onRetry: _analyze,
                          isCompact: true,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Password Input with Eye Icon
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF111827), // bg-gray-900 (color as before)
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

                      // Button: Analyze Password
                      Center(
                        child: SizedBox(
                          width: 220,
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
                              backgroundColor: const Color(0xFFCA8A04), // bg-yellow-600 (color as before)
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Results Section matching Image 1
                if (_result != null) ...[
                  const SizedBox(height: 28),
                  const Text(
                    "Analysis Results",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Two Side-by-Side Cards: Strength Rating & Breach Exposure
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Card: Strength Rating
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF131B2E), // dark slate navy from img 1
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.fitness_center_rounded, color: Color(0xFFF59E0B), size: 18),
                                    SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        "Strength Rating",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    strength,
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: strengthColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Right Card: Breach Exposure
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF131B2E), // dark slate navy from img 1
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.dns_rounded, color: Color(0xFF60A5FA), size: 18),
                                    SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        "Breach Exposure",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "$breachCount times",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: breachCount > 0 ? const Color(0xFFF87171) : const Color(0xFF22C55E),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  breachCount > 0
                                      ? "This password is highly vulnerable!"
                                      : "Safe! Not found in known breaches.",
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.3,
                                    color: breachCount > 0 ? const Color(0xFFF87171) : const Color(0xFF4ADE80),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bottom Card: Characteristics Checklist Box (Two-column layout matching img 1)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131B2E), // dark slate navy from img 1
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.checklist_rounded, color: Color(0xFF2DD4BF), size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Characteristics",
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column: 8+ Characters, Lowercase Letter, Special Character
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildCharacteristicRow("8+ Characters", hasLength),
                                  const SizedBox(height: 12),
                                  _buildCharacteristicRow("Lowercase Letter", hasLower),
                                  const SizedBox(height: 12),
                                  _buildCharacteristicRow("Special Character", hasSpecial),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Right Column: Uppercase Letter, Number
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildCharacteristicRow("Uppercase Letter", hasUpper),
                                  const SizedBox(height: 12),
                                  _buildCharacteristicRow("Number", hasDigit),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const CopyrightFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCharacteristicRow(String label, bool passed) {
    return Row(
      children: [
        Icon(
          passed ? Icons.check_rounded : Icons.close_rounded,
          color: passed ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
