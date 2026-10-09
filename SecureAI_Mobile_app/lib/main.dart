import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/verify_otp_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/spam_detector_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/anomaly_prediction_screen.dart';
import 'screens/password_analyzer_screen.dart';
import 'screens/email_phishing_screen.dart';
import 'screens/train_model_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/info_screens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SecureAIMobileApp());
}

class SecureAIMobileApp extends StatelessWidget {
  const SecureAIMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SecureAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/user_login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/admin_login': (context) => const AdminLoginScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/verify_otp': (context) => const VerifyOtpScreen(),
        '/reset_password': (context) => const ResetPasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/detect_spam': (context) => const SpamDetectorScreen(),
        '/qr_scanner': (context) => const QrScannerScreen(),
        '/anomaly_prediction': (context) => const AnomalyPredictionScreen(),
        '/password_analyzer': (context) => const PasswordAnalyzerScreen(),
        '/email_phishing': (context) => const EmailPhishingScreen(),
        '/train_models': (context) => const TrainModelScreen(),
        '/admin_dashboard': (context) => const AdminDashboardScreen(),
        '/introduction': (context) => const IntroductionScreen(),
        '/contact': (context) => const ContactScreen(),
      },
    );
  }
}
