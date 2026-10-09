import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Primary production API endpoint deployed on Render
  static const String liveBaseUrl = "https://secureai-7wgj.onrender.com";
  // Local fallback endpoint for development
  static const String localBaseUrl = "http://127.0.0.1:8000";

  static String _activeBaseUrl = liveBaseUrl;
  static String? _sessionCookie;

  static String get activeBaseUrl => _activeBaseUrl;

  static void setBaseUrl(String url) {
    _activeBaseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static Future<void> initSession() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionCookie = prefs.getString('session_cookie');
    final savedUrl = prefs.getString('custom_base_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _activeBaseUrl = savedUrl;
    }
  }

  static Future<void> _saveSessionCookie(http.Response response) async {
    final rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      // Extract sessionid or full cookie header
      final cookies = rawCookie.split(',');
      for (var cookie in cookies) {
        if (cookie.contains('sessionid=') || cookie.contains('csrftoken=')) {
          _sessionCookie = cookie.split(';')[0];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('session_cookie', _sessionCookie!);
        }
      }
    }
  }

  static Map<String, String> _getHeaders({Map<String, String>? extraHeaders}) {
    final headers = <String, String>{
      'Accept': 'application/json, text/html, */*',
    };
    if (_sessionCookie != null && _sessionCookie!.isNotEmpty) {
      headers['Cookie'] = _sessionCookie!;
    }
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  // --- AUTH APIs ---

  static Future<Map<String, dynamic>> userLogin(String name, String password) async {
    try {
      final uri = Uri.parse('$_activeBaseUrl/user-login/');
      final response = await http.post(
        uri,
        headers: _getHeaders(extraHeaders: {'Content-Type': 'application/x-www-form-urlencoded'}),
        body: {'name': name, 'password': password},
      );

      await _saveSessionCookie(response);

      if (response.statusCode == 200 || response.statusCode == 302) {
        if (response.body.contains("Invalid username or password") || response.body.contains("Wait for admin approval")) {
          return {'success': false, 'message': 'Invalid credentials or pending admin approval.'};
        }
        return {'success': true, 'message': 'Login successful!'};
      }
      return {'success': false, 'message': 'Login failed with status ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> register(String name, String email, String mobile, String password) async {
    try {
      final uri = Uri.parse('$_activeBaseUrl/register/');
      final response = await http.post(
        uri,
        headers: _getHeaders(extraHeaders: {'Content-Type': 'application/x-www-form-urlencoded'}),
        body: {
          'name': name,
          'email': email,
          'mobile': mobile,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        if (response.body.contains("already exist")) {
          return {'success': false, 'message': 'Username already exists. Please pick another.'};
        }
        return {'success': true, 'message': 'Registration successful! Awaiting admin approval.'};
      }
      return {'success': false, 'message': 'Registration failed.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> adminLogin(String name, String password) async {
    try {
      final uri = Uri.parse('$_activeBaseUrl/admin-login/');
      final response = await http.post(
        uri,
        headers: _getHeaders(extraHeaders: {'Content-Type': 'application/x-www-form-urlencoded'}),
        body: {'name': name, 'password': password},
      );

      await _saveSessionCookie(response);

      if (response.statusCode == 200 || response.statusCode == 302) {
        if (response.body.contains("Invalid admin credentials")) {
          return {'success': false, 'message': 'Invalid admin credentials.'};
        }
        return {'success': true, 'message': 'Admin login successful!'};
      }
      return {'success': false, 'message': 'Admin login failed.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<void> logout() async {
    try {
      final uri = Uri.parse('$_activeBaseUrl/user-logout/');
      await http.get(uri, headers: _getHeaders());
    } catch (_) {}
    _sessionCookie = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_cookie');
  }

  // --- AI ANALYSIS APIs ---

  static Future<Map<String, dynamic>> detectSpam(String message) async {
    try {
      final uri = Uri.parse('$_activeBaseUrl/detect_spam/');
      final response = await http.post(
        uri,
        headers: _getHeaders(extraHeaders: {'Content-Type': 'application/x-www-form-urlencoded'}),
        body: {'message': message},
      );

      if (response.statusCode == 200) {
        final body = response.body;
        bool isSpam = body.contains('Spam') || body.contains('SPAM');
        return {
          'success': true,
          'result': isSpam ? 'Spam' : 'Ham (Safe)',
          'is_spam': isSpam,
          'body': body,
        };
      }
      return {'success': false, 'message': 'Detection failed'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> predictAnomaly(int loginHour, double ipScore) async {
    try {
      final uri = Uri.parse('$_activeBaseUrl/predict-anomaly/');
      final response = await http.post(
        uri,
        headers: _getHeaders(extraHeaders: {'Content-Type': 'application/x-www-form-urlencoded'}),
        body: {
          'login_hour': loginHour.toString(),
          'ip_score': ipScore.toString(),
        },
      );

      if (response.statusCode == 200) {
        final body = response.body;
        bool isAnomaly = body.contains('Anomaly') || body.contains('ANOMALY');
        return {
          'success': true,
          'prediction': isAnomaly ? 'Anomaly Detected' : 'Normal Activity',
          'is_anomaly': isAnomaly,
          'raw_response': body,
        };
      }
      return {'success': false, 'message': 'Prediction failed'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> analyzePassword(String password) async {
    try {
      final uri = Uri.parse('$_activeBaseUrl/password-analyzer/');
      final response = await http.post(
        uri,
        headers: _getHeaders(extraHeaders: {'Content-Type': 'application/x-www-form-urlencoded'}),
        body: {'password': password},
      );

      if (response.statusCode == 200) {
        final body = response.body;
        return {
          'success': true,
          'length': password.length,
          'is_moderate': body.contains('Moderate'),
          'is_strong': body.contains('Strong'),
          'is_weak': body.contains('Weak'),
          'body': body,
        };
      }
      return {'success': false, 'message': 'Analysis failed'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> analyzeEmailPhishing(String emailText) async {
    try {
      final uri = Uri.parse('$_activeBaseUrl/email-phishing/');
      final response = await http.post(
        uri,
        headers: _getHeaders(extraHeaders: {'Content-Type': 'application/x-www-form-urlencoded'}),
        body: {'email_text': emailText},
      );

      if (response.statusCode == 200) {
        final body = response.body;
        bool isPhishing = body.contains('Phishing') || body.contains('PHISHING');
        return {
          'success': true,
          'is_phishing': isPhishing,
          'result': isPhishing ? 'Phishing Attempt Flagged' : 'Legitimate Email',
          'body': body,
        };
      }
      return {'success': false, 'message': 'Phishing analysis failed'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> trainModels() async {
    try {
      final uri = Uri.parse('$_activeBaseUrl/train-anomaly-model/');
      final response = await http.get(uri, headers: _getHeaders());
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'ML Models trained successfully!'};
      }
      return {'success': false, 'message': 'Training failed'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
