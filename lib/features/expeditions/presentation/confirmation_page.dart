import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/network/secure_storage_service.dart';
import '../data/expedition_model.dart';

class ConfirmationPage extends StatefulWidget {
  final Expedition surat;
  const ConfirmationPage({super.key, required this.surat});

  @override
  State<ConfirmationPage> createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  XFile? _capturedImage;
  Position? _position;
  bool _loadingLocation = false;
  bool _uploading = false;
  String? _error;
  final _penerimaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initCamera();
    _getLocation();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _penerimaController.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;
    _cameraController = CameraController(_cameras.first, ResolutionPreset.medium);
    await _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _getLocation() async {
    setState(() => _loadingLocation = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() => _position = pos);
    } catch (_) {
    } finally {
      setState(() => _loadingLocation = false);
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    final file = await _cameraController!.takePicture();
    setState(() => _capturedImage = file);
  }

  Future<void> _submit() async {
    if (_capturedImage == null) {
      setState(() => _error = 'Ambil foto terlebih dahulu');
      return;
    }
    setState(() { _uploading = true; _error = null; });
    try {
      final token = await sl<SecureStorageService>().accessToken;
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        },
      ));

      final formData = FormData.fromMap({
        'foto': await MultipartFile.fromFile(_capturedImage!.path, filename: 'bukti.jpg'),
        if (_position != null) 'lat': _position!.latitude.toString(),
        if (_position != null) 'long': _position!.longitude.toString(),
        if (_penerimaController.text.isNotEmpty) 'nama_penerima': _penerimaController.text.trim(),
      });

      await dio.post('${AppConstants.epSurat}/${widget.surat.uuid}/bukti', data: formData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Surat berhasil dikonfirmasi!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true);
      }
    } on DioException catch (err) {
      setState(() => _error = err.response?.data?['error']?.toString() ?? 'Gagal upload');
    } finally {
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Penerimaan'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.surat.nomorSurat ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(widget.surat.perihal, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('${widget.surat.divisiPengirim} → ${widget.surat.divisiTujuan}',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.outline)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_capturedImage == null) ...[
              if (_cameraController != null && _cameraController!.value.isInitialized)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  ),
                )
              else
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _takePicture,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Ambil Foto'),
              ),
            ] else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(_capturedImage!.path), height: 250, fit: BoxFit.cover),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() => _capturedImage = null),
                icon: const Icon(Icons.refresh),
                label: const Text('Ulangi Foto'),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 6),
                if (_loadingLocation)
                  const Text('Mendapatkan lokasi...')
                else if (_position != null)
                  Expanded(
                    child: Text(
                      '${_position!.latitude.toStringAsFixed(6)}, ${_position!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  )
                else
                  const Text('Lokasi tidak tersedia'),
                if (!_loadingLocation)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    onPressed: _getLocation,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _penerimaController,
              decoration: const InputDecoration(
                labelText: 'Nama Penerima (opsional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
              ),
            FilledButton.icon(
              onPressed: _uploading ? null : _submit,
              icon: _uploading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline),
              label: Text(_uploading ? 'Mengirim...' : 'Konfirmasi Penerimaan'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
