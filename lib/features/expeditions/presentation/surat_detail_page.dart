import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/sync/sync_manager.dart';
import '../data/expedition_model.dart';
import 'camera_capture_page.dart';

class SuratDetailPage extends StatefulWidget {
  final Expedition expedition;

  const SuratDetailPage({super.key, required this.expedition});

  @override
  State<SuratDetailPage> createState() => _SuratDetailPageState();
}

class _SuratDetailPageState extends State<SuratDetailPage> {
  late Expedition _expedition;
  final _penerimaCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _expedition = widget.expedition;
    if (_expedition.penerima != null) {
      _penerimaCtrl.text = _expedition.penerima!;
    }
  }

  @override
  void dispose() {
    _penerimaCtrl.dispose();
    super.dispose();
  }

  bool get _isDikirim => _expedition.status == ExpeditionStatus.dikirim;
  bool get _isDiterima => _expedition.status == ExpeditionStatus.diterima;
  bool get _canTakePhoto => _penerimaCtrl.text.trim().isNotEmpty;

  Future<void> _openCamera() async {
    if (!_canTakePhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nama penerima terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final namaPenerima = _penerimaCtrl.text.trim();
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => CameraCapturePage(
          nomorSurat: _expedition.nomorSurat ?? 'Tanpa Nomor',
          namaPenerima: namaPenerima,
        ),
      ),
    );
    if (result == null || !mounted) return;

    final String? fotoPath = result['foto_path'] as String?;
    final double? lat = (result['latitude'] as num?)?.toDouble();
    final double? lng = (result['longitude'] as num?)?.toDouble();
    final String fotoHash = (result['foto_hash'] as String?) ?? '';
    final String address = (result['alamat'] as String?) ?? '';

    if (fotoPath == null || fotoPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto tidak tersedia, coba ambil ulang'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final File foto = File(fotoPath);
    if (!await foto.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File foto tidak ditemukan'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _uploading = true);
    try {
      final syncResult = await sl<SyncManager>().saveProof(
        expedition: _expedition,
        recipient: namaPenerima,
        photoPath: fotoPath,
        photoHash: fotoHash,
        latitude: lat ?? 0.0,
        longitude: lng ?? 0.0,
        address: address,
      );
      setState(() {
        _expedition = _expedition.copyWith(
          status: ExpeditionStatus.diterima,
          penerima: namaPenerima,
          fotoPath: fotoPath,
          fotoHash: fotoHash,
          lat: lat ?? 0.0,
          lng: lng ?? 0.0,
          alamat: address,
          isSynced: syncResult.synced,
          needsUpload: !syncResult.synced,
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              syncResult.synced
                  ? 'Bukti berhasil disimpan dan tersinkron.'
                  : 'Bukti tersimpan offline dan akan tersinkron otomatis.',
            ),
            backgroundColor:
                syncResult.synced ? Colors.green : Colors.orange.shade800,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload gagal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _formatTanggal(String? raw) {
    if (raw == null) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm', 'id').format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_expedition.nomorSurat ?? 'Detail Surat'),
        centerTitle: false,
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _uploading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Menyimpan bukti pengiriman...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusBanner(status: _expedition.status),
                    if (_expedition.pendingTake ||
                        _expedition.needsUpload) ...[
                      const SizedBox(height: 12),
                      const _PendingSyncBanner(),
                    ],
                    const SizedBox(height: 16),
                    _InfoCard(
                      title: 'Informasi Surat',
                      icon: Icons.mail_outline,
                      children: [
                        _InfoRow('Nomor Surat', _expedition.nomorSurat ?? '-'),
                        _InfoRow('Perihal', _expedition.perihal),
                        _InfoRow(
                          'Pengirim (Divisi)',
                          _expedition.divisiPengirim.isEmpty
                              ? '-'
                              : _expedition.divisiPengirim,
                        ),
                        _InfoRow(
                          'Tujuan (Divisi)',
                          _expedition.divisiTujuan.isEmpty
                              ? '-'
                              : _expedition.divisiTujuan,
                        ),
                        if (_expedition.tanggalDiterima != null)
                          _InfoRow(
                            'Tanggal Diterima',
                            _formatTanggal(_expedition.tanggalDiterima),
                          ),
                      ],
                    ),
                    if (_isDiterima && _expedition.penerima != null) ...[
                      const SizedBox(height: 12),
                      _InfoCard(
                        title: 'Bukti Pengiriman',
                        icon: Icons.verified_outlined,
                        children: [
                          _InfoRow('Nama Penerima', _expedition.penerima!),
                          if (_expedition.lat != null && _expedition.lng != null)
                            _InfoRow(
                              'Koordinat GPS',
                              '${_expedition.lat!.toStringAsFixed(6)}, ${_expedition.lng!.toStringAsFixed(6)}',
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 32),
                    if (_isDikirim) ...[
                      const Text(
                        'Nama Penerima Surat',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _penerimaCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Masukkan Nama Penerima',
                          hintText: 'Contoh: Budi Santoso',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                          helperText:
                              'Isi nama penerima untuk mengaktifkan tombol kamera',
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Nama penerima wajib diisi'
                            : null,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: _canTakePhoto ? _openCamera : null,
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text(
                            'Ambil Foto Bukti Pengiriman',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: _canTakePhoto
                                ? colorScheme.primary
                                : Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Foto akan disertai watermark: Nama Penerima, GPS & Waktu',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.outline,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    if (_isDiterima) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Surat telah diterima dan data sudah tersinkronisasi ke server.',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class _PendingSyncBanner extends StatelessWidget {
  const _PendingSyncBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_upload_outlined, color: Color(0xFFC2410C)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Perubahan tersimpan di perangkat dan menunggu koneksi internet.',
              style: TextStyle(
                color: Color(0xFF9A3412),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (status) {
      ExpeditionStatus.dikirim => (
          Colors.orange,
          Icons.local_shipping_outlined,
          'Sedang Dikirim'
        ),
      ExpeditionStatus.diterima => (
          Colors.green,
          Icons.check_circle_outline,
          'Sudah Diterima'
        ),
      _ => (
          Theme.of(context).colorScheme.primary,
          Icons.inbox_outlined,
          'Tersedia'
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                )),
          ),
          const Text(': ', style: TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
