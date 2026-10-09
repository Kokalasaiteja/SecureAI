import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/app_drawer.dart';
import '../services/api_service.dart';

class AnomalyPredictionScreen extends StatefulWidget {
  const AnomalyPredictionScreen({super.key});

  @override
  State<AnomalyPredictionScreen> createState() => _AnomalyPredictionScreenState();
}

class _AnomalyPredictionScreenState extends State<AnomalyPredictionScreen> {
  final _hourController = TextEditingController(text: "3");
  final _scoreController = TextEditingController(text: "85.5");
  bool _isLoading = false;
  Map<String, dynamic>? _predictionResult;

  Future<void> _predict() async {
    final hourStr = _hourController.text.trim();
    final scoreStr = _scoreController.text.trim();
    if (hourStr.isEmpty || scoreStr.isEmpty) return;

    final hour = int.tryParse(hourStr) ?? 0;
    final score = double.tryParse(scoreStr) ?? 0.0;

    setState(() {
      _isLoading = true;
      _predictionResult = null;
    });

    final res = await ApiService.predictAnomaly(hour, score);

    setState(() {
      _isLoading = false;
      _predictionResult = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/anomaly_prediction'),
      appBar: AppBar(title: const Text("Behavior Anomaly Predictor")),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.person_search_rounded, color: AppTheme.primaryIndigo, size: 28),
                          SizedBox(width: 12),
                          Text(
                            "ML Anomaly Sentry",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Random Forest classifier trained on login hour and IP threat score parameters to detect unauthorized login behavior.",
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                      const SizedBox(height: 20),

                      CustomTextField(
                        controller: _hourController,
                        label: "Login Hour (0 - 23)",
                        hint: "e.g., 3 for 3 AM",
                        icon: Icons.access_time_filled_rounded,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _scoreController,
                        label: "IP Threat Score (0.0 - 100.0)",
                        hint: "e.g., 85.5",
                        icon: Icons.speed_rounded,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _predict,
                          icon: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.analytics_rounded),
                          label: Text(_isLoading ? "Evaluating..." : "Run ML Anomaly Prediction"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryIndigo,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (_predictionResult != null)
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    borderColor: (_predictionResult!['is_anomaly'] == true) ? AppTheme.accentRed : AppTheme.accentGreen,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              (_predictionResult!['is_anomaly'] == true) ? Icons.error_rounded : Icons.check_circle_rounded,
                              color: (_predictionResult!['is_anomaly'] == true) ? AppTheme.accentRed : AppTheme.accentGreen,
                              size: 30,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _predictionResult!['prediction'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: (_predictionResult!['is_anomaly'] == true) ? AppTheme.accentRed : AppTheme.accentGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 8),
                        Text(
                          _predictionResult!['raw_response'] ?? "Processed by Random Forest Model.",
                          style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
