import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../core/config/app_constants.dart';
import '../auth/data/auth_repository.dart';
import '../auth/presentation/login_page.dart';
import '../expeditions/data/api_surat_repository.dart';
import '../expeditions/data/expedition_model.dart';
import '../expeditions/presentation/confirmation_page.dart';

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
  String _filter = 'semua';
  Timer? _pollTimer;
  int _prevDraftCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _silentRefresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _silentRefresh() async {
    try {
      final list = await sl<ApiSuratRepository>().fetchSurat();
      final newDraftCount = list.where((s) => s.status == ExpeditionStatus.draft).length;
      if (mounted) {
        if (newDraftCount > _prevDraftCount) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${newDraftCount - _prevDraftCount} surat baru tersedia!'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        setState(() { _suratList = list; _prevDraftCount = newDraftCount; });
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = await sl<AuthRepository>().getCurrentUser();
      _kurirNama = user?['nama_lengkap'] as String? ?? 'Kurir';
      final list = await sl<ApiSuratRepository>().fetchSurat();
      _prevDraftCount = list.where((s) => s.status == ExpeditionStatus.draft).length;
      setState(() { _suratList = list; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  List<Expedition> get _filtered {
    if (_filter == 'semua') return _suratList;
    return _suratList.where((s) => s.status == _filter).toList();
  }

  Future<void> _ambilSurat(Expedition surat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ambil Surat'),
        content: Text('Ambil surat ${surat.nomorSurat ?? surat.perihal}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ambil')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final ok = await sl<ApiSuratRepository>().ambilSurat(surat.uuid);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Surat berhasil diambil'), backgroundColor: Colors.green),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _konfirmasiPenerimaan(Expedition surat) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ConfirmationPage(surat: surat)),
    );
    if (result == true) _loadData();
  }

  Future<void> _logout() async {
    await sl<AuthRepository>().logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginPage(isConfigured: widget.isConfigured)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ekspedisi Surat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(_kurirNama ?? '', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(theme),
          Expanded(child: _buildBody(theme)),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ThemeData theme) {
    final filters = [
      ('semua', 'Semua'),
      (ExpeditionStatus.draft, 'Tersedia'),
      (ExpeditionStatus.dikirim, 'Dikirim'),
      (ExpeditionStatus.diterima, 'Diterima'),
    ];
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((entry) {
            final selected = _filter == entry.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(entry.$2),
                selected: selected,
                onSelected: (_) => setState(() => _filter = entry.$1),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadData, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }
    final list = _filtered;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            const Text('Tidak ada surat', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        itemBuilder: (context, index) => _buildSuratCard(list[index], theme),
      ),
    );
  }

  Widget _buildSuratCard(Expedition surat, ThemeData theme) {
    final statusColor = _statusColor(surat.status, theme);
    final statusLabel = _statusLabel(surat.status);
    final isDraft = surat.status == ExpeditionStatus.draft;
    final isDikirim = surat.status == ExpeditionStatus.dikirim;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(surat.nomorSurat ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(surat.perihal, style: const TextStyle(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.send_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(child: Text(surat.divisiPengirim, style: const TextStyle(fontSize: 12, color: Colors.grey))),
            ]),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(child: Text(surat.divisiTujuan, style: const TextStyle(fontSize: 12, color: Colors.grey))),
            ]),
            if (surat.penerima != null) ...[
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(surat.penerima!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            ],
            if (isDraft || isDikirim) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (isDraft) Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _ambilSurat(surat),
                      icon: const Icon(Icons.local_shipping_outlined, size: 18),
                      label: const Text('Ambil'),
                    ),
                  ),
                  if (isDikirim) ...[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _konfirmasiPenerimaan(surat),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Konfirmasi Terima'),
                        style: FilledButton.styleFrom(backgroundColor: Colors.green),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status, ThemeData theme) {
    switch (status) {
      case ExpeditionStatus.dikirim: return Colors.orange;
      case ExpeditionStatus.diterima: return Colors.green;
      default: return theme.colorScheme.primary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case ExpeditionStatus.dikirim: return 'Sedang Dikirim';
      case ExpeditionStatus.diterima: return 'Diterima';
      default: return 'Tersedia';
    }
  }
}
