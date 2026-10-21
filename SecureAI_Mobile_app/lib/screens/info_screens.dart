import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/glass_card.dart';
import '../widgets/constellation_background.dart';
import '../widgets/app_drawer.dart';
import '../widgets/secure_ai_app_bar.dart';

class IntroductionScreen extends StatelessWidget {
  const IntroductionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/introduction'),
      appBar: SecureAIAppBar.public(title: "SecureAI"),
      body: ConstellationBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
                    borderRadius: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.shield_rounded, color: Color(0xFF6366F1), size: 28),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Welcome to SecureAI",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        const Text(
                          "The Usage of AI in prevention of Social Engineering Attacks project is an advanced, comprehensive cybersecurity platform designed to identify, analyze, and thwart various forms of human-targeted cyber threats. By leveraging cutting-edge Artificial Intelligence and Machine Learning techniques, this system proactively defends against psychological manipulation tactics.",
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFFD1D5DB),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "In today's digital landscape, social engineering attacks such as phishing, smishing, and quishing exploit human vulnerability rather than technical flaws. Our project provides a multi-layered defense mechanism with real-time AI analysis.",
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFFD1D5DB),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Feature 1: SMS Spam Detector
                        _buildFeatureCard(
                          icon: Icons.sms_rounded,
                          title: "1. SMS Spam Detector",
                          accentColor: const Color(0xFF2DD4BF), // Teal
                          logic: "NLP tokenization and contextual sequence analysis.",
                          model: "Google Gemini 3.5 Flash AI model.",
                          trainingData: "Pre-trained on vast datasets of global SMS communications, both legitimate and spam.",
                          functionality: "Real-time classification of SMS messages to determine if they are malicious phishing attempts or safe ('ham').",
                          examples: [
                            _ExampleItem(
                              isNegative: true,
                              label: "Example (Spam):",
                              content: '"Congratulations! You won a free gift. Click to claim now"',
                            ),
                            _ExampleItem(
                              isNegative: false,
                              label: "Example (Ham):",
                              content: '"Hi! Are we still meeting for dinner tonight?"',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Feature 2: QR Code Threat Scanner
                        _buildFeatureCard(
                          icon: Icons.qr_code_2_rounded,
                          title: "2. QR Code Threat Scanner",
                          accentColor: const Color(0xFFA855F7), // Purple
                          logic: "Image processing to decode QR matrices followed by rigorous URL threat extraction and analysis.",
                          model: "OpenCV for QR decoding; LangChain combined with Google Gemini 3.5 Flash.",
                          trainingData: "Analyzes patterns derived from known phishing URLs, safe domain registries, and malicious link structures.",
                          functionality: "Scans QR codes and classifies the hidden URL as Safe, Phishing, or Malicious.",
                          examples: [
                            _ExampleItem(
                              isNegative: false,
                              label: "Example (Safe):",
                              content: "A restaurant's digital menu URL.",
                            ),
                            _ExampleItem(
                              isNegative: true,
                              label: "Example (Phishing):",
                              content: "A QR code routing to a deceptive banking login page.",
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Feature 3: Email Phishing Analyzer
                        _buildFeatureCard(
                          icon: Icons.mark_email_read_rounded,
                          title: "3. Email Phishing Analyzer",
                          accentColor: const Color(0xFF3B82F6), // Blue
                          logic: "Textual analysis focusing on psychological triggers like urgency, authority, and deceptive phrasing.",
                          model: "Google Gemini 3.5 Flash.",
                          trainingData: "Generalized knowledge base encompassing historical phishing templates and standard corporate/personal communications.",
                          functionality: "Evaluates email contents and returns a strict classification (Safe, Suspicious, Phishing) along with bulleted explanations.",
                          examples: [
                            _ExampleItem(
                              isNegative: true,
                              label: "Example (Phishing):",
                              content: '"Dear customer, your account will be locked in 24 hours. Click here to verify."',
                            ),
                            _ExampleItem(
                              isWarning: true,
                              label: "Example (Suspicious):",
                              content: '"Hi team, please find attached the meeting notes from yesterday\'s sync."',
                            ),
                            _ExampleItem(
                              isNegative: false,
                              label: "Example (Safe):",
                              content: '"Hi John, could we reschedule our 1-on-1 meeting to tomorrow at 2 PM?"',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Feature 4: Password Strength & Breach Analyzer
                        _buildFeatureCard(
                          icon: Icons.shield_rounded,
                          title: "4. Password Strength & Breach Analyzer",
                          accentColor: const Color(0xFFF59E0B), // Yellow/Amber
                          logic: "Combines heuristic complexity checking with secure, zero-knowledge breach verification.",
                          model: "SHA-1 hashing algorithm for k-Anonymity (prefix matching).",
                          trainingData: "Integrates with the 'Have I Been Pwned' API database.",
                          functionality: "Evaluates password strength and checks for exposure in known data breaches without ever transmitting plain text.",
                          examples: [
                            _ExampleItem(
                              isNegative: true,
                              label: "Example (Weak/Breached):",
                              content: "password123",
                            ),
                            _ExampleItem(
                              isNegative: false,
                              label: "Example (Strong/Safe):",
                              content: "Tr0ub4dor&3!Secure",
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Feature 5: User Behavior Anomaly Detection
                        _buildFeatureCard(
                          icon: Icons.psychology_rounded,
                          title: "5. User Behavior Anomaly Detection",
                          accentColor: const Color(0xFF6366F1), // Indigo
                          logic: "Statistical profiling and machine learning classification to detect atypical session parameters.",
                          model: "Logistic Regression, Random Forest, and XGBoost classifiers.",
                          trainingData: "Trained locally on behavior_anomaly_dataset.csv, learning from historical login hours and IP risk scores.",
                          functionality: "The models evaluate login_hour and ip_score. High risk IPs with abnormal hours are flagged as Anomaly.",
                          examples: [
                            _ExampleItem(
                              isNegative: false,
                              label: "Normal Behavior:",
                              content: "login_hour = 10, ip_score = 0.20",
                            ),
                            _ExampleItem(
                              isNegative: true,
                              label: "Anomaly Detected:",
                              content: "login_hour = 2, ip_score = 0.95",
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Bottom CTA matching public_home_screen.dart
                        Column(
                          children: [
                            const Text(
                              "Ready to secure your digital life?",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.28),
                                    width: 1.1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4F46E5).withValues(alpha: 0.45),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.pushNamed(context, '/register'),
                                  icon: const Icon(Icons.rocket_launch_rounded, size: 20, color: Colors.white),
                                  label: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Get Started Now",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                                    ],
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required Color accentColor,
    required String logic,
    required String model,
    required String trainingData,
    required String functionality,
    required List<_ExampleItem> examples,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111827), // bg-gray-900
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF374151), // border-gray-700
            width: 1.0,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Accent colored indicator bar
              Container(
                width: 4.5,
                color: accentColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Circular Icon (matching web)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F2937), // bg-gray-800
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(icon, color: accentColor, size: 34),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Title
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Details
                      _buildBullet("Logic", logic),
                      _buildBullet("Model", model),
                      _buildBullet("Training Data", trainingData),
                      _buildBullet("Functionality", functionality),
                      const SizedBox(height: 12),

                      // Examples Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2937), // bg-gray-800
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF374151)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: examples.map((ex) {
                            final iconData = ex.isWarning
                                ? Icons.warning_rounded
                                : (ex.isNegative ? Icons.cancel_rounded : Icons.check_circle_rounded);
                            final color = ex.isWarning
                                ? const Color(0xFFFBBF24)
                                : (ex.isNegative ? const Color(0xFFF87171) : const Color(0xFF4ADE80));

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(iconData, color: color, size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(fontSize: 12, height: 1.4),
                                        children: [
                                          TextSpan(
                                            text: "${ex.label} ",
                                            style: TextStyle(color: color, fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text: ex.content,
                                            style: const TextStyle(color: Color(0xFFE5E7EB)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBullet(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12.5, color: Color(0xFFD1D5DB), height: 1.4),
          children: [
            TextSpan(
              text: "$title: ",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            TextSpan(text: content),
          ],
        ),
      ),
    );
  }
}

class _ExampleItem {
  final bool isNegative;
  final bool isWarning;
  final String label;
  final String content;

  _ExampleItem({
    this.isNegative = false,
    this.isWarning = false,
    required this.label,
    required this.content,
  });
}

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  Future<void> _launchUri(BuildContext context, String uriString) async {
    final uri = Uri.parse(uriString);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Could not launch $uriString")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error opening $uriString: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/contact'),
      appBar: SecureAIAppBar.public(title: "SecureAI"),
      body: ConstellationBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                      borderRadius: 18,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header matching contact.html
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.contact_page_rounded,
                                color: Color(0xFF818CF8),
                                size: 26,
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Contact Us",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          const Text(
                            "Have questions or need support? Reach out to the SecureAI developer below.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFD1D5DB),
                              fontSize: 13.5,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 1. Developer Card
                          _buildContactCard(
                            icon: Icons.account_circle_rounded,
                            accentColor: const Color(0xFF2DD4BF),
                            title: "Kokala Sai Teja",
                            subtitle: "Developer",
                            isClickable: false,
                          ),
                          const SizedBox(height: 16),

                          // 2. Email Support Card (Clickable mailto:)
                          _buildContactCard(
                            icon: Icons.email_rounded,
                            accentColor: const Color(0xFF3B82F6),
                            title: "Email Support",
                            subtitle: "kokalasaiteja@gmail.com",
                            isClickable: true,
                            onTap: () => _launchUri(context, "mailto:kokalasaiteja@gmail.com"),
                          ),
                          const SizedBox(height: 16),

                          // 3. Phone Number Card (Clickable tel:)
                          _buildContactCard(
                            icon: Icons.phone_in_talk_rounded,
                            accentColor: const Color(0xFF10B981),
                            title: "Phone Number",
                            subtitle: "+91 7013120537",
                            isClickable: true,
                            onTap: () => _launchUri(context, "tel:+917013120537"),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required Color accentColor,
    required String title,
    required String subtitle,
    required bool isClickable,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.2),
          ),
          child: Column(
            children: [
              Icon(icon, color: accentColor, size: 40),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
