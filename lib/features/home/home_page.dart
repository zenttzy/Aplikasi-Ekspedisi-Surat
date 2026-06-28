import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/di/service_locator.dart';
import '../expeditions/data/expedition_repository.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCount();
    // Simulate auto-sync on init
    _simulateAutoSync();
  }

  Future<void> _loadCount() async {
    try {
      final repo = sl<ExpeditionRepository>();
      final items = await repo.getAll();
      if (mounted) setState(() => _count = items.length);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _simulateAutoSync() async {
    setState(() => _isSyncing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isSyncing = false);
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
            onPressed: _isSyncing ? null : _simulateAutoSync,
            tooltip: 'Sync Data',
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildSidebar(theme),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _simulateAutoSync,
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                  ),
                  
                // Empty state for now
                if (!_isSyncing && _count == 0)
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
          // Placeholder for list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _count ?? 0,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF1F5F9),
                    child: Icon(Icons.mail_outline, size: 20, color: Color(0xFF64748B)),
                  ),
                  title: Text('Surat EKS-${index + 1}'),
                  subtitle: const Text('Tujuan: Divisi SDM'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    // TODO: Navigate to detail
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
