import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secure_ai/models/audit_presentation.dart';

void main() {
  group('Email Phishing Presentation Unit & Widget Tests', () {
    test('Verified clean link yields green shield and Verified Legitimate subtitle', () {
      final res = {
        'success': true,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          'has_links': true,
          'links_verified_clean': true,
          'links_unverified': false,
          'status': 'completed',
          'total_detected_links': 1,
          'scanned_links_count': 1,
          'omitted_links_count': 0,
          'threat_verdict_category': 'CLEAN',
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorGreen);
      expect(state.statusIcon, Icons.verified_user_rounded);
      expect(state.statusSubtitle, 'Verified Legitimate & Links Clean');
      expect(state.isSafeOrHam, true);
      expect(state.isPhishingOrSpam, false);
    });

    test('Safe content with no external links yields neutral blue card', () {
      final res = {
        'success': true,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          'has_links': false,
          'links_verified_clean': false,
          'links_unverified': false,
          'status': 'no_links',
          'total_detected_links': 0,
          'scanned_links_count': 0,
          'omitted_links_count': 0,
          'threat_verdict_category': 'NONE',
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorBlue);
      expect(state.statusIcon, Icons.info_outline_rounded);
      expect(state.statusSubtitle, 'Content Safe (No External Links)');
    });

    test('Safe content with timeout yields yellow warning (never green)', () {
      final res = {
        'success': true,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          'has_links': true,
          'links_verified_clean': false,
          'links_unverified': true,
          'status': 'timeout',
          'threat_verdict_category': 'UNVERIFIED',
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Content Safe (Links Unverified - Timeout)');
    });

    test('Safe content with unverified UGC links yields yellow warning', () {
      final res = {
        'success': true,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          'has_links': true,
          'links_verified_clean': false,
          'links_unverified': true,
          'status': 'completed',
          'threat_verdict_category': 'UNVERIFIED',
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Content Safe (Unverified Links Present)');
    });

    test('Safe content with null or error url_audit yields yellow warning (safe fail)', () {
      final resNullAudit = {
        'success': true,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': null
      };
      final stateNull = AuditPresentation.computeEmailPresentation(resNullAudit);
      expect(stateNull.statusColor, AuditPresentation.colorYellow);
      expect(stateNull.statusSubtitle, 'Content Safe (Link Verification Unavailable)');

      final resError = {
        'success': true,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          'status': 'error',
          'has_links': null,
          'links_verified_clean': false,
          'links_unverified': true,
        }
      };
      final stateErr = AuditPresentation.computeEmailPresentation(resError);
      expect(stateErr.statusColor, AuditPresentation.colorYellow);
      expect(stateErr.statusSubtitle, 'Content Safe (Link Verification Unavailable)');
    });

    test('Phishing classification yields red danger card', () {
      final res = {
        'success': true,
        'result': 'Phishing',
        'classification': 'Phishing',
        'url_audit': {
          'has_links': true,
          'links_verified_clean': false,
          'threat_verdict_category': 'CONFIRMED_THREAT',
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorRed);
      expect(state.statusIcon, Icons.dangerous_rounded);
      expect(state.statusSubtitle, 'Threat Detected');
      expect(state.isPhishingOrSpam, true);
    });

    test('Suspicious classification yields yellow warning card', () {
      final res = {
        'success': true,
        'result': 'Suspicious',
        'classification': 'Suspicious',
        'url_audit': {
          'has_links': true,
          'links_verified_clean': false,
          'threat_verdict_category': 'POLICY_BLOCKED',
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Suspicious Indicators');
      expect(state.isSuspicious, true);
    });

    test('Contradictory telemetry links_verified_clean=true with links_unverified=true fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          'has_links': true,
          'links_verified_clean': true,
          'links_unverified': true,
          'status': 'completed',
          'threat_verdict_category': 'UNVERIFIED',
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Content Safe (Unverified Links Present)');
      expect(state.isSafeOrHam, true);
    });

    test('Contradictory telemetry status=skipped with has_links=true fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          'has_links': true,
          'links_verified_clean': true,
          'links_unverified': false,
          'status': 'skipped',
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Content Safe (Links Not Fully Verified)');
      expect(state.isSafeOrHam, true);
    });

    test('Unknown audit status with links_verified_clean=true fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          'has_links': true,
          'links_verified_clean': true,
          'links_unverified': false,
          'status': 'unknown',
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Content Safe (Links Not Fully Verified)');
    });

    test('Missing success field yields inconclusive orange state', () {
      final res = {
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          'has_links': true,
          'links_verified_clean': true,
          'links_unverified': false,
          'status': 'completed',
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorOrange);
      expect(state.statusIcon, Icons.help_outline_rounded);
      expect(state.statusSubtitle, 'Classification Inconclusive');
      expect(state.isSafeOrHam, false);
    });

    test('Explicit success=false with classification Safe yields inconclusive orange state', () {
      final res = {
        'success': false,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          'has_links': true,
          'links_verified_clean': true,
          'links_unverified': false,
          'status': 'completed',
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorOrange);
      expect(state.statusIcon, Icons.help_outline_rounded);
      expect(state.statusSubtitle, 'Classification Inconclusive');
      expect(state.isSafeOrHam, false);
    });

    test('Explicit success=false with classification Phishing yields inconclusive orange state (never Phishing)', () {
      final res = {
        'success': false,
        'result': 'Phishing',
        'classification': 'Phishing',
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorOrange);
      expect(state.statusIcon, Icons.help_outline_rounded);
      expect(state.statusSubtitle, 'Classification Inconclusive');
      expect(state.isPhishingOrSpam, false);
      expect(state.isSafeOrHam, false);
    });

    test('Missing success field with classification Phishing yields inconclusive orange state', () {
      final res = {
        'result': 'Phishing',
        'classification': 'Phishing',
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorOrange);
      expect(state.statusIcon, Icons.help_outline_rounded);
      expect(state.statusSubtitle, 'Classification Inconclusive');
      expect(state.isPhishingOrSpam, false);
      expect(state.isSafeOrHam, false);
    });

    test('Completed audit with omitted links fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          'has_links': true,
          'links_verified_clean': true,
          'links_unverified': false,
          'status': 'completed',
          'total_detected_links': 5,
          'scanned_links_count': 3,
          'omitted_links_count': 2,
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Content Safe (Unverified Links Present)');
    });

    test('Completed audit with inconsistent scanned and total counts fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          'has_links': true,
          'links_verified_clean': true,
          'links_unverified': false,
          'status': 'completed',
          'total_detected_links': 3,
          'scanned_links_count': 2,
          'omitted_links_count': 0,
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Content Safe (Links Not Fully Verified)');
    });

    test('Valid completed, fully verified clean audit remains green', () {
      final res = {
        'success': true,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          'has_links': true,
          'links_verified_clean': true,
          'links_unverified': false,
          'status': 'completed',
          'total_detected_links': 2,
          'scanned_links_count': 2,
          'omitted_links_count': 0,
          'threat_verdict_category': 'CLEAN',
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorGreen);
      expect(state.statusIcon, Icons.verified_user_rounded);
      expect(state.statusSubtitle, 'Verified Legitimate & Links Clean');
      expect(state.isSafeOrHam, true);
    });

    test('Missing count fields with links_verified_clean=true fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          'has_links': true,
          'links_verified_clean': true,
          'links_unverified': false,
          'status': 'completed',
          'total_detected_links': null,
          'scanned_links_count': null,
          'omitted_links_count': null,
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Content Safe (Links Not Fully Verified)');
      expect(state.isSafeOrHam, true);
    });

    test('Negative count values fail safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          'has_links': true,
          'links_verified_clean': true,
          'links_unverified': false,
          'status': 'completed',
          'total_detected_links': -1,
          'scanned_links_count': -1,
          'omitted_links_count': 0,
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Content Safe (Links Not Fully Verified)');
    });

    test('Malformed non-numeric counts fail safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          'has_links': true,
          'links_verified_clean': true,
          'links_unverified': false,
          'status': 'completed',
          'total_detected_links': 'invalid',
          'scanned_links_count': 'nan',
          'omitted_links_count': 0,
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Content Safe (Links Not Fully Verified)');
    });

    test('Unscanned links (has_links=true with 0 scanned) fails safe to yellow (never blue)', () {
      final res = {
        'success': true,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          'has_links': true,
          'links_verified_clean': false,
          'links_unverified': false,
          'status': 'completed',
          'total_detected_links': 2,
          'scanned_links_count': 0,
          'omitted_links_count': 0,
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Content Safe (Links Not Fully Verified)');
    });

    test('Zero external links (has_links=false with 0 detected and status no_links) yields neutral blue card', () {
      final res = {
        'success': true,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          'has_links': false,
          'links_verified_clean': false,
          'links_unverified': false,
          'status': 'no_links',
          'total_detected_links': 0,
          'scanned_links_count': 0,
          'omitted_links_count': 0,
          'threat_verdict_category': 'NONE',
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorBlue);
      expect(state.statusIcon, Icons.info_outline_rounded);
      expect(state.statusSubtitle, 'Content Safe (No External Links)');
      expect(state.isSafeOrHam, true);
    });

    test('Email contradictory no_links with CONFIRMED_THREAT category fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          'has_links': false,
          'status': 'no_links',
          'total_detected_links': 0,
          'scanned_links_count': 0,
          'omitted_links_count': 0,
          'threat_verdict_category': 'CONFIRMED_THREAT',
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Content Safe (Links Not Fully Verified)');
    });

    test('has_links missing with status completed fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          'status': 'completed',
          'total_detected_links': 0,
          'scanned_links_count': 0,
          'omitted_links_count': 0,
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Content Safe (Links Not Fully Verified)');
      expect(state.isSafeOrHam, true);
    });

    test('has_links=false with positive total_detected_links fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          'has_links': false,
          'status': 'no_links',
          'total_detected_links': 5,
          'scanned_links_count': 0,
          'omitted_links_count': 0,
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Content Safe (Links Not Fully Verified)');
    });

    test('has_links=false with nonzero scanned count fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          'has_links': false,
          'status': 'no_links',
          'total_detected_links': 0,
          'scanned_links_count': 1,
          'omitted_links_count': 0,
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Content Safe (Links Not Fully Verified)');
    });

    test('has_links=false with missing count fields fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          'has_links': false,
          'status': 'no_links',
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Content Safe (Links Not Fully Verified)');
    });

    test('has_links=false with malformed count fields fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          'has_links': false,
          'status': 'no_links',
          'total_detected_links': 'bad',
          'scanned_links_count': 0,
          'omitted_links_count': 0,
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Content Safe (Links Not Fully Verified)');
    });

    test('has_links=false with status skipped fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          'has_links': false,
          'status': 'skipped',
          'total_detected_links': 0,
          'scanned_links_count': 0,
          'omitted_links_count': 0,
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Content Safe (Links Not Fully Verified)');
    });

    test('Malformed url_audit with non-string keys does not crash and handles safely', () {
      final res = {
        'success': true,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          123: 'val',
          true: 'other',
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Content Safe (Links Not Fully Verified)');
    });

    test('Email contradictory no_links with url_audit_timeout fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          'has_links': false,
          'status': 'no_links',
          'total_detected_links': 0,
          'scanned_links_count': 0,
          'omitted_links_count': 0,
          'url_audit_timeout': true,
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Content Safe (Links Unverified - Timeout)');
    });

    test('Email contradictory no_links with links_unverified fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          'has_links': false,
          'status': 'no_links',
          'total_detected_links': 0,
          'scanned_links_count': 0,
          'omitted_links_count': 0,
          'links_unverified': true,
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Content Safe (Unverified Links Present)');
    });

    test('Email links_verified_clean with threat_verdict_category UNVERIFIED fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Safe',
        'classification': 'Safe',
        'url_audit': {
          'has_links': true,
          'links_verified_clean': true,
          'links_unverified': false,
          'status': 'completed',
          'total_detected_links': 1,
          'scanned_links_count': 1,
          'omitted_links_count': 0,
          'threat_verdict_category': 'UNVERIFIED',
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Content Safe (Links Not Fully Verified)');
    });
  });

  group('SMS Spam Presentation Unit & Widget Tests', () {
    test('Ham with verified clean links yields green shield', () {
      final res = {
        'success': true,
        'result': 'Ham',
        'classification': 'Ham',
        'is_spam': false,
        'url_audit': {
          'has_links': true,
          'links_verified_clean': true,
          'links_unverified': false,
          'status': 'completed',
          'total_detected_links': 1,
          'scanned_links_count': 1,
          'omitted_links_count': 0,
          'threat_verdict_category': 'CLEAN',
        }
      };
      final state = AuditPresentation.computeSmsPresentation(res);
      expect(state.statusColor, AuditPresentation.colorGreen);
      expect(state.statusSubtitle, 'Verified Clean & Links Safe');
      expect(state.isSafeOrHam, true);
      expect(state.isPhishingOrSpam, false);
    });

    test('Ham with no external links yields neutral blue card', () {
      final res = {
        'success': true,
        'result': 'Ham',
        'classification': 'Ham',
        'is_spam': false,
        'url_audit': {
          'has_links': false,
          'status': 'no_links',
          'total_detected_links': 0,
          'scanned_links_count': 0,
          'omitted_links_count': 0,
          'threat_verdict_category': 'NONE',
        }
      };
      final state = AuditPresentation.computeSmsPresentation(res);
      expect(state.statusColor, AuditPresentation.colorBlue);
      expect(state.statusIcon, Icons.info_outline_rounded);
      expect(state.statusSubtitle, 'Message Safe (No External Links)');
      expect(state.isSafeOrHam, true);
    });

    test('SMS contradictory no_links with CONFIRMED_THREAT category fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Ham',
        'classification': 'Ham',
        'is_spam': false,
        'url_audit': {
          'has_links': false,
          'status': 'no_links',
          'total_detected_links': 0,
          'scanned_links_count': 0,
          'omitted_links_count': 0,
          'threat_verdict_category': 'CONFIRMED_THREAT',
        }
      };
      final state = AuditPresentation.computeSmsPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Message Safe (Links Not Fully Verified)');
    });

    test('Spam with POLICY_BLOCKED yields Prohibited Infrastructure subtitle', () {
      final res = {
        'success': true,
        'result': 'Spam',
        'is_spam': true,
        'url_audit': {
          'has_links': true,
          'threat_verdict_category': 'POLICY_BLOCKED',
        }
      };
      final state = AuditPresentation.computeSmsPresentation(res);
      expect(state.statusColor, AuditPresentation.colorRed);
      expect(state.statusSubtitle, 'Spam (Prohibited Infrastructure Blocked)');
    });

    test('Spam with CONFIRMED_THREAT yields Confirmed Malicious Threat subtitle', () {
      final res = {
        'success': true,
        'result': 'Spam',
        'is_spam': true,
        'url_audit': {
          'has_links': true,
          'threat_verdict_category': 'CONFIRMED_THREAT',
        }
      };
      final state = AuditPresentation.computeSmsPresentation(res);
      expect(state.statusColor, AuditPresentation.colorRed);
      expect(state.statusSubtitle, 'Spam (Confirmed Malicious Threat)');
    });

    test('Spam with SUSPICIOUS yields Suspicious Link Anomaly subtitle', () {
      final res = {
        'success': true,
        'result': 'Spam',
        'is_spam': true,
        'url_audit': {
          'has_links': true,
          'threat_verdict_category': 'SUSPICIOUS',
        }
      };
      final state = AuditPresentation.computeSmsPresentation(res);
      expect(state.statusColor, AuditPresentation.colorRed);
      expect(state.statusSubtitle, 'Spam (Suspicious Link Anomaly)');
    });

    test('Explicit success=false with classification Ham yields inconclusive orange state (never Ham)', () {
      final res = {
        'success': false,
        'result': 'Ham',
        'classification': 'Ham',
        'is_spam': false,
        'url_audit': {
          'has_links': true,
          'links_verified_clean': true,
          'links_unverified': false,
          'status': 'completed',
        }
      };
      final state = AuditPresentation.computeSmsPresentation(res);
      expect(state.statusColor, AuditPresentation.colorOrange);
      expect(state.statusIcon, Icons.help_outline_rounded);
      expect(state.statusSubtitle, 'Classification Inconclusive');
      expect(state.isSafeOrHam, false);
    });

    test('SMS Contradictory telemetry status=skipped with has_links=true fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Ham',
        'classification': 'Ham',
        'is_spam': false,
        'url_audit': {
          'has_links': true,
          'links_verified_clean': true,
          'links_unverified': false,
          'status': 'skipped',
        }
      };
      final state = AuditPresentation.computeSmsPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Message Safe (Links Not Fully Verified)');
      expect(state.isSafeOrHam, true);
    });

    test('SMS Unknown audit status with links_verified_clean=true fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Ham',
        'classification': 'Ham',
        'is_spam': false,
        'url_audit': {
          'has_links': true,
          'links_verified_clean': true,
          'links_unverified': false,
          'status': 'unknown',
        }
      };
      final state = AuditPresentation.computeSmsPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Message Safe (Links Not Fully Verified)');
    });

    test('SMS Completed audit with omitted links fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Ham',
        'classification': 'Ham',
        'is_spam': false,
        'url_audit': {
          'has_links': true,
          'links_verified_clean': true,
          'links_unverified': false,
          'status': 'completed',
          'total_detected_links': 4,
          'scanned_links_count': 2,
          'omitted_links_count': 2,
        }
      };
      final state = AuditPresentation.computeSmsPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Message Safe (Unverified Links Present)');
    });

    test('SMS Completed audit with inconsistent counts fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Ham',
        'classification': 'Ham',
        'is_spam': false,
        'url_audit': {
          'has_links': true,
          'links_verified_clean': true,
          'links_unverified': false,
          'status': 'completed',
          'total_detected_links': 4,
          'scanned_links_count': 3,
          'omitted_links_count': 0,
        }
      };
      final state = AuditPresentation.computeSmsPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Message Safe (Links Not Fully Verified)');
    });

    test('SMS Valid completed, fully verified clean audit remains green', () {
      final res = {
        'success': true,
        'result': 'Ham',
        'classification': 'Ham',
        'is_spam': false,
        'url_audit': {
          'has_links': true,
          'links_verified_clean': true,
          'links_unverified': false,
          'status': 'completed',
          'total_detected_links': 1,
          'scanned_links_count': 1,
          'omitted_links_count': 0,
          'threat_verdict_category': 'CLEAN',
        }
      };
      final state = AuditPresentation.computeSmsPresentation(res);
      expect(state.statusColor, AuditPresentation.colorGreen);
      expect(state.statusIcon, Icons.verified_user_rounded);
      expect(state.statusSubtitle, 'Verified Clean & Links Safe');
      expect(state.isSafeOrHam, true);
    });

    test('SMS has_links missing with status completed fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Ham',
        'classification': 'Ham',
        'is_spam': false,
        'url_audit': {
          'status': 'completed',
          'total_detected_links': 0,
          'scanned_links_count': 0,
          'omitted_links_count': 0,
        }
      };
      final state = AuditPresentation.computeSmsPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Message Safe (Links Not Fully Verified)');
      expect(state.isSafeOrHam, true);
    });

    test('SMS has_links=false with positive total_detected_links fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Ham',
        'classification': 'Ham',
        'is_spam': false,
        'url_audit': {
          'has_links': false,
          'status': 'no_links',
          'total_detected_links': 3,
          'scanned_links_count': 0,
          'omitted_links_count': 0,
        }
      };
      final state = AuditPresentation.computeSmsPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Message Safe (Links Not Fully Verified)');
    });

    test('SMS has_links=false with nonzero scanned count fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Ham',
        'classification': 'Ham',
        'is_spam': false,
        'url_audit': {
          'has_links': false,
          'status': 'no_links',
          'total_detected_links': 0,
          'scanned_links_count': 1,
          'omitted_links_count': 0,
        }
      };
      final state = AuditPresentation.computeSmsPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Message Safe (Links Not Fully Verified)');
    });

    test('SMS has_links=false with missing count fields fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Ham',
        'classification': 'Ham',
        'is_spam': false,
        'url_audit': {
          'has_links': false,
          'status': 'no_links',
        }
      };
      final state = AuditPresentation.computeSmsPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Message Safe (Links Not Fully Verified)');
    });

    test('SMS has_links=false with malformed count fields fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Ham',
        'classification': 'Ham',
        'is_spam': false,
        'url_audit': {
          'has_links': false,
          'status': 'no_links',
          'total_detected_links': 'bad',
          'scanned_links_count': 0,
          'omitted_links_count': 0,
        }
      };
      final state = AuditPresentation.computeSmsPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Message Safe (Links Not Fully Verified)');
    });

    test('SMS has_links=false with status skipped fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Ham',
        'classification': 'Ham',
        'is_spam': false,
        'url_audit': {
          'has_links': false,
          'status': 'skipped',
          'total_detected_links': 0,
          'scanned_links_count': 0,
          'omitted_links_count': 0,
        }
      };
      final state = AuditPresentation.computeSmsPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Message Safe (Links Not Fully Verified)');
    });

    test('SMS Malformed url_audit with non-string keys does not crash and handles safely', () {
      final res = {
        'success': true,
        'result': 'Ham',
        'classification': 'Ham',
        'is_spam': false,
        'url_audit': {
          123: 'val',
          false: 'other',
        }
      };
      final state = AuditPresentation.computeSmsPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Message Safe (Links Not Fully Verified)');
    });

    test('Explicit success=false with classification Spam and is_spam=true yields inconclusive orange state (never Spam)', () {
      final res = {
        'success': false,
        'result': 'Spam',
        'classification': 'Spam',
        'is_spam': true,
      };
      final state = AuditPresentation.computeSmsPresentation(res);
      expect(state.statusColor, AuditPresentation.colorOrange);
      expect(state.statusIcon, Icons.help_outline_rounded);
      expect(state.statusSubtitle, 'Classification Inconclusive');
      expect(state.isPhishingOrSpam, false);
      expect(state.isSafeOrHam, false);
    });

    test('Missing success field with classification Spam yields inconclusive orange state', () {
      final res = {
        'result': 'Spam',
        'classification': 'Spam',
        'is_spam': true,
      };
      final state = AuditPresentation.computeSmsPresentation(res);
      expect(state.statusColor, AuditPresentation.colorOrange);
      expect(state.statusIcon, Icons.help_outline_rounded);
      expect(state.statusSubtitle, 'Classification Inconclusive');
      expect(state.isPhishingOrSpam, false);
      expect(state.isSafeOrHam, false);
    });

    test('Malformed success value with classification Spam yields inconclusive orange state', () {
      final res = {
        'success': 'true', // string instead of boolean
        'result': 'Spam',
        'is_spam': true,
      };
      final state = AuditPresentation.computeSmsPresentation(res);
      expect(state.statusColor, AuditPresentation.colorOrange);
      expect(state.statusIcon, Icons.help_outline_rounded);
      expect(state.statusSubtitle, 'Classification Inconclusive');
      expect(state.isPhishingOrSpam, false);
      expect(state.isSafeOrHam, false);
    });

    test('Confirmed Spam with success=true remains correctly classified as Spam with red danger card', () {
      final res = {
        'success': true,
        'result': 'Spam',
        'classification': 'Spam',
        'is_spam': true,
      };
      final state = AuditPresentation.computeSmsPresentation(res);
      expect(state.statusColor, AuditPresentation.colorRed);
      expect(state.statusIcon, Icons.dangerous_rounded);
      expect(state.statusSubtitle, 'Spam Detected');
      expect(state.isPhishingOrSpam, true);
      expect(state.isSafeOrHam, false);
    });

    test('Contradictory SMS payload result=Ham with is_spam=true conservatively prioritizes Spam', () {
      final res = {
        'success': true,
        'result': 'Ham',
        'classification': 'Ham',
        'is_spam': true,
      };
      final state = AuditPresentation.computeSmsPresentation(res);
      expect(state.statusColor, AuditPresentation.colorRed);
      expect(state.statusIcon, Icons.dangerous_rounded);
      expect(state.statusSubtitle, 'Spam Detected');
      expect(state.isPhishingOrSpam, true);
      expect(state.isSafeOrHam, false);
    });

    test('Confirmed Ham with success=true remains correctly classified with green shield', () {
      final res = {
        'success': true,
        'result': 'Ham',
        'classification': 'Ham',
        'is_spam': false,
        'url_audit': {
          'has_links': true,
          'links_verified_clean': true,
          'links_unverified': false,
          'status': 'completed',
          'total_detected_links': 2,
          'scanned_links_count': 2,
          'omitted_links_count': 0,
          'threat_verdict_category': 'CLEAN',
        }
      };
      final state = AuditPresentation.computeSmsPresentation(res);
      expect(state.statusColor, AuditPresentation.colorGreen);
      expect(state.statusIcon, Icons.verified_user_rounded);
      expect(state.statusSubtitle, 'Verified Clean & Links Safe');
      expect(state.isSafeOrHam, true);
      expect(state.isPhishingOrSpam, false);
    });

    test('SMS contradictory no_links with url_audit_timeout fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Ham',
        'classification': 'Ham',
        'is_spam': false,
        'url_audit': {
          'has_links': false,
          'status': 'no_links',
          'total_detected_links': 0,
          'scanned_links_count': 0,
          'omitted_links_count': 0,
          'url_audit_timeout': true,
        }
      };
      final state = AuditPresentation.computeSmsPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Message Safe (Links Unverified - Timeout)');
    });

    test('SMS contradictory no_links with links_unverified fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Ham',
        'classification': 'Ham',
        'is_spam': false,
        'url_audit': {
          'has_links': false,
          'status': 'no_links',
          'total_detected_links': 0,
          'scanned_links_count': 0,
          'omitted_links_count': 0,
          'links_unverified': true,
        }
      };
      final state = AuditPresentation.computeSmsPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Message Safe (Unverified Links Present)');
    });

    test('SMS links_verified_clean with threat_verdict_category UNVERIFIED fails safe to yellow', () {
      final res = {
        'success': true,
        'result': 'Ham',
        'classification': 'Ham',
        'is_spam': false,
        'url_audit': {
          'has_links': true,
          'links_verified_clean': true,
          'links_unverified': false,
          'status': 'completed',
          'total_detected_links': 1,
          'scanned_links_count': 1,
          'omitted_links_count': 0,
          'threat_verdict_category': 'UNVERIFIED',
        }
      };
      final state = AuditPresentation.computeSmsPresentation(res);
      expect(state.statusColor, AuditPresentation.colorYellow);
      expect(state.statusIcon, Icons.warning_amber_rounded);
      expect(state.statusSubtitle, 'Message Safe (Links Not Fully Verified)');
    });
  });

  group('Presentation Widget Rendering Tests', () {
    testWidgets('Renders verified clean status card widget faithfully', (WidgetTester tester) async {
      final res = {
        'success': true,
        'result': 'Safe',
        'url_audit': {
          'has_links': true,
          'links_verified_clean': true,
          'status': 'completed',
          'total_detected_links': 1,
          'scanned_links_count': 1,
          'omitted_links_count': 0,
          'threat_verdict_category': 'CLEAN',
        }
      };
      final state = AuditPresentation.computeEmailPresentation(res);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              color: state.statusColor,
              child: Column(
                children: [
                  Icon(state.statusIcon),
                  Text(state.statusSubtitle),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Verified Legitimate & Links Clean'), findsOneWidget);
      expect(find.byIcon(Icons.verified_user_rounded), findsOneWidget);
    });

    testWidgets('Renders prohibited policy spam status card faithfully', (WidgetTester tester) async {
      final res = {
        'success': true,
        'result': 'Spam',
        'is_spam': true,
        'url_audit': {
          'has_links': true,
          'threat_verdict_category': 'POLICY_BLOCKED',
        }
      };
      final state = AuditPresentation.computeSmsPresentation(res);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Icon(state.statusIcon),
                Text(state.statusSubtitle),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Spam (Prohibited Infrastructure Blocked)'), findsOneWidget);
      expect(find.byIcon(Icons.dangerous_rounded), findsOneWidget);
    });
  });
}
