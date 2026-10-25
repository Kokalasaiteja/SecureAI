import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import '../widgets/constellation_background.dart';
import '../widgets/app_drawer.dart';
import '../services/api_service.dart';
import '../widgets/secure_ai_app_bar.dart';

class SpamDetectorScreen extends StatefulWidget {
  const SpamDetectorScreen({super.key});

  @override
  State<SpamDetectorScreen> createState() => _SpamDetectorScreenState();
}

class _SpamDetectorScreenState extends State<SpamDetectorScreen> {
  final _messageController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  Future<void> _analyzeMessage() async {
    final msg = _messageController.text.trim();
    if (msg.isEmpty) return;

    setState(() {
      _isLoading = true;
      _result = null;
    });

    final res = await ApiService.detectSpam(msg);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _result = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = _result != null && _result!['success'] == false;
    final bool hasResult = _result != null && _result!['success'] == true;
    final String resultText = _result?['result']?.toString() ?? 'Safe';
    final String explanationText = ApiService.unescapeHtml(_result?['body']?.toString() ?? 'No malicious indicators detected.');

    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/detect_spam'),
      appBar: SecureAIAppBar.user(title: "SecureAI Panel"),
      body: ConstellationBackground(
        gradientColors: const [
          Color(0xFF22C55E), // from-green-500
          Color(0xFF10B981), // via-emerald-500
          Color(0xFF0D9488), // to-teal-600
        ],
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon matching detect.html
                  Image.network(
                    "https://cdn-icons-png.flaticon.com/512/561/561127.png",
                    width: 72,
                    height: 72,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.mark_email_unread_rounded,
                      color: Color(0xFF10B981),
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Title matching detect.html
                  const Text(
                    "📩 SMS Spam Detector",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtitle matching detect.html
                  const Text(
                    "Detect if a message is spam using our Gemini-powered model.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE5E7EB),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Label: Enter Message:
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Enter Message:",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Textarea matching detect.html
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827), // bg-gray-900
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF4B5563)), // border-gray-600
                    ),
                    child: TextField(
                      controller: _messageController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: "Type your SMS here...",
                        hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button (Check) in teal matching detect.html
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _analyzeMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488), // bg-teal-600
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                            )
                          : const Text(
                              "Check",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  // Error Display matching detect.html
                  if (hasError) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Color(0xFFF87171), size: 20),
                              SizedBox(width: 8),
                              Text("Error", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _result?['message']?.toString() ?? "Detection failed.",
                            style: const TextStyle(color: Color(0xFFFECACA), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Result Display matching detect.html
                  if (hasResult) ...[
                    const SizedBox(height: 22),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xF0111827), // bg-gray-900 bg-opacity-90
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF374151)), // border-gray-700
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 16, color: Colors.white),
                              children: [
                                const TextSpan(
                                  text: "📌 Result: ",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: resultText,
                                  style: const TextStyle(
                                    color: Color(0xFFFDE047), // text-yellow-300
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 13, color: Color(0xFFD1D5DB), height: 1.5),
                              children: [
                                const TextSpan(
                                  text: "Explanation: ",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                TextSpan(text: explanationText),
                              ],
                            ),
                          ),
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
}
