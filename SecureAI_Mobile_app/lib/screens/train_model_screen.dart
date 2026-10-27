import 'package:flutter/material.dart';
import '../widgets/copyright_footer.dart';
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
                const CopyrightFooter(),
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

          // Structured Classification Metrics Table
          _buildClassificationTable(report, tn: tn, fp: fp, fn: fn, tp: tp),
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

  Widget _buildClassificationTable(String report, {int tn = 0, int fp = 0, int fn = 0, int tp = 0}) {
    final List<Map<String, String>> rows = [];

    final lines = report
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    for (final line in lines) {
      if (line.toLowerCase().contains('precision') && line.toLowerCase().contains('recall')) {
        continue; // Skip header line
      }

      if (line.toLowerCase().contains('accuracy')) {
        final matches = RegExp(r'[\d\.]+').allMatches(line).map((m) => m.group(0)!).toList();
        if (matches.length >= 2) {
          rows.add({
            'class': 'Accuracy',
            'precision': '-',
            'recall': '-',
            'f1': matches[matches.length - 2],
            'support': matches.last,
            'isHighlight': 'true',
          });
        }
      } else if (line.toLowerCase().contains('macro avg')) {
        final matches = RegExp(r'[\d\.]+').allMatches(line).map((m) => m.group(0)!).toList();
        if (matches.length >= 4) {
          rows.add({
            'class': 'Macro Avg',
            'precision': matches[0],
            'recall': matches[1],
            'f1': matches[2],
            'support': matches[3],
            'isHighlight': 'false',
          });
        }
      } else if (line.toLowerCase().contains('weighted avg')) {
        final matches = RegExp(r'[\d\.]+').allMatches(line).map((m) => m.group(0)!).toList();
        if (matches.length >= 4) {
          rows.add({
            'class': 'Weighted Avg',
            'precision': matches[0],
            'recall': matches[1],
            'f1': matches[2],
            'support': matches[3],
            'isHighlight': 'false',
          });
        }
      } else {
        final matches = RegExp(r'[\d\.]+').allMatches(line).map((m) => m.group(0)!).toList();
        if (matches.length == 4) {
          final labelPart = line.split(RegExp(r'[\d\.]+')).first.trim();
          final label = labelPart.isNotEmpty ? labelPart : 'Class';
          rows.add({
            'class': label,
            'precision': matches[0],
            'recall': matches[1],
            'f1': matches[2],
            'support': matches[3],
            'isHighlight': 'false',
          });
        } else if (matches.length >= 5) {
          var label = matches[0];
          if (label == '0') label = 'Normal';
          if (label == '1') label = 'Anomaly';
          rows.add({
            'class': label,
            'precision': matches[1],
            'recall': matches[2],
            'f1': matches[3],
            'support': matches[4],
            'isHighlight': 'false',
          });
        }
      }
    }

    // Defensive Fallback: If raw text could not be parsed but we have confusion matrix counts, calculate exact metrics
    if (rows.isEmpty && (tn > 0 || tp > 0 || fp > 0 || fn > 0)) {
      final total = tn + fp + fn + tp;
      final nSupport = tn + fp;
      final aSupport = fn + tp;

      final normPrec = (tn + fn > 0) ? (tn / (tn + fn)) : 0.0;
      final normRec = (nSupport > 0) ? (tn / nSupport) : 0.0;
      final normF1 = (normPrec + normRec > 0) ? (2 * normPrec * normRec / (normPrec + normRec)) : 0.0;

      final anomPrec = (tp + fp > 0) ? (tp / (tp + fp)) : 0.0;
      final anomRec = (aSupport > 0) ? (tp / aSupport) : 0.0;
      final anomF1 = (anomPrec + anomRec > 0) ? (2 * anomPrec * anomRec / (anomPrec + anomRec)) : 0.0;

      final accuracy = (total > 0) ? ((tn + tp) / total) : 0.0;
      final macroPrec = (normPrec + anomPrec) / 2;
      final macroRec = (normRec + anomRec) / 2;
      final macroF1 = (normF1 + anomF1) / 2;

      final weightedPrec = (total > 0) ? ((normPrec * nSupport + anomPrec * aSupport) / total) : 0.0;
      final weightedRec = (total > 0) ? ((normRec * nSupport + anomRec * aSupport) / total) : 0.0;
      final weightedF1 = (total > 0) ? ((normF1 * nSupport + anomF1 * aSupport) / total) : 0.0;

      rows.add({
        'class': 'Normal',
        'precision': normPrec.toStringAsFixed(2),
        'recall': normRec.toStringAsFixed(2),
        'f1': normF1.toStringAsFixed(2),
        'support': nSupport.toString(),
        'isHighlight': 'false',
      });
      rows.add({
        'class': 'Anomaly',
        'precision': anomPrec.toStringAsFixed(2),
        'recall': anomRec.toStringAsFixed(2),
        'f1': anomF1.toStringAsFixed(2),
        'support': aSupport.toString(),
        'isHighlight': 'false',
      });
      rows.add({
        'class': 'Accuracy',
        'precision': '-',
        'recall': '-',
        'f1': accuracy.toStringAsFixed(2),
        'support': total.toString(),
        'isHighlight': 'true',
      });
      rows.add({
        'class': 'Macro Avg',
        'precision': macroPrec.toStringAsFixed(2),
        'recall': macroRec.toStringAsFixed(2),
        'f1': macroF1.toStringAsFixed(2),
        'support': total.toString(),
        'isHighlight': 'false',
      });
      rows.add({
        'class': 'Weighted Avg',
        'precision': weightedPrec.toStringAsFixed(2),
        'recall': weightedRec.toStringAsFixed(2),
        'f1': weightedF1.toStringAsFixed(2),
        'support': total.toString(),
        'isHighlight': 'false',
      });
    }

    if (rows.isEmpty) {
      if (report.trim().isEmpty) {
        return const SizedBox.shrink();
      }
      return Container(
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
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: const Color(0xFF1E293B),
            child: Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: Text(
                    "Metric",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Precision",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Recall",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "F1-Score",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2DD4BF)),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Support",
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),
          ),

          // Table Rows
          for (int i = 0; i < rows.length; i++) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              color: i.isOdd ? Colors.white.withValues(alpha: 0.02) : Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      rows[i]['class'] ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: rows[i]['isHighlight'] == 'true' ? FontWeight.bold : FontWeight.w600,
                        color: rows[i]['class'] == 'Anomaly'
                            ? const Color(0xFFFDA4AF)
                            : (rows[i]['class'] == 'Normal'
                                ? const Color(0xFF5EEAD4)
                                : Colors.white),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      rows[i]['precision'] ?? '-',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      rows[i]['recall'] ?? '-',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      rows[i]['f1'] ?? '-',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2DD4BF),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      rows[i]['support'] ?? '-',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ],
              ),
            ),
            if (i < rows.length - 1)
              const Divider(height: 1, thickness: 0.6, color: Color(0xFF1E293B)),
          ],
        ],
      ),
    );
  }

}
