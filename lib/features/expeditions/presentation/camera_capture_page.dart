import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/utils/image_watermark_util.dart';

class CameraCapturePage extends StatefulWidget {
  final String nomorSurat;

  const CameraCapturePage({
    super.key,
    required this.nomorSurat,
  });

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitializing = true;
  bool _isProcessing = false;
  String _statusText = 'Menginisialisasi Kamera & GPS...';

  Position? _currentPosition;
  String _currentAddress = 'Mencari alamat...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissionsAndInit();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera(cameraController.description);
    }
  }

  Future<void> _requestPermissionsAndInit() async {
    setState(() {
      _isInitializing = true;
      _statusText = 'Meminta izin Kamera & GPS...';
    });

    // Request permissions
    final cameraStatus = await Permission.camera.request();
    final locationStatus = await Permission.locationWhenInUse.request();

    if (cameraStatus.isGranted && locationStatus.isGranted) {
      await _initLocation();
      await _setupCamera();
    } else {
      setState(() {
        _isInitializing = false;
        _statusText = 'Izin Kamera dan GPS diperlukan untuk mengambil bukti foto.';
      });
      _showPermissionDeniedDialog();
    }
  }

  Future<void> _initLocation() async {
    try {
      setState(() => _statusText = 'Mendapatkan koordinat GPS...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
      _currentPosition = position;

      setState(() => _statusText = 'Mengubah GPS ke Alamat...');
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final pm = placemarks.first;
        _currentAddress = '${pm.street ?? ''}, ${pm.subLocality ?? ''}, ${pm.locality ?? ''}, ${pm.subAdministrativeArea ?? ''}';
      } else {
        _currentAddress = 'Alamat tidak ditemukan';
      }
    } catch (e) {
      _currentAddress = 'Gagal mendapatkan alamat (${e.toString()})';
    }
  }

  Future<void> _setupCamera() async {
    try {
      setState(() => _statusText = 'Menyiapkan pratinjau kamera...');
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw Exception('Kamera tidak ditemukan pada perangkat');
      }

      // Gunakan kamera belakang utama
      final backCam = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      await _initCamera(backCam);
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _statusText = 'Gagal memuat kamera: ${e.toString()}';
      });
    }
  }

  Future<void> _initCamera(CameraDescription description) async {
    _controller = CameraController(
      description,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _statusText = 'Gagal menginisialisasi kamera: $e';
        });
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Izin Diperlukan'),
        content: const Text(
            'Aplikasi membutuhkan izin Kamera dan Lokasi (GPS) untuk mengambil bukti pengiriman berserta koordinat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusText = 'Mengambil gambar...';
    });

    try {
      // 1. Ambil foto menggunakan controller
      final XFile rawPhoto = await _controller!.takePicture();

      setState(() => _statusText = 'Mendapatkan GPS terbaru...');
      // 2. Dapatkan lokasi saat ini secara presisi
      Position? position = _currentPosition;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 4),
        );
      } catch (_) {}

      final lat = position?.latitude ?? 0.0;
      final lon = position?.longitude ?? 0.0;

      setState(() => _statusText = 'Menyematkan Watermark...');
      // 3. Sematkan watermark overlay dan dapatkan path berkas baru + hash SHA-256
      final result = await ImageWatermarkUtil.addWatermarkAndGetHash(
        imagePath: rawPhoto.path,
        nomorSurat: widget.nomorSurat,
        latitude: lat,
        longitude: lon,
        address: _currentAddress,
      );

      // Hapus foto asli temporer untuk menghemat ruang
      try {
        await File(rawPhoto.path).delete();
      } catch (_) {}

      if (mounted) {
        Navigator.of(context).pop({
          'foto_path': result.watermarkedPath,
          'foto_hash': result.hash,
          'latitude': lat,
          'longitude': lon,
          'alamat': _currentAddress,
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusText = 'Error: ${e.toString()}';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil foto: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              Text(
                _statusText,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _statusText,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _requestPermissionsAndInit,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          CameraPreview(_controller!),

          // Overlay Watermark Preview
          Positioned(
            bottom: 120,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No. Surat: ${widget.nomorSurat}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'GPS: ${_currentPosition?.latitude ?? 0.0}, ${_currentPosition?.longitude ?? 0.0}',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lokasi: $_currentAddress',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          // Bottom Control Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 110,
            child: Container(
              color: Colors.black87,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel button
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                  ),

                  // Capture button
                  GestureDetector(
                    onTap: _isProcessing ? null : _capturePhoto,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade400, width: 4),
                      ),
                      child: _isProcessing
                          ? const Center(
                              child: CircularProgressIndicator(color: Colors.black),
                            )
                          : const Icon(Icons.camera_alt, color: Colors.black, size: 32),
                    ),
                  ),

                  // Spacer to balance layout
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),

          // Processing Overlay loading state
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      _statusText,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
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
