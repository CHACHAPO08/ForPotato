import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../database/database.dart' show MediaType;

/// 카메라 화면이 반환하는 촬영 결과.
/// today_diary_page의 _PickedMedia로 변환해서 사용한다.
class CameraCaptureResult {
  const CameraCaptureResult({
    required this.bytes,
    required this.mimeType,
    required this.type,
  });

  final Uint8List bytes;
  final String mimeType;
  final MediaType type;
}

/// Setlog / 인스타그램 스토리 스타일의 독자적인 카메라 화면.
///
/// 내부적으로는 `camera` 패키지(웹에서는 camera_web이 자동으로 연결되어
/// getUserMedia / MediaRecorder를 감싼다)를 사용해서, 사진 촬영과
/// 최대 [maxVideoSeconds]초 영상 촬영을 하나의 화면에서 지원한다.
///
/// 주의: 촬영 직후 미리보기는 XFile.path(웹에서는 blob: URL)를 그대로
/// Image.network / VideoPlayerController.networkUrl에 넘기는 방식으로 구현했다.
/// 이 프로젝트는 현재 PWA(`flutter build web`)만 타겟팅하므로 이 방식으로 충분하며,
/// 추후 네이티브 iOS/Android 빌드를 다시 고려한다면 dart:io File 기반 분기가 필요하다.
class CameraCapturePage extends StatefulWidget {
  const CameraCapturePage({super.key, this.maxVideoSeconds = 10});

  final int maxVideoSeconds;

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

enum _CaptureMode { photo, video }

class _CameraCapturePageState extends State<CameraCapturePage> {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  CameraLensDirection _lensDirection = CameraLensDirection.back;
  _CaptureMode _mode = _CaptureMode.photo;

  bool _initializing = true;
  String? _error;

  bool _isRecording = false;
  int _elapsedSec = 0;
  Timer? _tickTimer;
  Timer? _autoStopTimer;

  XFile? _capturedFile;
  VideoPlayerController? _previewController;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _error = '사용 가능한 카메라를 찾을 수 없습니다.';
          _initializing = false;
        });
        return;
      }
      await _openCamera(_lensDirection);
    } catch (e) {
      setState(() {
        _error = _friendlyError(e);
        _initializing = false;
      });
    }
  }

  Future<void> _openCamera(CameraLensDirection direction) async {
    setState(() => _initializing = true);
    await _controller?.dispose();

    final description = _cameras.firstWhere(
      (c) => c.lensDirection == direction,
      orElse: () => _cameras.first,
    );

    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: _mode == _CaptureMode.video,
    );

    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _lensDirection = direction;
        _initializing = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
        _initializing = false;
      });
    }
  }

  String _friendlyError(Object e) {
    final message = e.toString();
    if (message.contains('NotAllowedError') || message.contains('Permission')) {
      return '카메라 권한이 거부되었습니다. 브라우저 설정에서 카메라 접근을 허용해주세요.';
    }
    if (message.contains('NotFoundError')) {
      return '사용 가능한 카메라를 찾을 수 없습니다.';
    }
    return '카메라를 사용하는 중 오류가 발생했습니다.\n($message)';
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isRecording) return;
    final next = _lensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    await _openCamera(next);
  }

  Future<void> _setMode(_CaptureMode mode) async {
    if (_mode == mode || _isRecording) return;
    setState(() => _mode = mode);
    // 사진↔영상 전환 시 오디오 트랙 유무가 달라지므로 컨트롤러를 다시 연다.
    await _openCamera(_lensDirection);
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      final file = await controller.takePicture();
      await _showPreview(file);
    } catch (e) {
      setState(() => _error = _friendlyError(e));
    }
  }

  Future<void> _startRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      await controller.startVideoRecording();
      setState(() {
        _isRecording = true;
        _elapsedSec = 0;
      });

      _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsedSec++);
      });
      // maxVideoSeconds에 도달하면 자동으로 정지한다.
      _autoStopTimer = Timer(
        Duration(seconds: widget.maxVideoSeconds),
        _stopRecording,
      );
    } catch (e) {
      setState(() => _error = _friendlyError(e));
    }
  }

  Future<void> _stopRecording() async {
    final controller = _controller;
    if (controller == null || !_isRecording) return;
    _tickTimer?.cancel();
    _autoStopTimer?.cancel();
    try {
      final file = await controller.stopVideoRecording();
      if (!mounted) return;
      setState(() => _isRecording = false);
      await _showPreview(file);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _error = _friendlyError(e);
      });
    }
  }

  Future<void> _showPreview(XFile file) async {
    setState(() => _capturedFile = file);
    if (_mode == _CaptureMode.video) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(file.path));
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (!mounted) return;
      setState(() => _previewController = controller);
    }
  }

  void _retake() {
    _previewController?.dispose();
    setState(() {
      _previewController = null;
      _capturedFile = null;
    });
  }

  Future<void> _confirm() async {
    final file = _capturedFile;
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final mimeType =
        file.mimeType ?? (_mode == _CaptureMode.photo ? 'image/jpeg' : 'video/mp4');

    if (!mounted) return;
    Navigator.of(context).pop(
      CameraCaptureResult(
        bytes: bytes,
        mimeType: mimeType,
        type: _mode == _CaptureMode.photo ? MediaType.photo : MediaType.video,
      ),
    );
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _autoStopTimer?.cancel();
    _previewController?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _capturedFile != null ? _buildPreview() : _buildCamera(),
      ),
    );
  }

  Widget _buildCamera() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('닫기'),
              ),
            ],
          ),
        ),
      );
    }
    if (_initializing || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(child: CameraPreview(_controller!)),

        if (_isRecording)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '● REC $_elapsedSec/${widget.maxVideoSeconds}s',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ),

        Positioned(
          bottom: 110,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _modeChip('사진', _CaptureMode.photo),
                  _modeChip('영상(최대 ${widget.maxVideoSeconds}초)', _CaptureMode.video),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed:
                    _cameras.length > 1 && !_isRecording ? _switchCamera : null,
                icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 28),
              ),
              GestureDetector(
                onTap: _mode == _CaptureMode.photo
                    ? _capturePhoto
                    : (_isRecording ? _stopRecording : _startRecording),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: _mode == _CaptureMode.video && _isRecording
                        ? BoxShape.rectangle
                        : BoxShape.circle,
                    borderRadius: _mode == _CaptureMode.video && _isRecording
                        ? BorderRadius.circular(12)
                        : null,
                    color: _isRecording ? Colors.redAccent : Colors.white,
                    border: Border.all(color: Colors.white54, width: 4),
                  ),
                ),
              ),
              const SizedBox(width: 44), // 좌측 전환 버튼과 시각적으로 대칭을 맞추는 여백
            ],
          ),
        ),
      ],
    );
  }

  Widget _modeChip(String label, _CaptureMode mode) {
    final active = _mode == mode;
    return GestureDetector(
      onTap: () => _setMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: _mode == _CaptureMode.photo
              ? Image.network(_capturedFile!.path, fit: BoxFit.contain)
              : (_previewController != null &&
                      _previewController!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _previewController!.value.aspectRatio,
                      child: VideoPlayer(_previewController!),
                    )
                  : const CircularProgressIndicator()),
        ),
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed: _retake,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                child: const Text('다시 촬영'),
              ),
              ElevatedButton(
                onPressed: _confirm,
                child: const Text('사용하기'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
