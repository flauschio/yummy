import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YOLO Realtime Detection',
      theme: ThemeData.dark(),
      home: const YOLODetection(),
    );
  }
}

class YOLODetection extends StatefulWidget {
  const YOLODetection({super.key});

  @override
  State<YOLODetection> createState() => _YOLODetectionState();
}

class _YOLODetectionState extends State<YOLODetection> {
  List<YOLOResult> _detections = [];
  double _fps = 0;
  final FlutterTts _tts = FlutterTts();
  DateTime _lastYummyAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _isSpeaking = false;

  static const Set<String> _yummyClasses = {
    'cup',
    'apple',
    'banana',
    'orange',
    'sandwich',
    'pizza',
    'donut',
    'cake',
    'hot dog',
    'broccoli',
    'carrot',
    'bowl',
  };

  static const Duration _yummyCooldown = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _configureTts();
  }

  Future<void> _configureTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() {
      _isSpeaking = true;
    });
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
    });
    _tts.setCancelHandler(() {
      _isSpeaking = false;
    });
    _tts.setErrorHandler((_) {
      _isSpeaking = false;
    });
  }

  Future<void> _trySayYummy(List<YOLOResult> results) async {
    final now = DateTime.now();
    if (_isSpeaking || now.difference(_lastYummyAt) < _yummyCooldown) {
      return;
    }

    final hasYummyObject = results.any(
      (result) => _yummyClasses.contains(result.className.toLowerCase()),
    );

    if (!hasYummyObject) return;

    _lastYummyAt = now;
    await _tts.speak('yummy!');
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black54,
        title: Text('${_detections.length} objects'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '${_fps.toStringAsFixed(1)} FPS',
                style: const TextStyle(color: Colors.greenAccent),
              ),
            ),
          ),
        ],
      ),
      body: YOLOView(
        modelPath: 'assets/models/yolo11n_int8.tflite',
        confidenceThreshold: 0.5,
        lensFacing: LensFacing.back,
        showOverlays: true,
        onResult: (results) {
          setState(() => _detections = results);
          _trySayYummy(results);
        },
        onPerformanceMetrics: (metrics) {
          setState(() => _fps = metrics.fps);
        },
      ),
    );
  }
}