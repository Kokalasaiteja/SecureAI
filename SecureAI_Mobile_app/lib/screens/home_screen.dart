import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/constellation_background.dart';
import '../widgets/app_drawer.dart';
import '../widgets/secure_ai_app_bar.dart';
import '../services/api_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userName = ApiService.currentUser ?? "User";
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final amPm = now.hour >= 12 ? 'PM' : 'AM';
    final formattedTime =
        "${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} $amPm";

    final initials = userName.length >= 2
        ? userName.substring(0, 2).toUpperCase()
        : userName.toUpperCase();

    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/home'),
      appBar: SecureAIAppBar.user(title: "SecureAI Panel"),
      body: ConstellationBackground(
        gradientColors: const [
          Color(0xFF6366F1), // from-indigo-500
          Color(0xFFA855F7), // via-purple-500
          Color(0xFFEC4899), // to-pink-500
        ],
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
                  child: Column(
                    children: [
                      // Welcome title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.accentTeal, size: 28),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              "Welcome, $userName!",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // User Avatar (Uploaded image with fallback to initials)
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF2DD4BF), width: 4), // border-teal-400
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: FutureBuilder<String?>(
                            future: ApiService.getCurrentUserImageUrl(),
                            builder: (context, snapshot) {
                              return _buildUserAvatar(userName, snapshot.data, initials);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Login time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.access_time_rounded, color: AppTheme.accentTeal, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "Login time: $formattedTime",
                            style: const TextStyle(fontSize: 13, color: Color(0xFFD1D5DB)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Subtitle
                      const Text(
                        "Explore SecureAI’s intelligent tools to combat social engineering and cyber threats.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFD1D5DB),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 6 Tools Grid matching web order and colors
                      _buildToolButton(
                        context,
                        title: "SMS Spam Detection",
                        icon: Icons.chat_bubble_rounded,
                        color: const Color(0xFF16A34A), // Green 600
                        route: '/detect_spam',
                      ),
                      const SizedBox(height: 12),
                      _buildToolButton(
                        context,
                        title: "QR Code Scanner",
                        icon: Icons.qr_code_2_rounded,
                        color: const Color(0xFF9333EA), // Purple 600
                        route: '/qr_scanner',
                      ),
                      const SizedBox(height: 12),
                      _buildToolButton(
                        context,
                        title: "Behavior Analysis",
                        icon: Icons.security_rounded,
                        color: const Color(0xFF4F46E5), // Indigo 600
                        route: '/anomaly_prediction',
                      ),
                      const SizedBox(height: 12),
                      _buildToolButton(
                        context,
                        title: "Train ML Models",
                        icon: Icons.psychology_rounded,
                        color: const Color(0xFFDB2777), // Pink 600
                        route: '/train_models',
                      ),
                      const SizedBox(height: 12),
                      _buildToolButton(
                        context,
                        title: "Password Analyzer",
                        icon: Icons.shield_rounded,
                        color: const Color(0xFFCA8A04), // Yellow 600
                        route: '/password_analyzer',
                      ),
                      const SizedBox(height: 12),
                      _buildToolButton(
                        context,
                        title: "Email Phishing",
                        icon: Icons.mark_email_read_rounded,
                        color: const Color(0xFF2563EB), // Blue 600
                        route: '/email_phishing',
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

  Widget _buildToolButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pushNamed(context, route),
        icon: Icon(icon, color: Colors.white, size: 22),
        label: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 4,
          shadowColor: color.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  static Widget _buildUserAvatar(String userName, String? imgUrl, String initials) {
    if (imgUrl != null && imgUrl.isNotEmpty) {
      return Image.network(
        imgUrl,
        width: 104,
        height: 104,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildLocalOrUiAvatar(userName, initials),
      );
    }
    return _buildLocalOrUiAvatar(userName, initials);
  }

  static Widget _buildLocalOrUiAvatar(String userName, String initials) {
    final lowerName = userName.toLowerCase();
    final bool isKokalaUser = lowerName.contains('kokala') || lowerName.contains('manikanta') || lowerName.contains('sai');

    if (isKokalaUser) {
      return Image.asset(
        'assets/images/user_avatar.jpg',
        width: 104,
        height: 104,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildUiAvatar(userName, initials),
      );
    }
    return _buildUiAvatar(userName, initials);
  }

  static Widget _buildUiAvatar(String userName, String initials) {
    final avatarUrl = ApiService.getAvatarFallbackUrl(userName, background: '0D9488', size: 256);
    return Image.network(
      avatarUrl,
      width: 104,
      height: 104,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(initials),
    );
  }

  static Widget _buildFallbackAvatar(String initials) {
    return Container(
      color: const Color(0xFF0D9488),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

}
