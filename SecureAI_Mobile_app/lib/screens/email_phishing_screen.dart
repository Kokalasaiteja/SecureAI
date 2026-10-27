import 'package:flutter/material.dart';
import '../widgets/copyright_footer.dart';
import '../widgets/glass_card.dart';
import '../widgets/constellation_background.dart';
import '../widgets/app_drawer.dart';
import '../services/api_service.dart';
import '../widgets/secure_ai_app_bar.dart';

class EmailPhishingScreen extends StatefulWidget {
  const EmailPhishingScreen({super.key});

  @override
  State<EmailPhishingScreen> createState() => _EmailPhishingScreenState();
}

class _EmailPhishingScreenState extends State<EmailPhishingScreen> {
  final _emailTextController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _errorMessage;

  Future<void> _analyzeEmail() async {
    final text = _emailTextController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = "Please enter email content to analyze.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    final res = await ApiService.analyzeEmailPhishing(text);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (res['success'] == true) {
        _result = res;
      } else {
        _errorMessage = res['message']?.toString() ?? "Phishing analysis failed.";
      }
    });
  }

  String _cleanText(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&#x27;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final String classification = _result?['classification']?.toString() ??
        _result?['result']?.toString() ??
        'Legitimate';
    final String explanation = _cleanText(_result?['body']?.toString() ??
        "Standard communication structure. No immediate social engineering red flags identified.");

    final bool isPhishing = classification.toLowerCase().contains("phishing");
    final bool isSuspicious = classification.toLowerCase().contains("suspicious");

    Color statusColor = const Color(0xFF22C55E); // Green
    IconData statusIcon = Icons.verified_user_rounded;
    if (isPhishing) {
      statusColor = const Color(0xFFEF4444); // Red
      statusIcon = Icons.dangerous_rounded;
    } else if (isSuspicious) {
      statusColor = const Color(0xFFEAB308); // Yellow
      statusIcon = Icons.warning_amber_rounded;
    }

    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/email_phishing'),
      appBar: SecureAIAppBar.user(title: "SecureAI Panel"),
      body: ConstellationBackground(
        gradientColors: const [
          Color(0xFF3B82F6), // from-blue-500
          Color(0xFF0EA5E9), // via-sky-500
          Color(0xFF06B6D4), // to-cyan-500
        ],
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title matching email_phishing.html
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.mark_email_read_rounded, color: Color(0xFF60A5FA), size: 26),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "Email Phishing Analyzer",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
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
                    "Paste the contents of a suspicious email below. Our AI will analyze the text for common social engineering tactics, artificial urgency, and deceptive phrasing.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFFD1D5DB), height: 1.45),
                  ),
                  const SizedBox(height: 22),

                  // Error notification box
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

                  // Label: Suspicious Email Content
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Suspicious Email Content",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Textarea matching email_phishing.html
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827), // bg-gray-900
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF374151)), // border-gray-700
                    ),
                    child: TextField(
                      controller: _emailTextController,
                      maxLines: 6,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: "Dear user, your account has been compromised. Please click the link below to verify your identity within 24 hours...",
                        hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Analyze Email Button (Gradient Blue to Indigo)
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF4F46E5)], // blue-600 to indigo-600
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _analyzeEmail,
                      icon: _isLoading
                          ? const SizedBox.shrink()
                          : const Icon(Icons.smart_toy_rounded, size: 20, color: Colors.white),
                      label: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                            )
                          : const Text(
                              "Analyze Email",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  // Report Section matching email_phishing.html
                  if (_result != null) ...[
                    const SizedBox(height: 26),
                    const Divider(color: Color(0xFF374151)),
                    const SizedBox(height: 16),

                    const Text(
                      "AI Analysis Report",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Classification Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827), // bg-gray-900
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: statusColor, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.25),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "CLASSIFICATION",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(statusIcon, color: statusColor, size: 30),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  classification,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Explanation & Red Flags Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827), // bg-gray-900
                        borderRadius: BorderRadius.circular(14),
                        border: const Border(
                          left: BorderSide(color: Color(0xFF3B82F6), width: 4),
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
                              Icon(Icons.shield_outlined, color: Color(0xFF60A5FA), size: 20),
                              SizedBox(width: 8),
                              Text(
                                "Explanation & Red Flags",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF60A5FA),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildFormattedExplanation(explanation),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const CopyrightFooter(),
          ],
        ),
      ),
    ),
  ),
);
  }

  Widget _buildFormattedExplanation(String rawText) {
    if (rawText.trim().isEmpty) {
      return const Text(
        "No detailed explanation provided.",
        style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
      );
    }

    final rawLines = rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final List<Widget> items = [];

    for (final rawLine in rawLines) {
      bool isBullet = false;
      String line = rawLine;

      if (line.startsWith('* ') || line.startsWith('- ') || line.startsWith('• ')) {
        isBullet = true;
        line = line.substring(2).trim();
      }

      // Parse bold segments (**bold**) into TextSpans
      final parts = RegExp(r'(\b|\B)(\*\*.*?\*\*)(\b|\B)').allMatches(line);
      final List<InlineSpan> spans = [];

      int lastIndex = 0;
      for (final match in parts) {
        final matchStart = match.start;
        final matchEnd = match.end;

        if (matchStart > lastIndex) {
          spans.add(TextSpan(
            text: line.substring(lastIndex, matchStart),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.normal,
              color: Color(0xFFD1D5DB),
              height: 1.5,
            ),
          ));
        }

        final matchText = match.group(0)!;
        final boldContent = matchText.replaceAll('**', '').trim();
        spans.add(TextSpan(
          text: boldContent.endsWith(':') ? '$boldContent ' : boldContent,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.5,
          ),
        ));

        lastIndex = matchEnd;
      }

      if (lastIndex < line.length) {
        spans.add(TextSpan(
          text: line.substring(lastIndex),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.normal,
            color: Color(0xFFD1D5DB),
            height: 1.5,
          ),
        ));
      }

      if (spans.isEmpty) {
        spans.add(TextSpan(
          text: line.replaceAll('**', ''),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.normal,
            color: Color(0xFFD1D5DB),
            height: 1.5,
          ),
        ));
      }

      if (isBullet) {
        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6, right: 10),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF60A5FA),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF3B82F6),
                        blurRadius: 4,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(children: spans),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RichText(
              text: TextSpan(children: spans),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }

}
