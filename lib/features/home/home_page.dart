import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/di/service_locator.dart';
import '../../core/sync/sync_manager.dart';
import '../expeditions/data/expedition_model.dart';
import '../expeditions/data/expedition_repository.dart';
import '../expeditions/presentation/expedition_detail_page.dart';

class HomePage extends StatefulWidget {
  final bool isConfigured;

  const HomePage({super.key, required this.isConfigured});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? _count;
  String? _error;
  bool _isSyncing = false;
  List<Expedition> _expeditions = [];

  @override
  void initState() {
    super.initState();
    _loadCount();
    // Perform sync on init if configured
    if (widget.isConfigured) {
      _performSync();
    }
  }

  Future<void> _loadCount() async {
    try {
      final repo = sl<ExpeditionRepository>();
      final items = await repo.getAll();
      if (mounted) {
        setState(() {
          _expeditions = items;
          _count = items.length;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _performSync() async {
    if (_isSyncing) return;
    setState(() {
      _isSyncing = true;
      _error = null;
    });
    try {
      final syncManager = sl<SyncManager>();
      final result = await syncManager.syncAll();
      if (!result.isSuccess) {
        setState(() => _error = result.error);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Sync Berhasil: ${result.downloaded} diunduh, ${result.uploaded} diunggah',
              ),
              backgroundColor: Colors.green.shade600,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      await _loadCount();
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      appBar: AppBar(
        title: const Text('Dashboard Kurir', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: theme.colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isSyncing 
                ? const SizedBox(
                    width: 20, height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1565C0))
                  )
                : const Icon(Icons.sync),
            onPressed: _isSyncing ? null : _performSync,
            tooltip: 'Sync Data',
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildSidebar(theme),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _performSync,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Bertugas!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B), // Slate 800
                  ),
                ).animate().fadeIn().slideX(),
                const SizedBox(height: 8),
                Text(
                  'Pantau dan selesaikan pengiriman surat hari ini.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B), // Slate 500
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(),
                
                const SizedBox(height: 24),
                
                // Stats Row
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Menunggu Diantar', '${_count ?? 0}', Colors.orange.shade700, Icons.local_shipping_outlined, 400.ms)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('Selesai Hari Ini', '0', Colors.green.shade600, Icons.check_circle_outline, 600.ms)),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  'Aktivitas Terbaru',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 800.ms),
                const SizedBox(height: 16),
                
                _isSyncing 
                  ? const LinearProgressIndicator(backgroundColor: Color(0xFFE2E8F0)).animate().fadeIn()
                  : const SizedBox.shrink(),
                  
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                    ),
                  ),
                  
                // List of Expeditions
                if (!_isSyncing && _expeditions.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _expeditions.length,
                    itemBuilder: (context, index) {
                      final item = _expeditions[index];
                      Color statusColor = Colors.orange;
                      if (item.status == 'diterima') statusColor = Colors.green;
                      if (item.status == 'draft') statusColor = Colors.grey;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: statusColor.withOpacity(0.1),
                            child: Icon(Icons.mail_outline, color: statusColor, size: 20),
                          ),
                          title: Text(
                            item.nomorSurat ?? 'EKS-Tanpa-Nomor',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Perihal: ${item.perihal}'),
                              Text('Tujuan: ${item.divisiTujuan}'),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ExpeditionDetailPage(expedition: item),
                              ),
                            );
                            _loadCount();
                          },
                        ),
                      ).animate().fadeIn(delay: (index * 100).ms);
                    },
                  ),

                // Empty state
                if (!_isSyncing && _expeditions.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('Belum ada surat yang perlu diantar', style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 1000.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon, Duration animDelay) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    ).animate().scale(delay: animDelay, duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildSidebar(ThemeData theme) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1565C0)),
            accountName: const Text('Kurir Aktif', style: TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: const Text('Status: Online & Tersinkronisasi'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFF1565C0), size: 36),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'DAFTAR KIRIMAN',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // Actual list in Drawer
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _expeditions.length,
              itemBuilder: (context, index) {
                final item = _expeditions[index];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF1F5F9),
                    child: Icon(Icons.mail_outline, size: 20, color: Color(0xFF64748B)),
                  ),
                  title: Text(item.nomorSurat ?? 'EKS-Tanpa-Nomor'),
                  subtitle: Text('Tujuan: ${item.divisiTujuan}'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    // Navigate to detail
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
