import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/glass_card.dart';
import '../widgets/constellation_background.dart';
import '../widgets/app_drawer.dart';
import '../widgets/secure_ai_app_bar.dart';
import '../services/api_service.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedFile;
  Uint8List? _selectedBytes;
  String? _selectedFileName;
  bool _isScanning = false;
  String? _errorMessage;
  Map<String, dynamic>? _scanResult;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedFile = File(picked.path);
          _selectedBytes = bytes;
          _selectedFileName = picked.name;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        if (source == ImageSource.camera) {
          _errorMessage = "Camera access denied or camera not available on this device. Please use 'Upload from Gallery'.";
        } else {
          _errorMessage = "Failed to select image from storage: $e";
        }
      });
    }
  }

  Future<void> _scanAndClassify() async {
    if (_selectedFile == null && (_selectedBytes == null || _selectedBytes!.isEmpty)) {
      setState(() {
        _errorMessage = "Please take a camera photo or choose an image file to scan.";
      });
      return;
    }

    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _scanResult = null;
    });

    final res = await ApiService.scanQrImage(
      filePath: _selectedFile?.path,
      fileBytes: _selectedBytes,
      fileName: _selectedFileName ?? 'qr_image.png',
    );

    if (!mounted) return;

    if (res['success'] == true) {
      final String url = res['url']?.toString() ?? 'None';
      final String classification = res['classification']?.toString() ?? '❌ QR Code not detected.';

      setState(() {
        _isScanning = false;
        _scanResult = {
          'url': url,
          'classification': classification,
        };
      });
    } else {
      setState(() {
        _isScanning = false;
        _errorMessage = res['message']?.toString() ?? "QR scanning failed. Please try a clearer QR image.";
      });
    }
  }

  void _resetScanner() {
    setState(() {
      _scanResult = null;
      _selectedFile = null;
      _selectedBytes = null;
      _selectedFileName = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/qr_scanner'),
      appBar: SecureAIAppBar.user(title: "SecureAI Panel"),
      body: ConstellationBackground(
        gradientColors: const [
          Color(0xFFA855F7), // from-purple-500
          Color(0xFFD946EF), // via-fuchsia-500
          Color(0xFFEC4899), // to-pink-500
        ],
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: _scanResult != null ? _buildResultView() : _buildFormView(),
          ),
        ),
      ),
    );
  }

  // --- FORM VIEW ---
  Widget _buildFormView() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Flaticon QR Icon
          Image.network(
            "https://cdn-icons-png.flaticon.com/512/888/888879.png",
            width: 72,
            height: 72,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF97316).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFFF97316), size: 40),
            ),
          ),
          const SizedBox(height: 14),

          // Title
          const Text(
            "📸 QR Code Classifier",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle
          const Text(
            "Powered by Gemini + LangChain for threat detection",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFE5E7EB),
            ),
          ),
          const SizedBox(height: 24),

          // Error box if any
          if (_errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFFCA5A5), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Camera vs Upload Action Cards
          Row(
            children: [
              // Option 1: Live Camera Photo
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _pickImage(ImageSource.camera),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF818CF8).withValues(alpha: 0.5), width: 1.2),
                      ),
                      child: Column(
                        children: const [
                          Icon(Icons.camera_alt_rounded, color: Color(0xFF818CF8), size: 30),
                          SizedBox(height: 8),
                          Text(
                            "Live Camera",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Capture live photo",
                            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Option 2: Upload from Storage / Gallery
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _pickImage(ImageSource.gallery),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2DD4BF).withValues(alpha: 0.5), width: 1.2),
                      ),
                      child: Column(
                        children: const [
                          Icon(Icons.photo_library_rounded, color: Color(0xFF2DD4BF), size: 30),
                          SizedBox(height: 8),
                          Text(
                            "Upload Image",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "From device gallery",
                            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Preview Thumbnail if chosen
          if (_selectedBytes != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2DD4BF).withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedFileName ?? "Selected QR Image",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _resetScanner,
                        icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFF87171)),
                        label: const Text(
                          "Remove",
                          style: TextStyle(color: Color(0xFFF87171), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 140,
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2DD4BF), width: 2),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.memory(_selectedBytes!, fit: BoxFit.contain),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Scan & Classify Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isScanning ? null : _scanAndClassify,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488), // bg-teal-600
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              child: _isScanning
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                    )
                  : const Text(
                      "Scan & Classify",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // --- RESULT VIEW ---
  Widget _buildResultView() {
    final url = _scanResult!['url']?.toString() ?? 'None';
    final classification = _scanResult!['classification']?.toString() ?? '';

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Result Icon
          Image.network(
            "https://cdn-icons-png.flaticon.com/512/2910/2910791.png",
            width: 76,
            height: 76,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF2DD4BF),
              size: 72,
            ),
          ),
          const SizedBox(height: 18),

          // Result Title
          const Text(
            "✅ QR Code Scan Result",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // Decoded URL
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(fontSize: 16, color: Colors.white),
              children: [
                const TextSpan(
                  text: "🔗 URL: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: url,
                  style: const TextStyle(
                    color: Color(0xFFFDE047), // text-yellow-300
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Classification
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(fontSize: 16, color: Colors.white),
              children: [
                const TextSpan(
                  text: "🔎 Classification: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: classification,
                  style: const TextStyle(
                    color: Color(0xFFFDE047), // text-yellow-300
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Scan Another Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _resetScanner,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488), // bg-teal-600
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              child: const Text(
                "🔁 Scan Another",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
