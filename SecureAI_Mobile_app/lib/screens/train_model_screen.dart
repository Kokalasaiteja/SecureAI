import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import '../widgets/constellation_background.dart';
import '../widgets/app_drawer.dart';
import '../services/api_service.dart';
import '../widgets/secure_ai_app_bar.dart';

class TrainModelScreen extends StatefulWidget {
  const TrainModelScreen({super.key});

  @override
  State<TrainModelScreen> createState() => _TrainModelScreenState();
}

class _TrainModelScreenState extends State<TrainModelScreen> {
  bool _isLoading = true;
  bool _isRetraining = false;
  List<Map<String, dynamic>> _models = [];

  @override
  void initState() {
    super.initState();
    _loadTrainingResults();
  }

  Future<void> _loadTrainingResults() async {
    setState(() {
      _isLoading = true;
    });

    final res = await ApiService.trainModels();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (res['success'] == true && res['models'] != null) {
        _models = List<Map<String, dynamic>>.from(res['models']);
      }
    });
  }

  Future<void> _retrain() async {
    setState(() {
      _isRetraining = true;
    });

    final res = await ApiService.trainModels();

    if (!mounted) return;
    setState(() {
      _isRetraining = false;
      if (res['success'] == true && res['models'] != null) {
        _models = List<Map<String, dynamic>>.from(res['models']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Models retrained and synchronized successfully!"),
            backgroundColor: Color(0xFF0D9488),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/train_models'),
      appBar: SecureAIAppBar.user(title: "SecureAI Panel"),
      body: ConstellationBackground(
        gradientColors: const [
          Color(0xFFEC4899), // from-pink-500
          Color(0xFFF43F5E), // via-rose-500
          Color(0xFFEF4444), // to-red-500
        ],
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Back to Dashboard Button & Retrain Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacementNamed(context, '/home');
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14B8A6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF14B8A6), width: 1.5),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.arrow_back_rounded, color: Color(0xFF14B8A6), size: 16),
                            SizedBox(width: 6),
                            Text(
                              "Back to Dashboard",
                              style: TextStyle(
                                color: Color(0xFF14B8A6),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: _isRetraining
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded, color: Colors.white70),
                      tooltip: "Retrain Models",
                      onPressed: _isRetraining ? null : _retrain,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Page Title matching train_anomaly.html
                const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.insights_rounded, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "Behavior Anomaly Detection - Training Results",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Loading Indicator
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF14B8A6)),
                    ),
                  )
                else ...[
                  // Model blocks matching train_anomaly.html
                  for (final model in _models) ...[
                    _buildModelBlock(model),
                    const SizedBox(height: 16),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModelBlock(Map<String, dynamic> model) {
    final name = model['name']?.toString() ?? 'Model Classifier';
    final report = model['report']?.toString() ?? '';
    final tn = model['tn'] ?? 0;
    final fp = model['fp'] ?? 0;
    final fn = model['fn'] ?? 0;
    final tp = model['tp'] ?? 0;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Model Title
          Row(
            children: [
              const Icon(Icons.psychology_rounded, color: Color(0xFF14B8A6), size: 24),
              const SizedBox(width: 8),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF14B8A6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Pre Classification Report Block
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                report,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Confusion Matrix Header
          const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.grid_view_rounded, color: Color(0xFF14B8A6), size: 18),
                SizedBox(width: 6),
                Text(
                  "Confusion Matrix",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF14B8A6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2x2 Matrix Grid matching train_anomaly.html
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF111827).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF374151).withValues(alpha: 0.6)),
            ),
            child: Column(
              children: [
                // Top Header: Pred Normal, Pred Anomaly
                Row(
                  children: const [
                    Expanded(flex: 2, child: SizedBox.shrink()),
                    Expanded(
                      flex: 3,
                      child: Text(
                        "Pred Normal",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        "Pred Anomaly",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Row 1: Actual Normal -> TN and FP
                Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        "Actual Normal",
                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF134E4A).withValues(alpha: 0.75), // teal-900
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF14B8A6).withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "$tn",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFCCFBF1)),
                            ),
                            const Text(
                              "True Neg (TN)",
                              style: TextStyle(fontSize: 8, color: Color(0xFF5EEAD4), letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4C0519).withValues(alpha: 0.5), // rose-950
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF43F5E).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "$fp",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFECDD3)),
                            ),
                            const Text(
                              "False Pos (FP)",
                              style: TextStyle(fontSize: 8, color: Color(0xFFFDA4AF), letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Row 2: Actual Anomaly -> FN and TP
                Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        "Actual Anomaly",
                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4C0519).withValues(alpha: 0.5), // rose-950
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF43F5E).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "$fn",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFECDD3)),
                            ),
                            const Text(
                              "False Neg (FN)",
                              style: TextStyle(fontSize: 8, color: Color(0xFFFDA4AF), letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF134E4A).withValues(alpha: 0.75), // teal-900
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF14B8A6).withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "$tp",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFCCFBF1)),
                            ),
                            const Text(
                              "True Pos (TP)",
                              style: TextStyle(fontSize: 8, color: Color(0xFF5EEAD4), letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
