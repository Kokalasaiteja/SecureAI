import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class ConstellationBackground extends StatefulWidget {
  final Widget child;
  final List<Color>? gradientColors;
  final bool showFooter;

  const ConstellationBackground({
    super.key,
    required this.child,
    this.gradientColors,
    this.showFooter = false,
  });

  @override
  State<ConstellationBackground> createState() => _ConstellationBackgroundState();
}

class _ConstellationBackgroundState extends State<ConstellationBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();
  static const int _particleCount = 38;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(
        _Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          vx: (_random.nextDouble() - 0.5) * 0.0007,
          vy: (_random.nextDouble() - 0.5) * 0.0007,
          radius: 1.5 + _random.nextDouble() * 2.0,
        ),
      );
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        for (var p in _particles) {
          p.x += p.vx;
          p.y += p.vy;
          if (p.x < 0) p.x = 1.0;
          if (p.x > 1.0) p.x = 0.0;
          if (p.y < 0) p.y = 1.0;
          if (p.y > 1.0) p.y = 0.0;
        }
        setState(() {});
      })
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.gradientColors ?? const [
      Color(0xFF6366F1), // from-indigo-500
      Color(0xFFA855F7), // via-purple-500
      Color(0xFFEC4899), // to-pink-500
    ];

    return Stack(
      children: [
        // Rich animated vibrant gradient matching web's .gradient-bg
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
        ),

        // Dark tint overlay to ensure high readability and contrast
        Container(
          color: Colors.black.withValues(alpha: 0.22),
        ),

        // Constellation / Particles Canvas (Dynamic Material Layer under glass)
        Positioned.fill(
          child: CustomPaint(
            painter: _ConstellationPainter(particles: _particles),
          ),
        ),

        // Content with bottom padding so it never collides with fixed footer
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: widget.showFooter ? (44.0 + MediaQuery.of(context).padding.bottom) : 0.0,
            ),
            child: widget.child,
          ),
        ),

        // Web-Matching Fixed Bottom Footer (Liquid Glass Mode)
        if (widget.showFooter)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: EdgeInsets.only(
                    top: 10,
                    bottom: 10 + MediaQuery.of(context).padding.bottom,
                    left: 16,
                    right: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xC00F172A), // Translucent frosted smoked glass
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.16),
                        width: 1.0,
                      ),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "© 2026 SecureAI. All rights reserved.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double radius;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
  });
}

class _ConstellationPainter extends CustomPainter {
  final List<_Particle> particles;

  _ConstellationPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final particlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Draw connecting lines between particles within proximity
    const maxDistance = 0.18;
    for (int i = 0; i < particles.length; i++) {
      final p1 = particles[i];
      final pos1 = Offset(p1.x * size.width, p1.y * size.height);

      for (int j = i + 1; j < particles.length; j++) {
        final p2 = particles[j];
        final dx = p1.x - p2.x;
        final dy = p1.y - p2.y;
        final dist = sqrt(dx * dx + dy * dy);

        if (dist < maxDistance) {
          final alpha = (1.0 - (dist / maxDistance)) * 0.35;
          linePaint.color = Colors.white.withValues(alpha: alpha);
          final pos2 = Offset(p2.x * size.width, p2.y * size.height);
          canvas.drawLine(pos1, pos2, linePaint);
        }
      }

      // Draw particle dot
      canvas.drawCircle(pos1, p1.radius, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) => true;
}
