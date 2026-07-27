import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/config/app_constants.dart';
import '../../core/di/service_locator.dart';
import '../auth/data/auth_repository.dart';
import '../auth/presentation/login_page.dart';
import '../dashboard/dashboard_page.dart';
import '../expeditions/data/api_surat_repository.dart';
import '../expeditions/data/expedition_model.dart';
import '../expeditions/presentation/surat_detail_page.dart';

class HomePage extends StatefulWidget {
  final bool isConfigured;
  const HomePage({super.key, required this.isConfigured});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Expedition> _suratList = [];
  bool _loading = true;
  String? _error;
  String? _kurirNama;
  String? _kurirEmail;

  // Track surat IDs seen before last refresh for badge counting
  Set<String> _seenUuids = {};
  int _newSuratCount = 0;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadData(initial: true);
    // Poll every 30s for new surat
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadData());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool initial = false}) async {
    if (initial) setState(() { _loading = true; _error = null; });
    try {
      final user = await sl<AuthRepository>().getCurrentUser();
      _kurirNama = user?['nama_lengkap'] as String? ?? 'Kurir';
      _kurirEmail = user?['email'] as String? ?? '';
      final list = await sl<ApiSuratRepository>().fetchSurat();

      if (mounted) {
        setState(() {
          if (!initial && _seenUuids.isNotEmpty) {
            final incoming = list.where((s) => !_seenUuids.contains(s.uuid)).toList();
            _newSuratCount = incoming.length;
          }
          _suratList = list;
          _seenUuids = list.map((s) => s.uuid).toSet();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _clearBadge() {
    if (_newSuratCount > 0) setState(() => _newSuratCount = 0);
  }

  Future<void> _ambilSurat(Expedition surat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ambil Surat'),
        content: Text('Ambil dan kirimkan surat "${surat.nomorSurat ?? surat.perihal}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ambil')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      final ok = await sl<ApiSuratRepository>().ambilSurat(surat.uuid);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Surat berhasil diambil, silakan antar!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openDetail(Expedition surat) async {
    final refreshed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SuratDetailPage(expedition: surat)),
    );
    if (refreshed == true) _loadData();
  }

  Future<void> _logout() async {
    await sl<AuthRepository>().logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginPage(isConfigured: widget.isConfigured)),
      );
    }
  }

  // Surat that kurir should see in sidebar: draft (tersedia) + dikirim
  List<Expedition> get _tugasList =>
      _suratList.where((s) => s.status != ExpeditionStatus.diterima).toList();

  List<Expedition> get _draftList =>
      _suratList.where((s) => s.status == ExpeditionStatus.draft).toList();

  List<Expedition> get _dikirimList =>
      _suratList.where((s) => s.status == ExpeditionStatus.dikirim).toList();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      appBar: AppBar(
        title: const Text('Ekspedisi Surat'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadData(initial: true),
          ),
        ],
      ),
      drawer: _buildDrawer(context, colorScheme),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : const DashboardPage(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text('Gagal memuat data', style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => _loadData(initial: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, ColorScheme colorScheme) {
    return Drawer(
      child: Column(
        children: [
          // Drawer header
          DrawerHeader(
            decoration: BoxDecoration(color: colorScheme.primary),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white24,
                  child: Text(
                    (_kurirNama?.isNotEmpty == true)
                        ? _kurirNama![0].toUpperCase()
                        : 'K',
                    style: const TextStyle(
                        fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _kurirNama ?? 'Kurir',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _kurirEmail ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Section: Tugas Saya
          _buildSectionHeader(
            context,
            'Tugas Saya',
            trailing: _newSuratCount > 0
                ? GestureDetector(
                    onTap: _clearBadge,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_newSuratCount baru',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  )
                : null,
          ),

          if (_tugasList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text('Tidak ada tugas aktif',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
            )
          else
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (_draftList.isNotEmpty) ...[
                    _buildSubSectionLabel('Tersedia (${_draftList.length})'),
                    ..._draftList.map((s) => _buildSuratTile(context, s, colorScheme)),
                  ],
                  if (_dikirimList.isNotEmpty) ...[
                    _buildSubSectionLabel('Sedang Dikirim (${_dikirimList.length})'),
                    ..._dikirimList.map((s) => _buildSuratTile(context, s, colorScheme)),
                  ],
                ],
              ),
            ),

          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Keluar', style: TextStyle(color: Colors.red)),
            onTap: _logout,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.5)),
          const Spacer(),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildSubSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSuratTile(
      BuildContext context, Expedition surat, ColorScheme colorScheme) {
    final isDraft = surat.status == ExpeditionStatus.draft;
    final statusColor = isDraft ? colorScheme.primary : Colors.orange.shade600;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.pop(context); // close drawer
          _openDetail(surat);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isDraft ? 'Tersedia' : 'Dikirim',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor),
                    ),
                  ),
                  const Spacer(),
                  if (isDraft)
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _ambilSurat(surat);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Ambil',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                surat.nomorSurat ?? surat.perihal,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                surat.perihal,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.arrow_forward, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      surat.divisiTujuan.isEmpty ? '-' : surat.divisiTujuan,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

