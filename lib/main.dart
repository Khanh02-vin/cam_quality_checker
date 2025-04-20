import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'camera_screen.dart';

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orange Quality Checker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const CameraScreen(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _cameraAvailable = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkCameraAvailability();
  }

  Future<void> _checkCameraAvailability() async {
    final cameras = await availableCameras();
    final cameraPermission = await Permission.camera.request();

    setState(() {
      _cameraAvailable = cameras.isNotEmpty && cameraPermission.isGranted;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orange Quality Checker'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              )
              : _cameraAvailable
              ? const Center(
                child: Text('Camera is available! Ready to check oranges.'),
              )
              : const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.no_photography, size: 80, color: Colors.grey),
                      SizedBox(height: 20),
                      Text(
                        'Camera is not available on this device.',
                        style: TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'This app requires camera access to check orange quality. Please use a device with a camera or grant camera permissions.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
