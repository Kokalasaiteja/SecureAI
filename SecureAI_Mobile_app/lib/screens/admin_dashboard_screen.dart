import 'dart:ui';
import '../widgets/copyright_footer.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/constellation_background.dart';
import '../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await ApiService.getAdminUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load users: $e";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleToggleStatus(Map<String, dynamic> user) async {
    final int id = user['id'] ?? 0;
    final bool currentStatus = user['is_active'] ?? false;
    final bool activate = !currentStatus;
    final String actionText = activate ? "activate" : "deactivate";

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        title: Text("Confirm $actionText", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to $actionText user ${user['name']}?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: activate ? AppTheme.accentGreen : Colors.amber.shade700,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(activate ? "Activate" : "Deactivate", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ApiService.toggleUserStatus(id, activate);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("User ${user['name']} has been ${activate ? 'activated' : 'deactivated'} successfully."),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
        _loadUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update status for ${user['name']}."),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _handleEditUser(Map<String, dynamic> user) async {
    final int id = user['id'] ?? 0;
    final nameCtrl = TextEditingController(text: user['name']?.toString() ?? '');
    final emailCtrl = TextEditingController(text: user['email']?.toString() ?? '');
    final mobileCtrl = TextEditingController(text: user['mobile']?.toString() ?? '');
    final passCtrl = TextEditingController();
    bool isActive = user['is_active'] == true;
    final String currentImageUrl = user['image_url']?.toString() ?? '';
    XFile? pickedImageFile;
    Uint8List? pickedImageBytes;
    final picker = ImagePicker();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1B4B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: Color(0xFF818CF8)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Edit User",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF818CF8), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: pickedImageBytes != null
                              ? Image.memory(pickedImageBytes!, width: 76, height: 76, fit: BoxFit.cover)
                              : _buildUserAvatar(nameCtrl.text.isNotEmpty ? nameCtrl.text : 'User', currentImageUrl),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Material(
                          color: const Color(0xFF4F46E5),
                          shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 1.5)),
                          child: InkWell(
                            onTap: () async {
                              try {
                                final picked = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 85,
                                );
                                if (picked != null) {
                                  final bytes = await picked.readAsBytes();
                                  setDialogState(() {
                                    pickedImageFile = picked;
                                    pickedImageBytes = bytes;
                                  });
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error picking image: $e')),
                                  );
                                }
                              }
                            },
                            customBorder: const CircleBorder(),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      try {
                        final picked = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 85,
                        );
                        if (picked != null) {
                          final bytes = await picked.readAsBytes();
                          setDialogState(() {
                            pickedImageFile = picked;
                            pickedImageBytes = bytes;
                          });
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error picking image: $e')),
                          );
                        }
                      }
                    },
                    child: Text(
                      pickedImageFile != null ? 'Photo selected (${pickedImageFile!.name})' : 'Tap camera icon to change DP',
                      style: TextStyle(
                        color: pickedImageFile != null ? const Color(0xFF34D399) : const Color(0xFF818CF8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: "Username",
                    labelStyle: TextStyle(color: Color(0xFF9CA3AF)),
                    prefixIcon: Icon(Icons.person_outline_rounded, color: Color(0xFF818CF8), size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email Address",
                    labelStyle: TextStyle(color: Color(0xFF9CA3AF)),
                    prefixIcon: Icon(Icons.mail_outline_rounded, color: Color(0xFF818CF8), size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mobileCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Mobile",
                    labelStyle: TextStyle(color: Color(0xFF9CA3AF)),
                    prefixIcon: Icon(Icons.phone_outlined, color: Color(0xFF818CF8), size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Reset Password (Optional)",
                    hintText: "Leave blank to keep existing",
                    labelStyle: TextStyle(color: Color(0xFF9CA3AF)),
                    hintStyle: TextStyle(color: Colors.white30, fontSize: 11),
                    prefixIcon: Icon(Icons.lock_outline_rounded, color: Color(0xFF818CF8), size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Account Active", style: TextStyle(color: Colors.white, fontSize: 14)),
                  value: isActive,
                  activeThumbColor: AppTheme.accentGreen,
                  onChanged: (val) {
                    setDialogState(() {
                      isActive = val;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel", style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    final String newName = nameCtrl.text.trim();
    final String newEmail = emailCtrl.text.trim();
    final String newMobile = mobileCtrl.text.trim();
    final String newPass = passCtrl.text.trim();

    if (newName.isEmpty || newEmail.isEmpty || newMobile.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Name, email, and mobile are required."), backgroundColor: AppTheme.accentRed),
        );
      }
      return;
    }

    final res = await ApiService.editUser(
      id: id,
      name: newName,
      email: newEmail,
      mobile: newMobile,
      isActive: isActive,
      password: newPass.isNotEmpty ? newPass : null,
      imagePath: pickedImageFile?.path,
      imageBytes: pickedImageBytes,
      imageName: pickedImageFile?.name,
    );

    if (mounted) {
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? "User updated successfully."), backgroundColor: AppTheme.accentGreen),
        );
        _loadUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? "Failed to update user."), backgroundColor: AppTheme.accentRed),
        );
      }
    }
  }

  Future<void> _handleDeleteUser(Map<String, dynamic> user) async {
    final int id = user['id'] ?? 0;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        title: const Text("Delete User", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to permanently delete user ${user['name']}?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ApiService.deleteUser(id);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("User ${user['name']} deleted."),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
        _loadUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete user ${user['name']}."),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              backgroundColor: const Color(0xB80F172A), // Translucent smoked liquid glass
              elevation: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.16),
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                tooltip: "Back to Admin Home",
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, '/admin_home');
                  }
                },
              ),
              titleSpacing: 0,
              title: const Text(
                "Admin Dashboard",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppTheme.accentTeal),
                  tooltip: "Refresh users",
                  onPressed: _loadUsers,
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.5)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.logout_rounded, color: Color(0xFFFCA5A5), size: 16),
                        SizedBox(width: 4),
                        Text("Logout", style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  onPressed: () async {
                    await ApiService.logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                    }
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: ConstellationBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadUsers,
            color: AppTheme.accentTeal,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              children: [
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.accentTeal, size: 24),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "User Account Management",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentTeal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.accentTeal.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          "${_users.length} Users",
                          style: const TextStyle(
                            color: AppTheme.accentTeal,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(color: AppTheme.accentTeal),
                    ),
                  )
                else if (_errorMessage != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppTheme.accentRed, fontSize: 14),
                      ),
                    ),
                  )
                else if (_users.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        "No users registered yet.",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  )
                else
                  ..._users.map((u) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildUserCard(u),
                      )),

                const SizedBox(height: 16),
                const CopyrightFooter(),
              ],
            )
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(String name, String imageUrl) {
    if (imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('data:image') || imageUrl.contains(';base64,')) {
        try {
          final base64Data = imageUrl.contains(',') ? imageUrl.split(',').last : imageUrl;
          final Uint8List bytes = base64Decode(base64Data);
          return Image.memory(
            bytes,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildUiAvatar(name),
          );
        } catch (_) {}
      } else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        return Image.network(
          imageUrl,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildUiAvatar(name),
        );
      } else if (imageUrl.length > 100 && !imageUrl.contains(' ')) {
        try {
          final Uint8List bytes = base64Decode(imageUrl);
          return Image.memory(
            bytes,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildUiAvatar(name),
          );
        } catch (_) {}
      }
    }
    return _buildUiAvatar(name);
  }

  Widget _buildUiAvatar(String name) {
    final avatarUrl = ApiService.getAvatarFallbackUrl(name, background: '6366F1', size: 128);
    return Image.network(
      avatarUrl,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(name),
    );
  }

  Widget _buildFallbackAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Container(
      color: const Color(0xFF1F2937),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFF818CF8),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final String name = user['name'] ?? 'User';
    final String email = user['email'] ?? '';
    final String mobile = user['mobile'] ?? '';
    final bool isActive = user['is_active'] ?? false;
    final String imageUrl = user['image_url']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2937), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (isActive ? AppTheme.accentTeal : const Color(0xFF6B7280)).withValues(alpha: 0.6),
                            width: 1.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _buildUserAvatar(name, imageUrl),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isActive ? AppTheme.accentGreen : AppTheme.accentRed).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (isActive ? AppTheme.accentGreen : AppTheme.accentRed).withValues(alpha: 0.5),
                    ),
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
            const SizedBox(height: 12),
            if (email.isNotEmpty)
              Text("Email: $email", style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
            if (mobile.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text("Mobile: $mobile", style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _handleEditUser(user),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF818CF8),
                    side: const BorderSide(color: Color(0xFF6366F1)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.edit_rounded, size: 15),
                  label: const Text("Edit", style: TextStyle(fontSize: 12)),
                ),
                OutlinedButton.icon(
                  onPressed: () => _handleToggleStatus(user),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isActive ? Colors.amber : AppTheme.accentGreen,
                    side: BorderSide(color: isActive ? Colors.amber : AppTheme.accentGreen),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: Icon(isActive ? Icons.block_rounded : Icons.check_circle_rounded, size: 15),
                  label: Text(isActive ? "Deactivate" : "Activate", style: const TextStyle(fontSize: 12)),
                ),
                OutlinedButton.icon(
                  onPressed: () => _handleDeleteUser(user),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentRed,
                    side: const BorderSide(color: AppTheme.accentRed),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.delete_forever_rounded, size: 15),
                  label: const Text("Delete", style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
