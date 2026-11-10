import 'package:flutter/material.dart';

class AuditPresentationState {
  final Color statusColor;
  final IconData statusIcon;
  final String statusSubtitle;
  final String rawClassification;
  final bool isPhishingOrSpam;
  final bool isSuspicious;

  /// Indicates whether the content classification engine produced a Safe/Ham verdict.
  /// NOTE: This field is informational and does NOT imply that the overall message presentation is safe;
  /// all visual elements (color, icon, subtitle) are strictly governed by statusColor, statusIcon,
  /// and statusSubtitle to ensure fail-safe presentation when links are unverified, timed out, or contradictory.
  final bool isSafeOrHam;

  const AuditPresentationState({
    required this.statusColor,
    required this.statusIcon,
    required this.statusSubtitle,
    required this.rawClassification,
    required this.isPhishingOrSpam,
    required this.isSuspicious,
    required this.isSafeOrHam,
  });
}

class AuditPresentation {
  static const Color colorRed = Color(0xFFEF4444);
  static const Color colorYellow = Color(0xFFEAB308);
  static const Color colorGreen = Color(0xFF22C55E);
  static const Color colorBlue = Color(0xFF3B82F6);
  static const Color colorOrange = Color(0xFFF97316);

  static AuditPresentationState computeEmailPresentation(Map<String, dynamic>? result) {
    final bool isSuccess = result != null && result['success'] == true;
    final String rawClassification = result?['result']?.toString() ??
        result?['classification']?.toString() ??
        "Unknown";
    final String normCls = rawClassification.trim().toLowerCase();

    // Authoritative classifications require an explicit successful response:
    final bool isPhishing = isSuccess && normCls == 'phishing';
    final bool isSuspicious = isSuccess && normCls == 'suspicious';
    final bool isSafe = isSuccess && (normCls == 'safe' || normCls == 'legitimate' || normCls == 'ham');

    Map<String, dynamic>? urlAudit;
    final dynamic rawAudit = result?['url_audit'];
    if (rawAudit is Map) {
      try {
        urlAudit = <String, dynamic>{};
        for (final entry in rawAudit.entries) {
          if (entry.key != null) {
            urlAudit[entry.key.toString()] = entry.value;
          }
        }
      } catch (_) {
        urlAudit = null;
      }
    }

    final String auditStatus = urlAudit?['status']?.toString().trim().toLowerCase() ?? 'unknown';
    final dynamic rawHasLinks = urlAudit?['has_links'];
    final bool isExplicitHasLinksTrue = rawHasLinks == true;
    final bool isExplicitHasLinksFalse = rawHasLinks == false;
    final bool linksVerifiedClean = urlAudit?['links_verified_clean'] == true;
    final bool linksUnverified = urlAudit?['links_unverified'] == true;
    final bool isTimeout = urlAudit?['url_audit_timeout'] == true || auditStatus == 'timeout';
    final String threatCategory = urlAudit?['threat_verdict_category']?.toString() ?? 'NONE';

    final dynamic rawTotal = urlAudit?['total_detected_links'];
    final dynamic rawScanned = urlAudit?['scanned_links_count'];
    final dynamic rawOmitted = urlAudit?['omitted_links_count'];

    final int? totalDetected = (rawTotal is int)
        ? rawTotal
        : (rawTotal is String ? int.tryParse(rawTotal) : null);
    final int? scannedCount = (rawScanned is int)
        ? rawScanned
        : (rawScanned is String ? int.tryParse(rawScanned) : null);
    final int? omittedCount = (rawOmitted is int)
        ? rawOmitted
        : (rawOmitted is String ? int.tryParse(rawOmitted) : null);

    // Strict validation of link counts for a verified clean completed scan with links:
    final bool validVerifiedCleanCounts = totalDetected != null &&
        scannedCount != null &&
        omittedCount != null &&
        totalDetected > 0 &&
        scannedCount > 0 &&
        omittedCount == 0 &&
        scannedCount == totalDetected;

    final bool hasOmittedLinks = (omittedCount != null && omittedCount > 0);

    // Green state strictly requires all conditions:
    final bool isFullyVerifiedClean = isSuccess &&
        isSafe &&
        urlAudit != null &&
        auditStatus == 'completed' &&
        threatCategory == 'CLEAN' &&
        isExplicitHasLinksTrue &&
        linksVerifiedClean &&
        !linksUnverified &&
        !isTimeout &&
        validVerifiedCleanCounts;

    // Neutral blue state strictly requires explicit confirmation of zero external links without timeouts, unverified flags, or contradictory threat categories:
    final bool isExplicitZeroLinks = isSuccess &&
        isSafe &&
        urlAudit != null &&
        isExplicitHasLinksFalse &&
        auditStatus == 'no_links' &&
        threatCategory == 'NONE' &&
        !isTimeout &&
        !linksUnverified &&
        totalDetected != null &&
        scannedCount != null &&
        omittedCount != null &&
        totalDetected == 0 &&
        scannedCount == 0 &&
        omittedCount == 0;

    Color statusColor;
    IconData statusIcon;
    String statusSubtitle = "";
    bool effectiveSafe = false;

    if (isPhishing) {
      statusColor = colorRed;
      statusIcon = Icons.dangerous_rounded;
      statusSubtitle = "Threat Detected";
    } else if (isSuspicious) {
      statusColor = colorYellow;
      statusIcon = Icons.warning_amber_rounded;
      statusSubtitle = "Suspicious Indicators";
    } else if (isSafe && isSuccess) {
      effectiveSafe = true;
      if (isFullyVerifiedClean) {
        statusColor = colorGreen;
        statusIcon = Icons.verified_user_rounded;
        statusSubtitle = "Verified Legitimate & Links Clean";
      } else if (isExplicitZeroLinks) {
        statusColor = colorBlue;
        statusIcon = Icons.info_outline_rounded;
        statusSubtitle = "Content Safe (No External Links)";
      } else if (urlAudit == null || auditStatus == 'error') {
        statusColor = colorYellow;
        statusIcon = Icons.warning_amber_rounded;
        statusSubtitle = "Content Safe (Link Verification Unavailable)";
      } else if (isTimeout) {
        statusColor = colorYellow;
        statusIcon = Icons.warning_amber_rounded;
        statusSubtitle = "Content Safe (Links Unverified - Timeout)";
      } else if (linksUnverified || hasOmittedLinks) {
        statusColor = colorYellow;
        statusIcon = Icons.warning_amber_rounded;
        statusSubtitle = "Content Safe (Unverified Links Present)";
      } else {
        // Any contradictory, unscanned, skipped, unknown, or telemetry-mismatch state
        statusColor = colorYellow;
        statusIcon = Icons.warning_amber_rounded;
        statusSubtitle = "Content Safe (Links Not Fully Verified)";
      }
    } else {
      statusColor = colorOrange;
      statusIcon = Icons.help_outline_rounded;
      statusSubtitle = "Classification Inconclusive";
      effectiveSafe = false;
    }

    return AuditPresentationState(
      statusColor: statusColor,
      statusIcon: statusIcon,
      statusSubtitle: statusSubtitle,
      rawClassification: rawClassification,
      isPhishingOrSpam: isPhishing,
      isSuspicious: isSuspicious,
      isSafeOrHam: effectiveSafe,
    );
  }

  static AuditPresentationState computeSmsPresentation(Map<String, dynamic>? result) {
    final bool isSuccess = result != null && result['success'] == true;
    final String rawClassification = result?['result']?.toString() ??
        result?['classification']?.toString() ??
        'Unknown';
    final String normCls = rawClassification.trim().toLowerCase();

    // Authoritative classifications require an explicit successful response:
    final bool isSpamCandidate = normCls == 'spam' || result?['is_spam'] == true;
    final bool isSpam = isSuccess && isSpamCandidate;
    final bool isHam = isSuccess && !isSpam && (normCls == 'ham' || normCls == 'safe' || normCls == 'legitimate');

    Map<String, dynamic>? urlAudit;
    final dynamic rawAudit = result?['url_audit'];
    if (rawAudit is Map) {
      try {
        urlAudit = <String, dynamic>{};
        for (final entry in rawAudit.entries) {
          if (entry.key != null) {
            urlAudit[entry.key.toString()] = entry.value;
          }
        }
      } catch (_) {
        urlAudit = null;
      }
    }

    final String auditStatus = urlAudit?['status']?.toString().trim().toLowerCase() ?? 'unknown';
    final dynamic rawHasLinks = urlAudit?['has_links'];
    final bool isExplicitHasLinksTrue = rawHasLinks == true;
    final bool isExplicitHasLinksFalse = rawHasLinks == false;
    final bool linksVerifiedClean = urlAudit?['links_verified_clean'] == true;
    final bool linksUnverified = urlAudit?['links_unverified'] == true;
    final bool isTimeout = urlAudit?['url_audit_timeout'] == true || auditStatus == 'timeout';
    final String threatCategory = urlAudit?['threat_verdict_category']?.toString() ?? 'NONE';

    final dynamic rawTotal = urlAudit?['total_detected_links'];
    final dynamic rawScanned = urlAudit?['scanned_links_count'];
    final dynamic rawOmitted = urlAudit?['omitted_links_count'];

    final int? totalDetected = (rawTotal is int)
        ? rawTotal
        : (rawTotal is String ? int.tryParse(rawTotal) : null);
    final int? scannedCount = (rawScanned is int)
        ? rawScanned
        : (rawScanned is String ? int.tryParse(rawScanned) : null);
    final int? omittedCount = (rawOmitted is int)
        ? rawOmitted
        : (rawOmitted is String ? int.tryParse(rawOmitted) : null);

    final bool validVerifiedCleanCounts = totalDetected != null &&
        scannedCount != null &&
        omittedCount != null &&
        totalDetected > 0 &&
        scannedCount > 0 &&
        omittedCount == 0 &&
        scannedCount == totalDetected;

    final bool hasOmittedLinks = (omittedCount != null && omittedCount > 0);

    final bool isFullyVerifiedClean = isSuccess &&
        isHam &&
        urlAudit != null &&
        auditStatus == 'completed' &&
        threatCategory == 'CLEAN' &&
        isExplicitHasLinksTrue &&
        linksVerifiedClean &&
        !linksUnverified &&
        !isTimeout &&
        validVerifiedCleanCounts;

    final bool isExplicitZeroLinks = isSuccess &&
        isHam &&
        urlAudit != null &&
        isExplicitHasLinksFalse &&
        auditStatus == 'no_links' &&
        threatCategory == 'NONE' &&
        !isTimeout &&
        !linksUnverified &&
        totalDetected != null &&
        scannedCount != null &&
        omittedCount != null &&
        totalDetected == 0 &&
        scannedCount == 0 &&
        omittedCount == 0;

    Color statusColor;
    IconData statusIcon;
    String statusSubtitle = "";

    if (isSpam) {
      statusColor = colorRed;
      statusIcon = Icons.dangerous_rounded;
      if (threatCategory == 'POLICY_BLOCKED') {
        statusSubtitle = "Spam (Prohibited Infrastructure Blocked)";
      } else if (threatCategory == 'CONFIRMED_THREAT') {
        statusSubtitle = "Spam (Confirmed Malicious Threat)";
      } else if (threatCategory == 'SUSPICIOUS') {
        statusSubtitle = "Spam (Suspicious Link Anomaly)";
      } else {
        statusSubtitle = "Spam Detected";
      }
    } else if (isHam) {
      if (isFullyVerifiedClean) {
        statusColor = colorGreen;
        statusIcon = Icons.verified_user_rounded;
        statusSubtitle = "Verified Clean & Links Safe";
      } else if (isExplicitZeroLinks) {
        statusColor = colorBlue;
        statusIcon = Icons.info_outline_rounded;
        statusSubtitle = "Message Safe (No External Links)";
      } else if (urlAudit == null || auditStatus == 'error') {
        statusColor = colorYellow;
        statusIcon = Icons.warning_amber_rounded;
        statusSubtitle = "Message Safe (Link Verification Unavailable)";
      } else if (isTimeout) {
        statusColor = colorYellow;
        statusIcon = Icons.warning_amber_rounded;
        statusSubtitle = "Message Safe (Links Unverified - Timeout)";
      } else if (linksUnverified || hasOmittedLinks) {
        statusColor = colorYellow;
        statusIcon = Icons.warning_amber_rounded;
        statusSubtitle = "Message Safe (Unverified Links Present)";
      } else {
        statusColor = colorYellow;
        statusIcon = Icons.warning_amber_rounded;
        statusSubtitle = "Message Safe (Links Not Fully Verified)";
      }
    } else {
      statusColor = colorOrange;
      statusIcon = Icons.help_outline_rounded;
      statusSubtitle = "Classification Inconclusive";
    }

    return AuditPresentationState(
      statusColor: statusColor,
      statusIcon: statusIcon,
      statusSubtitle: statusSubtitle,
      rawClassification: rawClassification,
      isPhishingOrSpam: isSpam,
      isSuspicious: false,
      isSafeOrHam: isHam,
    );
  }
}
