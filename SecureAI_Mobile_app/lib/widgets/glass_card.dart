import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Color? borderColor;
  final VoidCallback? onTap;
  final bool enablePressEffect;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 20,
    this.borderColor,
    this.onTap,
    this.enablePressEffect = false,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = widget.borderColor ?? AppTheme.primaryIndigo;

    Widget cardContent = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        // Liquid Glass: Ambient colored glow + deep elevation shadow
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: _isPressed ? 14 : 26,
            offset: Offset(0, _isPressed ? 4 : 12),
          ),
          BoxShadow(
            color: effectiveBorderColor.withValues(alpha: 0.09),
            blurRadius: 32,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              // Retains exact original dark glass background
              color: AppTheme.cardGlassBg,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              // Fresnel Specular Edge: Light strikes top-left and fades at bottom-right
              border: Border.all(
                color: widget.borderColor ?? Colors.white.withValues(alpha: 0.22),
                width: 1.2,
              ),
              // Liquid Caustic Light Sheen across top curvature
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.12), // Specular light hit
                  Colors.white.withValues(alpha: 0.03),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.18), // Bottom refraction depth
                ],
                stops: const [0.0, 0.25, 0.65, 1.0],
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.onTap != null || widget.enablePressEffect) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

