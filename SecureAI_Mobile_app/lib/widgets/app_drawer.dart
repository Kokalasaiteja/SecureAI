import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;
  final bool? forcePublicMode;

  const AppDrawer({
    super.key,
    required this.currentRoute,
    this.forcePublicMode,
  });

  bool get isPublicMode {
    if (forcePublicMode != null) return forcePublicMode!;
    const publicRoutes = [
      '/',
      '/public_home',
      '/user_login',
      '/register',
      '/admin_login',
      '/forgot_password',
      '/verify_otp',
      '/reset_password',
      '/introduction',
      '/contact',
    ];
    return publicRoutes.contains(currentRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xC80F172A), // Translucent smoked liquid glass
                border: Border(
                  right: BorderSide(
                    color: Colors.white.withValues(alpha: 0.20),
                    width: 1.0,
                  ),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: isPublicMode ? _buildPublicDrawer(context) : _buildUserDrawer(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. PUBLIC / LOGGED-OUT DRAWER MODE (Matches Image 2 - base.html) ---
  Widget _buildPublicDrawer(BuildContext context) {
    return Column(
      children: [
        // Drawer Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryIndigo.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryIndigo.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.shield_rounded, color: AppTheme.accentPurple, size: 22),
              ),
              const SizedBox(width: 12),
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
                      "Navigation Menu",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        // Nav Items List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            children: [
              _buildPublicItem(
                context,
                icon: Icons.home_rounded,
                title: "Home",
                subtitle: "Main portal & Overview",
                iconColor: AppTheme.primaryIndigo,
                route: "/public_home",
              ),
              _buildPublicItem(
                context,
                icon: Icons.menu_book_rounded,
                title: "Introduction",
                subtitle: "Social Engineering & AI",
                iconColor: AppTheme.accentTeal,
                route: "/introduction",
              ),
              _buildPublicItem(
                context,
                icon: Icons.email_rounded,
                title: "Contact Us",
                subtitle: "Support & Feedback",
                iconColor: Colors.blueAccent,
                route: "/contact",
              ),
              _buildPublicItem(
                context,
                icon: Icons.person_add_rounded,
                title: "Register",
                subtitle: "Create new account",
                iconColor: AppTheme.accentPurple,
                route: "/register",
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              const SizedBox(height: 12),

              // User Login Pill Button
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  if (currentRoute != '/user_login') {
                    Navigator.pushReplacementNamed(context, '/user_login');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Row(
                        children: [
                          Icon(Icons.login_rounded, color: Color(0xFF86EFAC), size: 20),
                          SizedBox(width: 12),
                          Text(
                            "User Login",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Admin Portal Bordered Button
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  if (currentRoute != '/admin_login') {
                    Navigator.pushReplacementNamed(context, '/admin_login');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEC4899).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Row(
                        children: [
                          Icon(Icons.lock_rounded, color: Color(0xFFF472B6), size: 20),
                          SizedBox(width: 12),
                          Text(
                            "Admin Portal",
                            style: TextStyle(
                              color: Color(0xFFF472B6),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Icon(Icons.shield_outlined, color: Color(0xFFF472B6), size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Download Android App Button (below Admin Portal)
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  final uri = Uri.parse("http://127.0.0.1:8000/media/app-arm64-v8a-release.apk");
                  final fallbackUri = Uri.parse("https://secureai-7wgj.onrender.com/media/app-arm64-v8a-release.apk");
                  try {
                    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
                    }
                  } catch (_) {
                    try {
                      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
                    } catch (_) {}
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF2DD4BF).withValues(alpha: 0.45)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.android_rounded, color: Color(0xFF2DD4BF), size: 20),
                          SizedBox(width: 12),
                          Text(
                            "Download Android App",
                            style: TextStyle(
                              color: Color(0xFF2DD4BF),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.download_rounded, color: Color(0xFF2DD4BF), size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Public Footer
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "© 2026 SecureAI",
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  // --- 2. LOGGED-IN USER PANEL DRAWER MODE (Matches Image 1 - user_base.html / SecureAI Panel) ---
  Widget _buildUserDrawer(BuildContext context) {
    return Column(
      children: [
        // Drawer Header (SecureAI Panel)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.accentTeal, size: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "SecureAI Panel",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        // Logged In Items List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            children: [
              _buildUserItem(
                context,
                icon: Icons.home_rounded,
                title: "Home",
                iconColor: AppTheme.accentTeal,
                route: "/home",
              ),
              _buildUserItem(
                context,
                icon: Icons.chat_bubble_rounded,
                title: "SMS Spam Detection",
                iconColor: AppTheme.accentGreen,
                route: "/detect_spam",
              ),
              _buildUserItem(
                context,
                icon: Icons.qr_code_2_rounded,
                title: "QR Code Scanner",
                iconColor: AppTheme.accentPurple,
                route: "/qr_scanner",
              ),
              _buildUserItem(
                context,
                icon: Icons.account_balance_rounded,
                title: "Behavior Analysis",
                iconColor: AppTheme.primaryIndigo,
                route: "/anomaly_prediction",
              ),
              _buildUserItem(
                context,
                icon: Icons.shield_rounded,
                title: "Password Analyzer",
                iconColor: Colors.amber,
                route: "/password_analyzer",
              ),
              _buildUserItem(
                context,
                icon: Icons.mark_email_read_rounded,
                title: "Email Phishing",
                iconColor: Colors.blueAccent,
                route: "/email_phishing",
              ),
              _buildUserItem(
                context,
                icon: Icons.psychology_rounded,
                title: "Train ML Models",
                iconColor: AppTheme.accentPink,
                route: "/train_models",
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white12),
              const SizedBox(height: 8),

              // Logout Button Container Box (Matching Image 1)
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.accentRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accentRed.withValues(alpha: 0.25)),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.logout_rounded, color: AppTheme.accentRed, size: 22),
                  title: const Text(
                    "Logout",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentRed,
                    ),
                  ),
                  onTap: () async {
                    await ApiService.logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, '/user_login', (r) => false);
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Delete Account Button Container Box
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.person_remove_rounded, color: Colors.redAccent, size: 20),
                  title: const Text(
                    "Delete Account",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                  onTap: () {
                    _showDeleteAccountDialog(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text("Delete Account", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Are you sure? This will permanently delete your account, profile picture, and all associated security data.",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter password to confirm",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final password = passwordController.text.trim();
              if (password.isEmpty) return;
              Navigator.pop(ctx);
              final result = await ApiService.deleteAccount(password);
              if (result['success'] == true) {
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/user_login', (r) => false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['message'] ?? 'Account deleted.')),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Failed to delete account.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Permanently Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Helper Widget for Public Drawer Nav Items with Active Route Highlighting
  Widget _buildPublicItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required String route,
  }) {
    final bool isSelected = currentRoute == route || (route == '/public_home' && currentRoute == '/');

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF4F46E5).withValues(alpha: 0.32) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF818CF8).withValues(alpha: 0.7) : Colors.transparent,
          width: 1.2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: isSelected ? 0.35 : 0.2),
            borderRadius: BorderRadius.circular(10),
            border: isSelected ? Border.all(color: iconColor.withValues(alpha: 0.6)) : null,
          ),
          child: Icon(icon, color: isSelected ? Colors.white : iconColor, size: 20),
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
          style: TextStyle(
            fontSize: 11,
            color: isSelected ? const Color(0xFFC7D2FE) : Colors.grey,
          ),
        ),
        trailing: isSelected
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF818CF8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF818CF8),
                      blurRadius: 6,
                      spreadRadius: 1,
                    )
                  ],
                ),
              )
            : null,
        onTap: () {
          Navigator.pop(context);
          if (!isSelected) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
    );
  }

  // Helper Widget for User Panel Nav Items with Active Route Highlighting
  Widget _buildUserItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color iconColor,
    required String route,
  }) {
    final bool isSelected = currentRoute == route;

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF0D9488).withValues(alpha: 0.30) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF2DD4BF).withValues(alpha: 0.7) : Colors.transparent,
          width: 1.2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF2DD4BF).withValues(alpha: 0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: isSelected ? 0.35 : 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: isSelected ? Colors.white : iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
        trailing: isSelected
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF2DD4BF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF2DD4BF),
                      blurRadius: 6,
                      spreadRadius: 1,
                    )
                  ],
                ),
              )
            : null,
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
