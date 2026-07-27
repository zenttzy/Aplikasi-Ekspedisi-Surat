import 'package:flutter/material.dart';

import '../../core/config/app_constants.dart';
import '../../core/di/service_locator.dart';
import '../expeditions/data/api_surat_repository.dart';
import '../expeditions/data/expedition_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Expedition> _suratList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final list = await sl<ApiSuratRepository>().fetchSurat();
      if (mounted) setState(() { _suratList = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _totalSurat => _suratList.length;
  int get _suratTersedia => _suratList.where((s) => s.status == ExpeditionStatus.draft).length;
  int get _suratDikirim => _suratList.where((s) => s.status == ExpeditionStatus.dikirim).length;
  int get _suratDiterima => _suratList.where((s) => s.status == ExpeditionStatus.diterima).length;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Selamat Pagi' : now.hour < 17 ? 'Selamat Siang' : 'Selamat Sore';

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$greeting 👋',
                      style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('Siap Mengirim Surat Hari Ini?',
                      style: TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _loading
                            ? 'Memuat data...'
                            : '$_suratDikirim surat sedang dalam pengiriman',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text('Ringkasan Surat',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            // Stat cards 2x2 grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.55,
              children: [
                _StatCard(
                  label: 'Total Surat',
                  value: _loading ? '-' : '$_totalSurat',
                  icon: Icons.mail_outline,
                  color: colorScheme.primary,
                  loading: _loading,
                ),
                _StatCard(
                  label: 'Tersedia',
                  value: _loading ? '-' : '$_suratTersedia',
                  icon: Icons.inbox_outlined,
                  color: Colors.blue.shade600,
                  loading: _loading,
                ),
                _StatCard(
                  label: 'Sedang Dikirim',
                  value: _loading ? '-' : '$_suratDikirim',
                  icon: Icons.local_shipping_outlined,
                  color: Colors.orange.shade600,
                  loading: _loading,
                ),
                _StatCard(
                  label: 'Sudah Diterima',
                  value: _loading ? '-' : '$_suratDiterima',
                  icon: Icons.check_circle_outline,
                  color: Colors.green.shade600,
                  loading: _loading,
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text('Panduan Pengiriman',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _GuideCard(
              title: 'Buka Daftar Surat',
              desc: 'Ketuk ikon menu (☰) untuk melihat surat yang perlu dikirimkan.',
              icon: Icons.menu,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 8),
            _GuideCard(
              title: 'Ambil Surat',
              desc: 'Tekan "Ambil & Kirim" pada surat berstatus tersedia untuk mulai pengiriman.',
              icon: Icons.touch_app_outlined,
              color: Colors.blue.shade600,
            ),
            const SizedBox(height: 8),
            _GuideCard(
              title: 'Foto Bukti Pengiriman',
              desc: 'Buka detail surat, ambil foto bukti, lalu isi nama penerima.',
              icon: Icons.camera_alt_outlined,
              color: Colors.orange.shade600,
            ),
            const SizedBox(height: 8),
            _GuideCard(
              title: 'Sinkronisasi Otomatis',
              desc: 'Status surat otomatis diperbarui ke server setelah upload berhasil.',
              icon: Icons.sync,
              color: Colors.green.shade600,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool loading;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.loading,
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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const Spacer(),
            loading
                ? SizedBox(
                    height: 20,
                    width: 40,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.grey.shade200,
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                : Text(value,
                    style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;

  const _GuideCard({
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(desc,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
