import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/home'),
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.shield_rounded, color: AppTheme.accentTeal, size: 22),
            SizedBox(width: 8),
            Text(
              "SecureAI Panel",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Hero Banner Card
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryIndigo.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.security, color: AppTheme.accentTeal, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "AI Sentry Shield",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "Real-time Attack Prevention",
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.accentGreen.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.circle, color: AppTheme.accentGreen, size: 8),
                              SizedBox(width: 6),
                              Text(
                                "Active",
                                style: TextStyle(
                                  color: AppTheme.accentGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "SecureAI leverages machine learning models (XGBoost, Random Forest, & LLM Chains) to counter traditional and AI-enabled threats including phishing, vishing, smishing, and whaling in real-time.",
                      style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Grid Feature Tools
              const Text(
                "AI Defense Tools",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
                children: [
                  _buildToolTile(
                    context,
                    title: "SMS Spam",
                    subtitle: "Detect fake texts",
                    icon: Icons.sms_rounded,
                    color: AppTheme.accentGreen,
                    route: "/detect_spam",
                  ),
                  _buildToolTile(
                    context,
                    title: "QR Scanner",
                    subtitle: "Scan malicious URLs",
                    icon: Icons.qr_code_scanner_rounded,
                    color: AppTheme.accentPurple,
                    route: "/qr_scanner",
                  ),
                  _buildToolTile(
                    context,
                    title: "Behavior AI",
                    subtitle: "Anomaly detection",
                    icon: Icons.security_rounded,
                    color: AppTheme.primaryIndigo,
                    route: "/anomaly_prediction",
                  ),
                  _buildToolTile(
                    context,
                    title: "Password Audit",
                    subtitle: "Breach check",
                    icon: Icons.shield_rounded,
                    color: Colors.amber,
                    route: "/password_analyzer",
                  ),
                  _buildToolTile(
                    context,
                    title: "Email Phishing",
                    subtitle: "AI text classifier",
                    icon: Icons.mark_email_read_rounded,
                    color: Colors.blueAccent,
                    route: "/email_phishing",
                  ),
                  _buildToolTile(
                    context,
                    title: "Train Models",
                    subtitle: "Retrain AI Sentry",
                    icon: Icons.psychology_rounded,
                    color: AppTheme.accentPink,
                    route: "/train_models",
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Attack Vectors Overview
              const Text(
                "Social Engineering Vectors",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),

              _buildVectorCard(
                title: "Phishing & Vishing",
                description: "Deceptive emails and voice calls used to steal sensitive user credentials.",
                icon: Icons.phishing_rounded,
                iconColor: AppTheme.accentPurple,
              ),
              const SizedBox(height: 10),
              _buildVectorCard(
                title: "Smishing & Quishing",
                description: "Exploiting mobile SMS and deceptive QR codes to trick users into downloading malware.",
                icon: Icons.qr_code_2_rounded,
                iconColor: AppTheme.accentTeal,
              ),
              const SizedBox(height: 10),
              _buildVectorCard(
                title: "Whaling & Baiting",
                description: "Targeting high-profile individuals with executive spoofing and false offers.",
                icon: Icons.person_search_rounded,
                iconColor: AppTheme.accentPink,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVectorCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
