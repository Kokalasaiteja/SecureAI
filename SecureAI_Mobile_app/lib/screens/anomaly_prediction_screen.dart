import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import '../widgets/constellation_background.dart';
import '../widgets/app_drawer.dart';
import '../services/api_service.dart';
import '../widgets/secure_ai_app_bar.dart';

class AnomalyPredictionScreen extends StatefulWidget {
  const AnomalyPredictionScreen({super.key});

  @override
  State<AnomalyPredictionScreen> createState() => _AnomalyPredictionScreenState();
}

class _AnomalyPredictionScreenState extends State<AnomalyPredictionScreen> {
  final _hourController = TextEditingController();
  final _scoreController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _predictionResult;
  String? _errorMessage;

  @override
  void deactivate() {
    // When navigating to next page or another screen, clear written text and response
    _hourController.clear();
    _scoreController.clear();
    _predictionResult = null;
    _errorMessage = null;
    super.deactivate();
  }

  @override
  void dispose() {
    _hourController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _predict() async {
    final hourStr = _hourController.text.trim();
    final scoreStr = _scoreController.text.trim();
    if (hourStr.isEmpty || scoreStr.isEmpty) {
      setState(() {
        _errorMessage = "Please fill in both login hour and IP score.";
      });
      return;
    }

    final hour = int.tryParse(hourStr);
    final score = double.tryParse(scoreStr);

    if (hour == null || hour < 0 || hour > 23) {
      setState(() {
        _errorMessage = "Login hour must be an integer between 0 and 23.";
      });
      return;
    }

    if (score == null || score < 0.0 || score > 1.0) {
      setState(() {
        _errorMessage = "IP score must be a number between 0.0 and 1.0.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _predictionResult = null;
    });

    final res = await ApiService.predictAnomaly(hour, score);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (res['success'] == true) {
        _predictionResult = res;
      } else {
        _errorMessage = res['message']?.toString() ?? "Prediction failed.";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String predictionText = _predictionResult?['prediction']?.toString() ?? '';
    final bool isAnomaly = _predictionResult?['is_anomaly'] == true ||
        predictionText.toLowerCase() == 'anomaly';

    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/anomaly_prediction'),
      appBar: SecureAIAppBar.user(title: "SecureAI Panel"),
      body: ConstellationBackground(
        gradientColors: const [
          Color(0xFF6366F1), // from-indigo-500
          Color(0xFF3B82F6), // via-blue-500
          Color(0xFF06B6D4), // to-cyan-500
        ],
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon matching predict_anomaly.html
                  Image.network(
                    "https://cdn-icons-png.flaticon.com/512/3064/3064197.png",
                    width: 72,
                    height: 72,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.security_rounded,
                      color: Color(0xFF3B82F6),
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Title matching predict_anomaly.html
                  const Text(
                    "Predict User Behavior Anomaly",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtitle matching predict_anomaly.html
                  const Text(
                    "Use AI to detect suspicious login patterns.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE5E7EB),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Error notice if any
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFFFECACA), fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Field 1: Login Hour (0 - 23):
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Login Hour (0 - 23):",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827), // bg-gray-900
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF4B5563)), // border-gray-600
                    ),
                    child: TextField(
                      controller: _hourController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: "e.g. 3",
                        hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Field 2: IP Score (0.0 - 1.0):
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "IP Score (0.0 - 1.0):",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827), // bg-gray-900
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF4B5563)), // border-gray-600
                    ),
                    child: TextField(
                      controller: _scoreController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: "e.g. 0.85",
                        hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Button: Predict (Teal bg-teal-600)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _predict,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488), // bg-teal-600
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                            )
                          : const Text(
                              "Predict",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  // Result display matching predict_anomaly.html
                  if (_predictionResult != null) ...[
                    const SizedBox(height: 22),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xF0111827), // bg-gray-900 bg-opacity-90
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isAnomaly ? const Color(0xFFF43F5E) : const Color(0xFF14B8A6),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isAnomaly ? const Color(0xFFF43F5E) : const Color(0xFF14B8A6))
                                .withValues(alpha: 0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isAnomaly ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                            color: isAnomaly ? const Color(0xFFF43F5E) : const Color(0xFF14B8A6),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "🔍 Predicted Behavior: ",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            predictionText,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: isAnomaly ? const Color(0xFFFDE047) : const Color(0xFF5EEAD4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
