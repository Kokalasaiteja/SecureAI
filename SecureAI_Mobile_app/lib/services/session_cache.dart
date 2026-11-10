import 'api_service.dart';

class SessionCache {
  // SMS Spam state
  static String? smsInput;
  static Map<String, dynamic>? smsResult;
  static bool smsLoading = false;
  static Future<Map<String, dynamic>>? smsFuture;

  // Email Phishing state
  static String? emailInput;
  static Map<String, dynamic>? emailResult;
  static bool emailLoading = false;
  static Future<Map<String, dynamic>>? emailFuture;

  // QR Scanner state
  static List<int>? qrBytes;
  static String? qrFileName;
  static String? qrFilePath;
  static Map<String, dynamic>? qrResult;
  static String? qrErrorMessage;
  static bool qrLoading = false;
  static Future<Map<String, dynamic>>? qrFuture;

  // Password Analyzer state
  static String? passwordInput;
  static Map<String, dynamic>? passwordResult;
  static String? passwordErrorMessage;
  static int? passwordErrorStatusCode;
  static bool passwordLoading = false;
  static Future<Map<String, dynamic>>? passwordFuture;

  // Anomaly Prediction state
  static String? anomalyHour;
  static String? anomalyScore;
  static Map<String, dynamic>? anomalyResult;
  static String? anomalyErrorMessage;
  static bool anomalyLoading = false;
  static Future<Map<String, dynamic>>? anomalyFuture;

  // --- Background Dispatchers with Guaranteed State Persistence ---

  static String sanitizeMessage(dynamic err) {
    final s = err.toString();
    if (s.contains('RESOURCE_EXHAUSTED') || s.contains('429') || s.toLowerCase().contains('quota')) {
      return "AI analysis service is temporarily busy (API quota reached). Please wait a moment and try again.";
    }
    if (s.contains('SocketException') || s.contains('timeout') || s.contains('ClientException') || s.contains('ConnectError')) {
      return "Unable to connect to AI security service. Please check your internet connection.";
    }
    return s.replaceFirst(RegExp(r'^Exception:\s*'), '').replaceFirst(RegExp(r'^Analysis failed:\s*'), '');
  }

  static Future<Map<String, dynamic>> startSmsAnalysis(String msg) {
    smsInput = msg;
    smsLoading = true;
    smsResult = null;
    final future = ApiService.detectSpam(msg).then((res) {
      smsLoading = false;
      smsResult = res;
      return res;
    }).catchError((err) {
      smsLoading = false;
      final safe = {'success': false, 'message': sanitizeMessage(err)};
      smsResult = safe;
      return safe;
    });
    smsFuture = future;
    return future;
  }

  static Future<Map<String, dynamic>> startEmailAnalysis(String text) {
    emailInput = text;
    emailLoading = true;
    emailResult = null;
    final future = ApiService.analyzeEmailPhishing(text).then((res) {
      emailLoading = false;
      emailResult = res;
      return res;
    }).catchError((err) {
      emailLoading = false;
      final safe = {'success': false, 'message': sanitizeMessage(err)};
      emailResult = safe;
      return safe;
    });
    emailFuture = future;
    return future;
  }

  static Future<Map<String, dynamic>> startPasswordAnalysis(String pwd) {
    passwordInput = pwd;
    passwordLoading = true;
    passwordResult = null;
    passwordErrorMessage = null;
    passwordErrorStatusCode = null;
    final future = ApiService.analyzePassword(pwd).then((res) {
      passwordLoading = false;
      if (res['success'] == true) {
        passwordResult = res;
        passwordErrorMessage = null;
        passwordErrorStatusCode = null;
      } else {
        passwordResult = null;
        passwordErrorMessage = sanitizeMessage(res['message'] ?? "Analysis failed.");
        passwordErrorStatusCode = res['statusCode'] as int? ?? 500;
      }
      return res;
    }).catchError((err) {
      passwordLoading = false;
      passwordResult = null;
      final msg = sanitizeMessage(err);
      passwordErrorMessage = msg;
      passwordErrorStatusCode = 500;
      return {'success': false, 'message': msg, 'statusCode': 500};
    });
    passwordFuture = future;
    return future;
  }

  static Future<Map<String, dynamic>> startQrScan({
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) {
    qrLoading = true;
    qrResult = null;
    qrErrorMessage = null;
    final future = ApiService.scanQrImage(
      filePath: filePath,
      fileBytes: fileBytes,
      fileName: fileName ?? 'qr_image.png',
    ).then((res) {
      qrLoading = false;
      if (res['success'] == true) {
        qrResult = {
          'url': res['url']?.toString() ?? 'None',
          'classification': res['classification']?.toString() ?? '❌ QR Code not detected.',
        };
        qrErrorMessage = null;
      } else {
        qrResult = null;
        qrErrorMessage = sanitizeMessage(res['message'] ?? "QR scanning failed. Please try a clearer QR image.");
      }
      return res;
    }).catchError((err) {
      qrLoading = false;
      qrResult = null;
      final msg = sanitizeMessage(err);
      qrErrorMessage = msg;
      return {'success': false, 'message': msg};
    });
    qrFuture = future;
    return future;
  }

  static Future<Map<String, dynamic>> startAnomalyPrediction(int hour, double score) {
    anomalyHour = hour.toString();
    anomalyScore = score.toString();
    anomalyLoading = true;
    anomalyResult = null;
    anomalyErrorMessage = null;
    final future = ApiService.predictAnomaly(hour, score).then((res) {
      anomalyLoading = false;
      if (res['success'] == true) {
        anomalyResult = res;
        anomalyErrorMessage = null;
      } else {
        anomalyResult = null;
        anomalyErrorMessage = sanitizeMessage(res['message'] ?? "Prediction failed.");
      }
      return res;
    }).catchError((err) {
      anomalyLoading = false;
      anomalyResult = null;
      final msg = sanitizeMessage(err);
      anomalyErrorMessage = msg;
      return {'success': false, 'message': msg};
    });
    anomalyFuture = future;
    return future;
  }

  /// Clears all cached in-flight and result states (e.g. on user logout).
  static void clear() {
    smsInput = null;
    smsResult = null;
    smsLoading = false;
    smsFuture = null;

    emailInput = null;
    emailResult = null;
    emailLoading = false;
    emailFuture = null;

    qrBytes = null;
    qrFileName = null;
    qrFilePath = null;
    qrResult = null;
    qrErrorMessage = null;
    qrLoading = false;
    qrFuture = null;

    passwordInput = null;
    passwordResult = null;
    passwordErrorMessage = null;
    passwordErrorStatusCode = null;
    passwordLoading = false;
    passwordFuture = null;

    anomalyHour = null;
    anomalyScore = null;
    anomalyResult = null;
    anomalyErrorMessage = null;
    anomalyLoading = false;
    anomalyFuture = null;
  }
}
