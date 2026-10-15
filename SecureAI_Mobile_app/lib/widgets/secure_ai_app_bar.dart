import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ChatGPTMenuIcon extends StatelessWidget {
  final Color color;
  const ChatGPTMenuIcon({super.key, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 19,
          height: 2.2,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 4.5),
        Container(
          width: 13,
          height: 2.2,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 4.5),
        Container(
          width: 17,
          height: 2.2,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class SecureAIAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isUserPanel;
  final List<Widget>? actions;
  final bool showBackButton;

  const SecureAIAppBar({
    super.key,
    required this.title,
    this.isUserPanel = false,
    this.actions,
    this.showBackButton = false,
  });

  factory SecureAIAppBar.public({
    String title = "SecureAI",
    List<Widget>? actions,
    bool showBackButton = false,
  }) {
    return SecureAIAppBar(
      title: title,
      isUserPanel: false,
      actions: actions,
      showBackButton: showBackButton,
    );
  }

  factory SecureAIAppBar.user({
    String title = "SecureAI Panel",
    List<Widget>? actions,
    bool showBackButton = false,
  }) {
    return SecureAIAppBar(
      title: title,
      isUserPanel: true,
      actions: actions,
      showBackButton: showBackButton,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final themeColor = isUserPanel ? AppTheme.accentTeal : AppTheme.primaryIndigo;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: preferredSize.height + MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: 12,
            right: 12,
          ),
          decoration: BoxDecoration(
            color: const Color(0xB80F172A), // Translucent smoked liquid glass
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.16),
                width: 1.0,
              ),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              // Left button: Liquid Glass droplet Back or Menu button
              if (showBackButton)
                IconButton(
                  icon: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                )
              else
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0x661F2937),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.menu_rounded,
                      color: isUserPanel ? AppTheme.accentTeal : const Color(0xFF818CF8),
                      size: 22,
                    ),
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),

              const SizedBox(width: 12),

              // Brand Icon matching website (with liquid glass sheen)
              if (isUserPanel)
                const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AppTheme.accentTeal,
                  size: 24,
                )
              else
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: themeColor.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.shield_rounded,
                    color: themeColor,
                    size: 20,
                  ),
                ),

              const SizedBox(width: 8),

              // Brand Name / Title (1:1 with website mobile view)
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                      color: isUserPanel ? Colors.white : const Color(0xFF818CF8),
                    ),
                  ),
                ),
              ),

              // Actions
              ...?actions,
            ],
          ),
        ),
      ),
    );
  }
}
