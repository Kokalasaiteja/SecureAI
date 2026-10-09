import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/app_drawer.dart';

class IntroductionScreen extends StatelessWidget {
  const IntroductionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/introduction'),
      appBar: AppBar(title: const Text("Introduction to SecureAI")),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              GlassCard(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "AI-Powered Social Engineering Defense",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "SecureAI is a multi-modal security framework designed to counter modern cyber threats including phishing, vishing, smishing, quishing, and whaling attacks.\n\nOur platform integrates XGBoost, Random Forest classifiers, and AI Sentry LLMs to detect malicious patterns, analyze URLs, and prevent credential harvesting in real-time.",
                      style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  void _submit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Thank you! Your message has been sent to SecureAI support.")),
    );
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/contact'),
      appBar: AppBar(title: const Text("Contact Support")),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Get in Touch",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Have questions or need assistance with SecureAI?",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  CustomTextField(
                    controller: _nameController,
                    label: "Name",
                    hint: "Your name",
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: _emailController,
                    label: "Email",
                    hint: "your.email@example.com",
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: _messageController,
                    label: "Message",
                    hint: "Type your message or inquiry...",
                    icon: Icons.chat_bubble_outline_rounded,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryIndigo,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("Send Message", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
