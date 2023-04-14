import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _cameras = await availableCameras();
  runApp(const CameraApp());
}

class CameraApp extends StatefulWidget {
  const CameraApp({Key? key}) : super(key: key);

  @override
  State<CameraApp> createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = Future.value(null);
    initializeCameraController();
  }

  Future<void> initializeCameraController() async {
    Directory directory = await getApplicationDocumentsDirectory();
    _controller = CameraController(_cameras[0], ResolutionPreset.max);
    _initializeControllerFuture = _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {}); // Force refresh after initialization
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (_controller.value.isInitialized) {
                return CameraPreview(_controller);
              } else {
                return Center(child: CircularProgressIndicator());
              }
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.camera_alt),
          onPressed: () async {
            if (_initializeControllerFuture == null){
              return;
            }
            try {
              await _initializeControllerFuture;
              if(!_controller.value.isInitialized){
                // Show an error message if the preview stream is not initialized.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: Camera preview stream not initialized.')),
                );
                return;
              }
              final path = join(
                (await getTemporaryDirectory()).path,
                '${DateTime.now()}.png',
              );
              await _controller.takePicture();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CameraPreviewScreen(imagePath: path),
                ),
              );
            } catch (e) {
              print(e);
            }
          },
        ),
      ),
    );
  }
}

class CameraPreviewScreen extends StatelessWidget {
  final String imagePath;

  const CameraPreviewScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Preview')),
      body: Image.file(File(imagePath)),
    );
  }
}
