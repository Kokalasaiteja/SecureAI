import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import '../widgets/constellation_background.dart';
import '../widgets/app_drawer.dart';
import '../widgets/secure_ai_app_bar.dart';

class PublicHomeScreen extends StatelessWidget {
  const PublicHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/public_home', forcePublicMode: true),
      appBar: SecureAIAppBar.public(title: "SecureAI"),
      body: ConstellationBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Hero Section
                const SizedBox(height: 10),
                const Text(
                  "Welcome to SecureAI",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Harnessing AI to Prevent Social Engineering Attacks",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFFD1D5DB),
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),


                // 2. About SecureAI Section
                GlassCard(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.shield_rounded, color: Color(0xFF818CF8), size: 26),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "About SecureAI",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "SecureAI is dedicated to leveraging Artificial Intelligence to counter social engineering attacks. Our platform addresses both traditional and AI-enabled threats, including phishing, vishing, smishing, and whaling, using advanced AI-based defense mechanisms like AI Sentry to protect users and organizations.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFD1D5DB),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 3. Social Engineering Attacks Section (4 Cards)
                _buildAttackCard(
                  icon: Icons.phishing_rounded,
                  iconColor: const Color(0xFFC084FC), // Purple 400
                  title: "Phishing & Vishing",
                  description:
                      "Phishing and vishing attacks use deceptive emails and voice calls to steal sensitive information. Our AI-powered detection systems identify and block these malicious attempts in real-time.",
                ),
                const SizedBox(height: 14),
                _buildAttackCard(
                  icon: Icons.phone_android_rounded,
                  iconColor: const Color(0xFF818CF8), // Indigo 400
                  title: "Smishing & Quishing",
                  description:
                      "Smishing and quishing exploit SMS and QR codes to deceive users. SecureAI’s solutions analyze patterns and flag suspicious messages to protect against these modern threats.",
                ),
                const SizedBox(height: 14),
                _buildAttackCard(
                  icon: Icons.business_center_rounded,
                  iconColor: const Color(0xFFC084FC), // Purple 400
                  title: "Whaling & Baiting",
                  description:
                      "Whaling targets high-profile individuals, while baiting lures users with false promises. Our AI Sentry technology uses behavioral analysis to detect and prevent these sophisticated attacks.",
                ),
                const SizedBox(height: 14),
                _buildAttackCard(
                  icon: Icons.handshake_rounded,
                  iconColor: const Color(0xFF818CF8), // Indigo 400
                  title: "Quid Pro Quo",
                  description:
                      "Quid Pro Quo attacks offer benefits in exchange for information. SecureAI uses machine learning to identify deceptive tactics and provide real-time alerts to users.",
                ),
                const SizedBox(height: 28),

                // 4. Call to Action Section
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
                  child: Column(
                    children: const [
                      Text(
                        "Join the Fight Against Social Engineering",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Protecting users and organizations with AI-powered defense mechanisms against modern cyber threats.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFFD1D5DB),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttackCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFFD1D5DB),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
