import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

class ResultScreen extends StatefulWidget {
  final String imagePath;

  const ResultScreen({super.key, required this.imagePath});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isAnalyzing = true;
  String _quality = '';
  double _score = 0.0;
  String _errorMessage = '';
  bool _hasError = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    try {
      // In a real application, you would load the TFLite model here
      // For example:
      // final modelFile = await getModelFile();
      // final labelsFile = await getLabelsFile();
      // if (!File(modelFile).existsSync() || !File(labelsFile).existsSync()) {
      //   throw Exception("Model files not found");
      // }

      // Simulate the model loading and processing time
      await Future.delayed(const Duration(seconds: 2));

      // For demo purposes, generate a random quality score
      // In a real app, this would come from the TensorFlow model
      final random = math.Random();
      final randomScore =
          0.5 + random.nextDouble() * 0.5; // Between 0.5 and 1.0

      String qualityLabel;
      if (randomScore > 0.8) {
        qualityLabel = 'Tốt';
      } else if (randomScore > 0.6) {
        qualityLabel = 'Trung bình';
      } else {
        qualityLabel = 'Kém';
      }

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _quality = qualityLabel;
          _score = randomScore;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _hasError = true;
          _errorMessage = 'Lỗi phân tích: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _saveImageToGallery() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Kiểm tra xem file có tồn tại không
      final File imageFile = File(widget.imagePath);
      if (!imageFile.existsSync()) {
        throw Exception('Không tìm thấy file ảnh');
      }

      // Yêu cầu quyền lưu trữ
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Cần cấp quyền lưu trữ để lưu ảnh');
      }

      // Lấy thư mục Downloads hoặc Pictures
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('Không thể truy cập thư mục lưu trữ');
      }

      // Tạo tên file dựa trên thời gian
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = path.join(
        directory.path,
        'orange_quality_$timestamp.jpg',
      );

      // Sao chép file ảnh vào vị trí mới
      await imageFile.copy(newPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã lưu ảnh thành công vào: $newPath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra nếu file có tồn tại
    final imageFile = File(widget.imagePath);
    final bool fileExists = imageFile.existsSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả phân tích'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Image preview
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child:
                  fileExists
                      ? Image.file(imageFile, fit: BoxFit.contain)
                      : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Không thể tải hình ảnh',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
          ),

          // Results section
          Expanded(
            flex: 2,
            child:
                _isAnalyzing
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.orange),
                          SizedBox(height: 16),
                          Text('Đang phân tích chất lượng quả cam...'),
                        ],
                      ),
                    )
                    : _hasError
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Quay lại'),
                            ),
                          ],
                        ),
                      ),
                    )
                    : Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kết quả phân tích:',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Quality result
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(26),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Chất lượng:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _quality,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            _quality == 'Tốt'
                                                ? Colors.green
                                                : _quality == 'Trung bình'
                                                ? Colors.orange
                                                : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Quality score bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: _score,
                                    minHeight: 12,
                                    backgroundColor: Colors.grey.shade300,
                                    color:
                                        _score > 0.8
                                            ? Colors.green
                                            : _score > 0.5
                                            ? Colors.orange
                                            : Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${(_score * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Chụp lại'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed:
                                      _isSaving ? null : _saveImageToGallery,
                                  icon:
                                      _isSaving
                                          ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                          : const Icon(Icons.save),
                                  label: Text(
                                    _isSaving ? 'Đang lưu...' : 'Lưu ảnh',
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
