import 'dart:ui';
import 'package:flutter/material.dart';

class HttpErrorWidget extends StatelessWidget {
  final int statusCode;
  final String? message;
  final VoidCallback? onRetry;
  final VoidCallback? onAction;
  final String? actionLabel;
  final bool isCompact;

  const HttpErrorWidget({
    super.key,
    required this.statusCode,
    this.message,
    this.onRetry,
    this.onAction,
    this.actionLabel,
    this.isCompact = false,
  });

  static Future<void> showErrorDialog(
    BuildContext context, {
    required int statusCode,
    String? message,
    VoidCallback? onRetry,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: HttpErrorWidget(
            statusCode: statusCode,
            message: message,
            onRetry: onRetry != null
                ? () {
                    Navigator.of(ctx).pop();
                    onRetry();
                  }
                : null,
            onAction: () => Navigator.of(ctx).pop(),
            actionLabel: "Dismiss",
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Configuration based on HTTP status code
    final IconData icon;
    final Color accentColor;
    final String title;
    final String defaultMsg;

    switch (statusCode) {
      case 503:
      case 502:
      case 504:
        icon = Icons.cloud_sync_rounded;
        accentColor = const Color(0xFFF59E0B); // Amber
        title = "Cloud Service Awakening (503)";
        defaultMsg = "The Render cloud server is waking up from idle mode (cold start takes ~60-75s). Subsequent requests will respond in under 1 second.";
        break;
      case 403:
        icon = Icons.gpp_bad_rounded;
        accentColor = const Color(0xFFEF4444); // Red
        title = "Access Denied (403)";
        defaultMsg = "You do not have permission to access this resource, or your account is awaiting administrator activation.";
        break;
      case 302:
        icon = Icons.lock_clock_rounded;
        accentColor = const Color(0xFF818CF8); // Indigo
        title = "Session Expired (302)";
        defaultMsg = "Your security session has expired due to inactivity. Please log in again to continue.";
        break;
      case 404:
        icon = Icons.search_off_rounded;
        accentColor = const Color(0xFF38BDF8); // Sky blue
        title = "Resource Not Found (404)";
        defaultMsg = "The requested endpoint or security resource could not be found.";
        break;
      case 500:
      default:
        icon = Icons.warning_amber_rounded;
        accentColor = const Color(0xFFF97316); // Orange
        title = "Server Processing Error ($statusCode)";
        defaultMsg = "An unexpected error occurred while processing the request on the cloud backend.";
        break;
    }

    final displayMsg = (message != null && message!.isNotEmpty) ? message! : defaultMsg;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.all(isCompact ? 16 : 22),
          decoration: BoxDecoration(
            color: const Color(0xE60F172A), // Dark slate liquid glass
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: accentColor.withValues(alpha: 0.15),
                blurRadius: 24,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon & Status Badge
              Container(
                width: isCompact ? 44 : 54,
                height: isCompact ? 44 : 54,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: isCompact ? 24 : 28,
                ),
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isCompact ? 15 : 17,
                ),
              ),
              const SizedBox(height: 8),

              // Message
              Text(
                displayMsg,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFD1D5DB),
                  fontSize: isCompact ? 12 : 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onRetry != null) ...[
                    Flexible(
                      child: ElevatedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text("Retry", style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (onAction != null)
                    Flexible(
                      child: OutlinedButton(
                        onPressed: onAction,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          actionLabel ?? "OK",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

