import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/app_drawer.dart';
import '../services/api_service.dart';

class EmailPhishingScreen extends StatefulWidget {
  const EmailPhishingScreen({super.key});

  @override
  State<EmailPhishingScreen> createState() => _EmailPhishingScreenState();
}

class _EmailPhishingScreenState extends State<EmailPhishingScreen> {
  final _emailTextController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  Future<void> _analyzeEmail() async {
    final text = _emailTextController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _result = null;
    });

    final res = await ApiService.analyzeEmailPhishing(text);

    setState(() {
      _isLoading = false;
      _result = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/email_phishing'),
      appBar: AppBar(title: const Text("Email Phishing Analyzer")),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.mark_email_read_rounded, color: Colors.blueAccent, size: 28),
                          SizedBox(width: 12),
                          Text(
                            "AI Email Inspector",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Paste full email body or headers to scan for spear-phishing, urgency traps, and suspicious links.",
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                      const SizedBox(height: 20),

                      CustomTextField(
                        controller: _emailTextController,
                        label: "Email Content",
                        hint: "Paste email body text here...",
                        icon: Icons.email_rounded,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _analyzeEmail,
                          icon: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.manage_search_rounded),
                          label: Text(_isLoading ? "Scanning Email..." : "Scan Email for Phishing"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
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
                    borderColor: (_result!['is_phishing'] == true) ? AppTheme.accentRed : AppTheme.accentGreen,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              (_result!['is_phishing'] == true) ? Icons.warning_rounded : Icons.check_circle_rounded,
                              color: (_result!['is_phishing'] == true) ? AppTheme.accentRed : AppTheme.accentGreen,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _result!['result'],
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: (_result!['is_phishing'] == true) ? AppTheme.accentRed : AppTheme.accentGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 8),
                        Text(
                          _result!['body'] ?? "Email analyzed by AI Sentry Engine.",
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
