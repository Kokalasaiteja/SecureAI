import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/app_drawer.dart';
import '../services/api_service.dart';

class TrainModelScreen extends StatefulWidget {
  const TrainModelScreen({super.key});

  @override
  State<TrainModelScreen> createState() => _TrainModelScreenState();
}

class _TrainModelScreenState extends State<TrainModelScreen> {
  bool _isTraining = false;
  String? _statusMessage;

  Future<void> _startTraining() async {
    setState(() {
      _isTraining = true;
      _statusMessage = null;
    });

    final res = await ApiService.trainModels();

    setState(() {
      _isTraining = false;
      _statusMessage = res['message'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/train_models'),
      appBar: AppBar(title: const Text("Train ML Models")),
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
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppTheme.accentPink.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.accentPink.withOpacity(0.5)),
                        ),
                        child: const Icon(Icons.psychology_rounded, color: AppTheme.accentPink, size: 36),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "AI Model Retraining Console",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Trains Random Forest, XGBoost, and Logistic Regression on latest anomaly datasets.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _isTraining ? null : _startTraining,
                          icon: _isTraining
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.model_training_rounded),
                          label: Text(_isTraining ? "Training Models..." : "Trigger Model Retraining"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentPink,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (_statusMessage != null)
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppTheme.accentGreen, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _statusMessage!,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
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
