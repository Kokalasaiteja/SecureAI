import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;
  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xF00F172A),
          border: Border(
            right: BorderSide(color: Colors.white.withOpacity(0.15)),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset('assets/images/app_icon.png', fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "SecureAI",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "AI Security Framework",
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Drawer Nav Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  children: [
                    _buildNavItem(
                      context,
                      icon: Icons.home_rounded,
                      title: "Home",
                      subtitle: "Dashboard & Metrics",
                      iconColor: AppTheme.primaryIndigo,
                      route: "/home",
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.sms_rounded,
                      title: "SMS Spam Detection",
                      subtitle: "Check suspicious texts",
                      iconColor: AppTheme.accentGreen,
                      route: "/detect_spam",
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.qr_code_scanner_rounded,
                      title: "QR Code Scanner",
                      subtitle: "Scan & verify QR URLs",
                      iconColor: AppTheme.accentPurple,
                      route: "/qr_scanner",
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.security_rounded,
                      title: "Behavior Analysis",
                      subtitle: "Login anomaly detection",
                      iconColor: AppTheme.primaryIndigo,
                      route: "/anomaly_prediction",
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.shield_rounded,
                      title: "Password Analyzer",
                      subtitle: "Check strength & breaches",
                      iconColor: Colors.amber,
                      route: "/password_analyzer",
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.mark_email_read_rounded,
                      title: "Email Phishing",
                      subtitle: "Analyze email content",
                      iconColor: Colors.blueAccent,
                      route: "/email_phishing",
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.psychology_rounded,
                      title: "Train ML Models",
                      subtitle: "Retrain AI Sentry models",
                      iconColor: AppTheme.accentPink,
                      route: "/train_models",
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: Colors.white12),
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.menu_book_rounded,
                      title: "Introduction",
                      subtitle: "Social Engineering & AI",
                      iconColor: AppTheme.accentTeal,
                      route: "/introduction",
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.support_agent_rounded,
                      title: "Contact Us",
                      subtitle: "Support & Feedback",
                      iconColor: Colors.lightBlue,
                      route: "/contact",
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.admin_panel_settings_rounded,
                      title: "Admin Portal",
                      subtitle: "User management dashboard",
                      iconColor: AppTheme.accentPink,
                      route: "/admin_dashboard",
                    ),
                  ],
                ),
              ),

              // Footer Logout Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: InkWell(
                  onTap: () async {
                    await ApiService.logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, '/user_login', (r) => false);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentRed.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accentRed.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.logout_rounded, color: AppTheme.accentRed, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Logout",
                          style: TextStyle(
                            color: AppTheme.accentRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required String route,
  }) {
    final bool isSelected = currentRoute == route;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isSelected ? AppTheme.primaryIndigo.withOpacity(0.25) : Colors.transparent,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        onTap: () {
          Navigator.pop(context);
          if (!isSelected) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
    );
  }
}
