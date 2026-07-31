import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/di/service_locator.dart';
import 'data/courier_pairing_repository.dart';

class CourierPairingScannerPage extends StatefulWidget {
  const CourierPairingScannerPage({super.key});

  @override
  State<CourierPairingScannerPage> createState() =>
      _CourierPairingScannerPageState();
}

class _CourierPairingScannerPageState
    extends State<CourierPairingScannerPage> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  bool _processing = false;
  String? _error;
  CourierPairingResult? _result;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleCapture(BarcodeCapture capture) async {
    if (_processing || _result != null) return;

    String? rawValue;
    for (final barcode in capture.barcodes) {
      if (barcode.rawValue?.isNotEmpty == true) {
        rawValue = barcode.rawValue;
        break;
      }
    }
    if (rawValue == null) return;

    setState(() {
      _processing = true;
      _error = null;
    });
    await _scannerController.stop();

    try {
      final result = await sl<CourierPairingRepository>().claimQrPayload(
        rawValue,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _processing = false;
      });
    } on CourierPairingException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _processing = false;
      });
      await _scannerController.start();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'QR belum dapat diproses. Periksa koneksi lalu coba lagi.';
        _processing = false;
      });
      await _scannerController.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) return _buildSuccess(context, _result!);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Tata Usaha'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            tooltip: 'Nyalakan lampu',
            onPressed: _scannerController.toggleTorch,
            icon: const Icon(Icons.flashlight_on_outlined),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _scannerController,
            fit: BoxFit.cover,
            onDetect: _handleCapture,
          ),
          Container(color: Colors.black.withValues(alpha: 0.22)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                children: [
                  const Text(
                    'Arahkan kamera ke QR yang tampil pada website akun Tata Usaha.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 270,
                    height: 270,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Center(
                      child: _processing
                          ? Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(color: Colors.white),
                                  SizedBox(height: 14),
                                  Text(
                                    'Menghubungkan...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const Icon(
                              Icons.qr_code_scanner,
                              size: 54,
                              color: Colors.white70,
                            ),
                    ),
                  ),
                  const Spacer(),
                  if (_error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7F1D1D).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const Text(
                      'Pairing memerlukan koneksi internet. QR hanya berlaku 5 menit dan satu kali penggunaan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, height: 1.4),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(
    BuildContext context,
    CourierPairingResult result,
  ) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Kurir Terhubung')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 58,
                  color: Color(0xFF16A34A),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Pairing berhasil',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              const Text(
                'Mulai sekarang Anda hanya menerima surat dari Tata Usaha berikut.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), height: 1.5),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'TATA USAHA',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.tuName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (result.tuEmail?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        result.tuEmail!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                    const Divider(height: 28),
                    Text(
                      result.divisionCode?.isNotEmpty == true
                          ? '${result.divisionName} (${result.divisionCode})'
                          : result.divisionName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(result),
                  icon: const Icon(Icons.sync),
                  label: const Text('Sinkronkan tugas sekarang'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
