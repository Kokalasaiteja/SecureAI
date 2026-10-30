import 'package:flutter/material.dart';

/// Clean, legitimate copyright footer that flows naturally at the end of page content.
/// Avoids floating overlays, fixed positioning, and horizontal border cutoffs.
class CopyrightFooter extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const CopyrightFooter({
    super.key,
    this.padding = const EdgeInsets.only(top: 24, bottom: 20),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: const Center(
        child: Text(
          "© 2026 SecureAI. All rights reserved.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

