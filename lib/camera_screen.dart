import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  bool _isCameraPermissionGranted = false;
  bool _isCameraInitialized = false;
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCapturing = false;
  int _selectedCameraIndex = 0;
  FlashMode _flashMode = FlashMode.auto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Quản lý vòng đời của camera khi ứng dụng chuyển trạng thái
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera(_selectedCameraIndex);
    }
  }

  Future<void> _requestPermissions() async {
    try {
      // Yêu cầu quyền camera
      final cameraPermission = await Permission.camera.request();

      // Yêu cầu quyền lưu trữ cho Android
      await [Permission.storage, Permission.photos].request();

      // Kiểm tra quyền truy cập camera
      final cameras = await availableCameras();
      setState(() {
        _isCameraPermissionGranted =
            cameras.isNotEmpty && cameraPermission.isGranted;
      });

      if (_isCameraPermissionGranted) {
        await _initializeCamera(0);
      }
    } catch (e) {
      debugPrint('Lỗi yêu cầu quyền: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi yêu cầu quyền camera: $e')));
      }
    }
  }

  Future<void> _initializeCamera(int cameraIndex) async {
    try {
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        setState(() {
          _isCameraInitialized = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không tìm thấy camera nào trên thiết bị'),
            ),
          );
        }
        return;
      }

      if (cameraIndex >= _cameras.length) {
        cameraIndex = 0;
      }

      _selectedCameraIndex = cameraIndex;

      // Dispose controller trước khi khởi tạo
      await _cameraController?.dispose();

      _cameraController = CameraController(
        _cameras[cameraIndex],
        ResolutionPreset.medium, // Dùng medium để tương thích tốt hơn
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      try {
        await _cameraController!.initialize();
        // Khởi tạo flash mode
        await _setFlashMode(_flashMode);

        // Đảm bảo màn hình chưa bị hủy
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      } on CameraException catch (e) {
        debugPrint('Lỗi khởi tạo camera: ${e.code} - ${e.description}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khởi tạo camera: ${e.description}')),
          );
        }
      }
    } catch (e) {
      debugPrint('Lỗi tổng thể: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _setFlashMode(FlashMode mode) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      await _cameraController!.setFlashMode(mode);
      setState(() {
        _flashMode = mode;
      });
    } catch (e) {
      // Một số thiết bị có thể không hỗ trợ flash
      debugPrint('Lỗi đặt chế độ flash: $e');
    }
  }

  Future<void> _toggleFlashMode() async {
    // Chuyển đổi qua các chế độ flash
    FlashMode newMode;

    switch (_flashMode) {
      case FlashMode.off:
        newMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        newMode = FlashMode.always;
        break;
      case FlashMode.always:
        newMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        newMode = FlashMode.off;
        break;
    }

    await _setFlashMode(newMode);
  }

  Future<void> _switchCamera() async {
    final newIndex = (_selectedCameraIndex + 1) % _cameras.length;
    setState(() {
      _isCameraInitialized = false; // Hiển thị loading
    });
    await _initializeCamera(newIndex);
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Camera chưa sẵn sàng')));
      }
      return;
    }

    if (_isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final image = await _cameraController!.takePicture();

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(imagePath: image.path),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi chụp ảnh: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  // Lấy biểu tượng thích hợp cho chế độ flash hiện tại
  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.highlight;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraPermissionGranted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Kiểm tra chất lượng cam'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.no_photography, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Cần cấp quyền camera để sử dụng ứng dụng',
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _requestPermissions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'CẤP QUYỀN',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isCameraInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Kiểm tra chất lượng cam'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.orange),
              SizedBox(height: 16),
              Text('Đang khởi tạo camera...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chụp ảnh quả cam'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // Camera Preview
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Center(child: CameraPreview(_cameraController!)),
                    ),
                  ),

                  // Grid overlay for better positioning
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange, width: 3),
                      ),
                      child: GridPaper(
                        color: Colors.orange.withAlpha(76),
                        divisions: 2,
                        subdivisions: 1,
                      ),
                    ),
                  ),

                  // Target circle in center
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.orange.withAlpha(204),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Loading indicator when capturing
                  if (_isCapturing)
                    Container(
                      color: Colors.black26,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.orange),
                      ),
                    ),
                ],
              ),
            ),

            // Caption
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black87,
              width: double.infinity,
              child: const Text(
                'Đặt quả cam ở chính giữa khung hình để có kết quả chính xác nhất',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),

            // Camera controls
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Camera switch button (if more than one camera)
                  _cameras.length > 1
                      ? IconButton.filled(
                        icon: const Icon(
                          Icons.flip_camera_ios,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: _switchCamera,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.orange.withAlpha(179),
                        ),
                      )
                      : const SizedBox(width: 40),

                  // Capture button
                  GestureDetector(
                    onTap: _isCapturing ? null : _captureImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: _isCapturing ? Colors.grey : Colors.orange,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withAlpha(128),
                            spreadRadius: 2,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Flash button
                  IconButton.filled(
                    icon: Icon(_getFlashIcon(), color: Colors.white, size: 28),
                    onPressed: _toggleFlashMode,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.orange.withAlpha(179),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
