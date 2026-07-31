import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/config/app_constants.dart';
import '../../core/di/service_locator.dart';
import '../../core/sync/sync_manager.dart';
import '../account/account_page.dart';
import '../account/usage_guide_page.dart';
import '../activity/activity_page.dart';
import '../auth/data/auth_repository.dart';
import '../auth/presentation/login_page.dart';
import '../dashboard/dashboard_page.dart';
import '../expeditions/data/expedition_model.dart';
import '../expeditions/data/expedition_repository.dart';
import '../expeditions/presentation/surat_detail_page.dart';
import '../history/history_page.dart';

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
  String _courierName = 'Kurir';
  String _courierEmail = '';
  String? _divisiNama;
  String? _assignedTuNama;
  int _selectedIndex = 0;
  int _newTaskCount = 0;
  Set<String> _knownUuids = {};
  SyncState _syncState = const SyncState(
    isOnline: false,
    isSyncing: false,
    pendingCount: 0,
  );
  StreamSubscription<SyncState>? _syncSubscription;

  @override
  void initState() {
    super.initState();
    _initializeOfflineFirst();
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeOfflineFirst() async {
    final syncManager = sl<SyncManager>();
    _syncSubscription = syncManager.states.listen((state) async {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        setState(() => _syncState = state);
        await _loadLocalData();
        if (state.error != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
      });
    });

    final user = await sl<AuthRepository>().getCurrentUser();
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _courierName = user?['nama_lengkap'] as String? ?? 'Kurir';
          _courierEmail = user?['email'] as String? ?? '';
          _divisiNama = user?['divisi_nama'] as String?;
          _assignedTuNama = user?['assigned_tu_nama'] as String?;
        });
      });
    }

    await _loadLocalData(initial: true);
    await syncManager.start();
  }

  void _openUsageGuide() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UsageGuidePage()),
    );
  }

  Future<void> _loadLocalData({bool initial = false}) async {
    if (initial && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _loading = true;
          _error = null;
        });
      });
    }

    try {
      final list = await sl<ExpeditionRepository>().getAll();
      if (!mounted) return;
      final incoming = _knownUuids.isEmpty
          ? <Expedition>[]
          : list.where((item) => !_knownUuids.contains(item.uuid)).toList();
      setState(() {
        _suratList = list;
        _knownUuids = list.map((item) => item.uuid).toSet();
        _newTaskCount += incoming
            .where((item) => item.status == ExpeditionStatus.draft)
            .length;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _refresh() async {
    await sl<SyncManager>().syncAll();
    await _loadLocalData();
  }

  Future<void> _takeSurat(Expedition surat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delivery_dining_outlined),
        title: const Text('Ambil tugas pengiriman?'),
        content: Text(
          'Surat ${surat.nomorSurat ?? surat.perihal} akan disimpan sebagai tugas Anda, termasuk saat offline.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ambil tugas'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final result = await sl<SyncManager>().takeSurat(surat);
      await _loadLocalData();
      if (!mounted) return;
      setState(() => _selectedIndex = 1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.synced
                ? 'Tugas berhasil diambil dan tersinkron.'
                : 'Tugas disimpan offline dan akan tersinkron otomatis.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil tugas: $error')),
      );
    }
  }

  Future<void> _openDetail(Expedition surat) async {
    final latest = await sl<ExpeditionRepository>().getByUuid(surat.uuid) ?? surat;
    if (!mounted) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SuratDetailPage(expedition: latest),
      ),
    );
    if (changed == true) await _loadLocalData();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: _syncState.pendingCount > 0
            ? Text(
                '${_syncState.pendingCount} perubahan masih pending. Sebaiknya tunggu tersinkron sebelum keluar.',
              )
            : const Text('Anda perlu login kembali untuk menerima tugas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await sl<AuthRepository>().logout();
    await sl<ExpeditionRepository>().clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LoginPage(isConfigured: widget.isConfigured),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        courierName: _courierName,
        suratList: _suratList,
        onRefresh: _refresh,
        onTake: _takeSurat,
        onOpen: _openDetail,
        onViewActivities: () => setState(() {
          _selectedIndex = 1;
          _newTaskCount = 0;
        }),
      ),
      ActivityPage(
        suratList: _suratList,
        onRefresh: _refresh,
        onTake: _takeSurat,
        onOpen: _openDetail,
      ),
      HistoryPage(
        suratList: _suratList,
        onRefresh: _refresh,
        onOpen: _openDetail,
      ),
      AccountPage(
        name: _courierName,
        email: _courierEmail,
        divisiNama: _divisiNama,
        assignedTuNama: _assignedTuNama,
        isOnline: _syncState.isOnline,
        isSyncing: _syncState.isSyncing,
        pendingCount: _syncState.pendingCount,
        onSync: _refresh,
        onOpenGuide: _openUsageGuide,
        onLogout: _logout,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.mail_outline, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Ekspedisi Surat'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sinkronkan',
            onPressed: _syncState.isSyncing ? null : _refresh,
            icon: _syncState.isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync),
          ),
        ],
      ),
      body: Column(
        children: [
          _SyncBanner(state: _syncState),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorView(error: _error!, onRetry: _loadLocalData)
                    : IndexedStack(index: _selectedIndex, children: pages),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
            if (index == 1) _newTaskCount = 0;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: _newTaskCount > 0
                ? Badge(
                    label: Text('$_newTaskCount'),
                    child: const Icon(Icons.route_outlined),
                  )
                : const Icon(Icons.route_outlined),
            selectedIcon: const Icon(Icons.route),
            label: 'Aktivitas',
          ),
          const NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}

class _SyncBanner extends StatelessWidget {
  final SyncState state;

  const _SyncBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isOnline && !state.isSyncing && state.pendingCount == 0) {
      return const SizedBox.shrink();
    }

    final color = !state.isOnline
        ? const Color(0xFFF59E0B)
        : state.pendingCount > 0
            ? Theme.of(context).colorScheme.primary
            : const Color(0xFF0284C7);
    final icon = !state.isOnline
        ? Icons.cloud_off_outlined
        : state.isSyncing
            ? Icons.sync
            : Icons.cloud_upload_outlined;
    final text = !state.isOnline
        ? 'Mode offline • ${state.pendingCount} perubahan menunggu sinkronisasi'
        : state.isSyncing
            ? 'Menyinkronkan data dengan server...'
            : '${state.pendingCount} perubahan menunggu sinkronisasi';

    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storage_outlined, size: 52),
            const SizedBox(height: 14),
            const Text(
              'Data lokal belum dapat dibuka',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
