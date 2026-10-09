import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/app_drawer.dart';
import '../services/api_service.dart';

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

    setState(() {
      _isLoading = false;
      _result = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/detect_spam'),
      appBar: AppBar(
        title: const Text("SMS Spam Detection"),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.sms_rounded, color: AppTheme.accentGreen, size: 28),
                          SizedBox(width: 12),
                          Text(
                            "SMS Content Checker",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Analyze suspicious text messages for scam links, fraudulent offers, and phishing bait using AI Sentry.",
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                      const SizedBox(height: 20),

                      CustomTextField(
                        controller: _messageController,
                        label: "SMS Text Message",
                        hint: "Paste the text message content here...",
                        icon: Icons.chat_bubble_outline_rounded,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _analyzeMessage,
                          icon: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.search_rounded),
                          label: Text(_isLoading ? "Analyzing..." : "Analyze SMS Text"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (_result != null)
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    borderColor: (_result!['is_spam'] == true) ? AppTheme.accentRed : AppTheme.accentGreen,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              (_result!['is_spam'] == true) ? Icons.warning_rounded : Icons.check_circle_rounded,
                              color: (_result!['is_spam'] == true) ? AppTheme.accentRed : AppTheme.accentGreen,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Result: ${_result!['result']}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: (_result!['is_spam'] == true) ? AppTheme.accentRed : AppTheme.accentGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 8),
                        const Text(
                          "Analysis Breakdown:",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _result!['body'] ?? "Analyzed by AI Sentry.",
                          style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
