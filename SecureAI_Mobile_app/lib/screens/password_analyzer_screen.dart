import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/app_drawer.dart';
import '../services/api_service.dart';

class PasswordAnalyzerScreen extends StatefulWidget {
  const PasswordAnalyzerScreen({super.key});

  @override
  State<PasswordAnalyzerScreen> createState() => _PasswordAnalyzerScreenState();
}

class _PasswordAnalyzerScreenState extends State<PasswordAnalyzerScreen> {
  final _pwdController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _analysis;

  Future<void> _analyze() async {
    final pwd = _pwdController.text;
    if (pwd.isEmpty) return;

    setState(() {
      _isLoading = true;
      _analysis = null;
    });

    final res = await ApiService.analyzePassword(pwd);

    setState(() {
      _isLoading = false;
      _analysis = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/password_analyzer'),
      appBar: AppBar(title: const Text("Password Strength & Breach Audit")),
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
                          Icon(Icons.shield_rounded, color: Colors.amber, size: 28),
                          SizedBox(width: 12),
                          Text(
                            "Password Audit Tool",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Checks character complexity and queries HaveIBeenPwned database to verify if password has leaked in data breaches.",
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                      const SizedBox(height: 20),

                      CustomTextField(
                        controller: _pwdController,
                        label: "Password to Check",
                        hint: "Enter password...",
                        icon: Icons.key_rounded,
                        obscureText: true,
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _analyze,
                          icon: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.saved_search_rounded),
                          label: Text(_isLoading ? "Auditing..." : "Audit Password Security"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (_analysis != null)
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              (_analysis!['is_strong'] == true) ? Icons.check_circle_rounded : Icons.warning_rounded,
                              color: (_analysis!['is_strong'] == true) ? AppTheme.accentGreen : Colors.amber,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Strength: ${(_analysis!['is_strong'] == true) ? 'Strong' : (_analysis!['is_moderate'] == true) ? 'Moderate' : 'Weak'}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: (_analysis!['is_strong'] == true) ? AppTheme.accentGreen : Colors.amber,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 8),
                        Text(
                          "Password Length: ${_analysis!['length']} characters",
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _analysis!['body'] ?? "Checked against security criteria.",
                          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
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
