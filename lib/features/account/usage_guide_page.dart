import 'package:flutter/material.dart';

class UsageGuidePage extends StatelessWidget {
  const UsageGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Cara Pemakaian')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: const [
          _GuideHero(),
          SizedBox(height: 20),
          _GuideSection(
            number: '01',
            icon: Icons.notifications_active_outlined,
            title: 'Terima tugas baru',
            text: 'Saat surat baru masuk, notifikasi akan muncul. Buka tab Aktivitas untuk melihat daftar surat yang tersedia.',
          ),
          _GuideSection(
            number: '02',
            icon: Icons.local_shipping_outlined,
            title: 'Ambil surat',
            text: 'Buka detail surat lalu tekan Ambil Tugas. Status surat berubah menjadi Dikirim dan surat menjadi tanggung jawab Anda.',
          ),
          _GuideSection(
            number: '03',
            icon: Icons.person_outline,
            title: 'Masukkan nama penerima',
            text: 'Sebelum mengambil foto, isi nama orang yang menerima surat. Nama ini akan tampil pada website dan watermark foto.',
          ),
          _GuideSection(
            number: '04',
            icon: Icons.camera_alt_outlined,
            title: 'Ambil bukti pengiriman',
            text: 'Tekan Ambil Foto Bukti Pengiriman. Aplikasi menambahkan nomor surat, nama penerima, GPS, alamat, dan waktu pada foto.',
          ),
          _GuideSection(
            number: '05',
            icon: Icons.sync_outlined,
            title: 'Sinkronisasi otomatis',
            text: 'Jika offline, tugas dan bukti disimpan di perangkat. Saat internet kembali, data akan dikirim otomatis ke server.',
          ),
          SizedBox(height: 8),
          _OfflineTip(),
          SizedBox(height: 16),
          _StatusGuide(),
        ],
      ),
    );
  }
}

class _GuideHero extends StatelessWidget {
  const _GuideHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0284C7)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.delivery_dining_outlined, color: Colors.white, size: 42),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panduan Kurir',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Ikuti langkah berikut untuk menyelesaikan pengiriman surat.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String text;

  const _GuideSection({
    required this.number,
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LANGKAH $number',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      text,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineTip extends StatelessWidget {
  const _OfflineTip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_outlined, color: Color(0xFFC2410C)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tips offline: jangan hapus aplikasi atau logout sebelum indikator sinkronisasi selesai. Pastikan file foto tetap tersimpan sampai upload berhasil.',
              style: TextStyle(color: Color(0xFF9A3412), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusGuide extends StatelessWidget {
  const _StatusGuide();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Arti status surat',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 12),
            _StatusRow(color: Color(0xFF1565C0), label: 'Draft', text: 'Menunggu diambil kurir'),
            _StatusRow(color: Color(0xFFF59E0B), label: 'Dikirim', text: 'Sedang diantar kurir'),
            _StatusRow(color: Color(0xFF16A34A), label: 'Diterima', text: 'Bukti pengiriman sudah tersimpan'),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final Color color;
  final String label;
  final String text;

  const _StatusRow({required this.color, required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          SizedBox(width: 76, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF64748B)))),
        ],
      ),
    );
  }
}
