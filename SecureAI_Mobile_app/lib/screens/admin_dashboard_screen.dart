import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/app_drawer.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/admin_dashboard'),
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
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
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: const [
                    Icon(Icons.admin_panel_settings_rounded, color: AppTheme.accentPink, size: 28),
                    SizedBox(width: 12),
                    Text(
                      "User Account Management",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildUserCard(
                name: "testuser",
                email: "test@example.com",
                mobile: "9876543210",
                isActive: true,
              ),
              const SizedBox(height: 12),
              _buildUserCard(
                name: "testuser3748",
                email: "testuser3748@example.com",
                mobile: "9876543210",
                isActive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard({
    required String name,
    required String email,
    required String mobile,
    required bool isActive,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isActive ? AppTheme.accentGreen : AppTheme.accentRed).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (isActive ? AppTheme.accentGreen : AppTheme.accentRed).withOpacity(0.4)),
                ),
                child: Text(
                  isActive ? "Active" : "Inactive",
                  style: TextStyle(
                    color: isActive ? AppTheme.accentGreen : AppTheme.accentRed,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text("Email: $email", style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text("Mobile: $mobile", style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: Icon(isActive ? Icons.block_rounded : Icons.check_circle_rounded, size: 16, color: Colors.amber),
                label: Text(isActive ? "Deactivate" : "Activate", style: const TextStyle(color: Colors.amber, fontSize: 12)),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.delete_forever_rounded, size: 16, color: AppTheme.accentRed),
                label: const Text("Delete", style: TextStyle(color: AppTheme.accentRed, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
