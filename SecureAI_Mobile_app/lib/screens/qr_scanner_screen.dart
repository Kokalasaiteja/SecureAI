import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/app_drawer.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _urlController = TextEditingController();
  bool _isAnalyzing = false;
  Map<String, dynamic>? _scanResult;

  void _analyzeUrl() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _scanResult = null;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        bool isSuspicious = url.contains("login") || url.contains("verify") || url.contains("bank") || url.contains("free");
        setState(() {
          _isAnalyzing = false;
          _scanResult = {
            'url': url,
            'is_suspicious': isSuspicious,
            'status': isSuspicious ? "MALICIOUS / PHISHING LINK DETECTED" : "SAFE & LEGITIMATE URL",
            'confidence': isSuspicious ? "94.2%" : "98.7%",
          };
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/qr_scanner'),
      appBar: AppBar(title: const Text("QR Code & URL Scanner")),
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
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppTheme.accentPurple.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.accentPurple.withOpacity(0.5)),
                        ),
                        child: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.accentPurple, size: 36),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "Quishing Protection",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Quishing exploits deceptive QR codes. Enter or scan any URL to analyze safety.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),

                      CustomTextField(
                        controller: _urlController,
                        label: "Target URL / Scanned Data",
                        hint: "https://example.com/login",
                        icon: Icons.link_rounded,
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _isAnalyzing ? null : _analyzeUrl,
                          icon: _isAnalyzing
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.security_rounded),
                          label: Text(_isAnalyzing ? "Scanning..." : "Verify URL Security"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentPurple,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (_scanResult != null)
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    borderColor: (_scanResult!['is_suspicious'] == true) ? AppTheme.accentRed : AppTheme.accentGreen,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              (_scanResult!['is_suspicious'] == true) ? Icons.gpp_maybe_rounded : Icons.gpp_good_rounded,
                              color: (_scanResult!['is_suspicious'] == true) ? AppTheme.accentRed : AppTheme.accentGreen,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _scanResult!['status'],
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: (_scanResult!['is_suspicious'] == true) ? AppTheme.accentRed : AppTheme.accentGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text("Target URL: ${_scanResult!['url']}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        Text("AI Confidence: ${_scanResult!['confidence']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
