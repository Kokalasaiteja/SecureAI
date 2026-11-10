import 'package:flutter/material.dart';
import '../models/audit_presentation.dart';
import '../widgets/copyright_footer.dart';
import '../widgets/glass_card.dart';
import '../widgets/constellation_background.dart';
import '../widgets/app_drawer.dart';
import '../services/api_service.dart';
import '../services/session_cache.dart';
import '../widgets/secure_ai_app_bar.dart';

class SpamDetectorScreen extends StatefulWidget {
  const SpamDetectorScreen({super.key});

  @override
  State<SpamDetectorScreen> createState() => _SpamDetectorScreenState();
}

class _SpamDetectorScreenState extends State<SpamDetectorScreen> {
  late final TextEditingController _messageController;
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _lastAnalyzedText;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(text: SessionCache.smsInput ?? '');
    _result = SessionCache.smsResult;
    _isLoading = SessionCache.smsLoading;
    _lastAnalyzedText = SessionCache.smsInput;

    // If an analysis was initiated and running in background, reattach to its completion:
    if (SessionCache.smsFuture != null && (_result == null || SessionCache.smsLoading)) {
      SessionCache.smsFuture!.then((res) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _result = res;
          });
        }
      });
    }

    _messageController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    final text = _messageController.text;
    SessionCache.smsInput = text;
    // Dismiss and clear result only as soon as user changes or edits input away from analyzed text
    if (_result != null && text.trim() != (_lastAnalyzedText ?? '').trim()) {
      setState(() {
        _result = null;
      });
      SessionCache.smsResult = null;
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onInputChanged);
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _analyzeMessage() async {
    final msg = _messageController.text.trim();
    if (msg.isEmpty) return;

    setState(() {
      _isLoading = true;
      _result = null;
      _lastAnalyzedText = msg;
    });

    final future = SessionCache.startSmsAnalysis(msg);

    try {
      final res = await future;
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _result = res;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = _result != null && _result!['success'] == false;
    final bool hasResult = _result != null && _result!['success'] == true;
    final String resultText = _result?['result']?.toString() ?? _result?['classification']?.toString() ?? 'Ham';
    final String rawExp = ApiService.unescapeHtml(_result?['explanation']?.toString() ?? _result?['body']?.toString() ?? 'No malicious indicators detected.');
    final String explanationText = rawExp.replaceFirst(
      RegExp(r'^(?:(?:classification|result|verdict|status)\s*[:\-\—]\s*)?(?:ham|spam)\s*[:\-\—\.\,]\s*(?:explanation\s*[:\-\—]\s*)?|^(?:explanation\s*[:\-\—]\s*)', caseSensitive: false),
      '',
    ).trim();

    final presentation = AuditPresentation.computeSmsPresentation(_result);
    final bool isSpam = presentation.isPhishingOrSpam;
    final Color statusColor = presentation.statusColor;
    final IconData statusIcon = presentation.statusIcon;
    final String statusSubtitle = presentation.statusSubtitle;

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
            child: Column(
              children: [
                GlassCard(
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
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.2,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "Checking SMS...",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
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
                        border: Border.all(color: statusColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(statusIcon, color: statusColor, size: 22),
                              const SizedBox(width: 8),
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
                                      style: TextStyle(
                                        color: isSpam ? const Color(0xFFEF4444) : const Color(0xFFFDE047),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (statusSubtitle.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              statusSubtitle,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: statusColor.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          const Text(
                            "Findings & Explanation:",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildSmsExplanation(explanationText),
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

  Widget _buildSmsExplanation(String rawText) {
    if (rawText.trim().isEmpty) {
      return const Text(
        "No detailed explanation is available.",
        style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
      );
    }

    final rawLines = rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final List<Widget> items = [];

    for (final rawLine in rawLines) {
      String line = rawLine;
      if (line.startsWith('* ') || line.startsWith('- ') || line.startsWith('• ')) {
        line = line.substring(2).trim();
      }

      // Separate Link Verification into its own dedicated prominent card
      final isLink = RegExp(r'^Link Verification\s*:', caseSensitive: false).hasMatch(line);
      if (isLink) {
        final bodyText = line.replaceFirst(RegExp(r'^Link Verification\s*:\s*', caseSensitive: false), '').trim();
        items.add(
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2922),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF14B8A6), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.link_rounded, color: Color(0xFF2DD4BF), size: 18),
                    SizedBox(width: 8),
                    Text(
                      "LINK VERIFICATION",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: Color(0xFF2DD4BF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  bodyText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFE5E7EB),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Handle other findings / bullet points with Heading: Body
      final colonIndex = line.indexOf(':');
      if (colonIndex > 0 && !line.toLowerCase().startsWith('http://') && !line.toLowerCase().startsWith('https://')) {
        final heading = line.substring(0, colonIndex).replaceAll('*', '').trim();
        final body = line.substring(colonIndex + 1).replaceAll('*', '').trim();

        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF10B981),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF10B981),
                        blurRadius: 4,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, color: Color(0xFFD1D5DB), height: 1.45),
                      children: [
                        TextSpan(
                          text: '$heading: ',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        TextSpan(text: body),
                      ],
                    ),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF10B981),
                  ),
                ),
                Expanded(
                  child: Text(
                    line.replaceAll('**', '').replaceAll('*', ''),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFD1D5DB),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
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
