import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/di/service_locator.dart';
import '../data/api_surat_repository.dart';
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
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _expedition = widget.expedition;
  }

  @override
  void dispose() {
    _penerimaCtrl.dispose();
    super.dispose();
  }

  bool get _isDikirim => _expedition.status == ExpeditionStatus.dikirim;
  bool get _isDiterima => _expedition.status == ExpeditionStatus.diterima;

  Future<void> _openCamera() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => CameraCapturePage(
          nomorSurat: _expedition.nomorSurat ?? 'Tanpa Nomor',
        ),
      ),
    );
    if (result == null || !mounted) return;

    final File? foto = result['file'] as File?;
    final double? lat = result['lat'] as double?;
    final double? lng = result['lng'] as double?;

    if (foto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto tidak tersedia'), backgroundColor: Colors.red),
      );
      return;
    }

    _penerimaCtrl.clear();
    final String? namaPenerima = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Nama Penerima'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Masukkan nama penerima atau perwakilan surat ini.'),
            const SizedBox(height: 12),
            TextField(
              controller: _penerimaCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama Penerima',
                hintText: 'Contoh: Budi Santoso',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) Navigator.of(ctx).pop(v.trim());
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final name = _penerimaCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Nama tidak boleh kosong')),
                );
                return;
              }
              Navigator.of(ctx).pop(name);
            },
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );

    if (namaPenerima == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      await sl<ApiSuratRepository>().uploadBukti(
        uuid: _expedition.uuid,
        foto: foto,
        lat: lat ?? 0.0,
        lng: lng ?? 0.0,
        namaPenerima: namaPenerima,
      );
      setState(() {
        _expedition = _expedition.copyWith(
          status: ExpeditionStatus.diterima,
          penerima: namaPenerima,
          isSynced: true,
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Surat berhasil dikirim & disinkronkan!'),
            ]),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload gagal: $e'), backgroundColor: Colors.red),
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
      backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
                  Text('Mengupload bukti pengiriman...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusBanner(status: _expedition.status),
                  const SizedBox(height: 16),
                  _InfoCard(
                    title: 'Informasi Surat',
                    icon: Icons.mail_outline,
                    children: [
                      _InfoRow('Nomor Surat', _expedition.nomorSurat ?? '-'),
                      _InfoRow('Perihal', _expedition.perihal),
                      _InfoRow('Pengirim (Divisi)', _expedition.divisiPengirim.isEmpty ? '-' : _expedition.divisiPengirim),
                      _InfoRow('Tujuan (Divisi)', _expedition.divisiTujuan.isEmpty ? '-' : _expedition.divisiTujuan),
                      if (_expedition.tanggalDiterima != null)
                        _InfoRow('Tanggal Diterima', _formatTanggal(_expedition.tanggalDiterima)),
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
                          _InfoRow('Koordinat GPS', '${_expedition.lat!.toStringAsFixed(6)}, ${_expedition.lng!.toStringAsFixed(6)}'),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),
                  if (_isDikirim) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _openCamera,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text(
                          'Ambil Foto Bukti Pengiriman',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Foto akan disertai watermark GPS & waktu otomatis',
                        style: TextStyle(fontSize: 12, color: colorScheme.outline),
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
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
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
      ExpeditionStatus.dikirim => (Colors.orange, Icons.local_shipping_outlined, 'Sedang Dikirim'),
      ExpeditionStatus.diterima => (Colors.green, Icons.check_circle_outline, 'Sudah Diterima'),
      _ => (Theme.of(context).colorScheme.primary, Icons.inbox_outlined, 'Tersedia'),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
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

  const _InfoCard({required this.title, required this.icon, required this.children});

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
                Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
