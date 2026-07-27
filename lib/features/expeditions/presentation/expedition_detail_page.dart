import 'dart:io';
import 'package:flutter/material.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/di/service_locator.dart';
import '../data/expedition_repository.dart';
import '../data/expedition_model.dart';
import '../../../core/sync/sync_manager.dart';
import 'camera_capture_page.dart';

class ExpeditionDetailPage extends StatefulWidget {
  final Expedition expedition;

  const ExpeditionDetailPage({
    super.key,
    required this.expedition,
  });

  @override
  State<ExpeditionDetailPage> createState() => _ExpeditionDetailPageState();
}

class _ExpeditionDetailPageState extends State<ExpeditionDetailPage> {
  late Expedition _expedition;
  final _penerimaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _expedition = widget.expedition;
  }

  @override
  void dispose() {
    _penerimaController.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    // Navigasi ke Halaman Kamera untuk mengambil foto & metadata GPS
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => CameraCapturePage(
          nomorSurat: _expedition.nomorSurat ?? 'Tanpa Nomor',
        ),
      ),
    );

    if (result == null) return;

    // Tampilkan Dialog Input Nama Penerima
    if (!mounted) return;
    _penerimaController.clear();
    
    final String? namaPenerima = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Input Penerima'),
        content: TextField(
          controller: _penerimaController,
          decoration: const InputDecoration(
            labelText: 'Nama Penerima / Perwakilan',
            hintText: 'Masukkan nama lengkap...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              final name = _penerimaController.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(context).pop(name);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama penerima tidak boleh kosong')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (namaPenerima == null) return;

    // Update objek ekspedisi ke database lokal dengan status DITERIMA dan beri tanda needs_upload
    final updatedExpedisi = _expedition.copyWith(
      status: ExpeditionStatus.diterima,
      fotoPath: result['foto_path'] as String,
      fotoHash: result['foto_hash'] as String,
      lat: result['latitude'] as double,
      lng: result["longitude"] as double,
      alamat: result['alamat'] as String,
      penerima: namaPenerima,
      tanggalDiterima: DateTime.now().toLocal().toString().substring(0, 19),
      needsUpload: true,
      isSynced: false,
    );

    await sl<ExpeditionRepository>().upsert(updatedExpedisi);

    setState(() {
      _expedition = updatedExpedisi;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanda terima disimpan lokal! Tekan tombol Sync di dashboard untuk mengirim ke server.'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _takeSurat() async {
    setState(() => _isLoadingTake = true);
    final syncManager = sl<SyncManager>();
    final success = await syncManager.takeSurat(_expedition.uuid);
    
    if (success) {
      final updated = _expedition.copyWith(status: ExpeditionStatus.dikirim);
      setState(() {
        _expedition = updated;
        _isLoadingTake = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Surat berhasil diambil!')),
        );
      }
    } else {
      setState(() => _isLoadingTake = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengambil surat. Coba lagi.')),
        );
      }
    }
  }

  bool _isLoadingTake = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDiterima = _expedition.status == ExpeditionStatus.diterima;
    final isDraft = _expedition.status == 'draft';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Surat Ekspedisi'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Banner Card
            _buildStatusCard(isDiterima, isDraft),
            const SizedBox(height: 20),

            // Letter Info
            _buildSectionTitle('Informasi Surat'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow('Nomor Surat', _expedition.nomorSurat ?? '-'),
                    const Divider(),
                    _buildInfoRow('Perihal', _expedition.perihal),
                    const Divider(),
                    _buildInfoRow('Divisi Pengirim', _expedition.divisiPengirim),
                    const Divider(),
                    _buildInfoRow('Divisi Tujuan', _expedition.divisiTujuan),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Proof Metadata (Jika sudah diterima)
            if (isDiterima) ...[
              _buildSectionTitle('Bukti Penerimaan'),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildInfoRow('Nama Penerima', _expedition.penerima ?? '-'),
                      const Divider(),
                      _buildInfoRow('Waktu Penerimaan', _expedition.tanggalDiterima ?? '-'),
                      const Divider(),
                      _buildInfoRow('Koordinat GPS', '${_expedition.lat ?? 0.0}, ${_expedition.lng ?? 0.0}'),
                      const Divider(),
                      _buildInfoRow('Alamat Lokasi', _expedition.alamat ?? '-'),
                      const Divider(),
                      _buildInfoRow('SHA-256 Hash', _expedition.fotoHash ?? '-', isMonospace: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Image display
              if (_expedition.fotoPath != null && File(_expedition.fotoPath!).existsSync()) ...[
                _buildSectionTitle('Foto Bukti (Overlay Watermark)'),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_expedition.fotoPath!),
                    fit: BoxFit.cover,
                    height: 250,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],

            // Action Button
            if (isDraft)
              ElevatedButton.icon(
                onPressed: _isLoadingTake ? null : _takeSurat,
                icon: const Icon(Icons.assignment_return_rounded, color: Colors.white),
                label: _isLoadingTake 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Ambil Surat Ini'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              )
            else if (!isDiterima)
              ElevatedButton.icon(
                onPressed: _openCamera,
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                label: const Text('Ambil Foto Bukti Penerimaan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1565C0),
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isDiterima, bool isDraft) {
    final statusText = isDiterima 
        ? 'DITERIMA' 
        : (isDraft ? 'DRAFT (BELUM DIAMBIL)' : 'DIKIRIM (DALAM PERJALANAN)');
    final bgColor = isDiterima 
        ? Colors.green.shade50 
        : (isDraft ? Colors.grey.shade100 : Colors.orange.shade50);
    final borderColor = isDiterima 
        ? Colors.green.shade300 
        : (isDraft ? Colors.grey.shade300 : Colors.orange.shade300);
    final textColor = isDiterima 
        ? Colors.green.shade700 
        : (isDraft ? Colors.grey.shade700 : Colors.orange.shade700);
    final icon = isDiterima 
        ? Icons.check_circle_outline 
        : (isDraft ? Icons.assignment_outlined : Icons.info_outline);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Status Pengiriman',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                statusText,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontFamily: isMonospace ? 'monospace' : null,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
