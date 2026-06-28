import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../expeditions/data/expedition_repository.dart';

/// Halaman beranda sementara — memverifikasi fondasi (DI + SQLite) berjalan.
///
/// Akan digantikan oleh alur Login → Daftar Surat pada iterasi berikutnya.
class HomePage extends StatefulWidget {
  final bool isConfigured;

  const HomePage({super.key, required this.isConfigured});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? _count;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    try {
      // Membaca dari SQLite via repository membuktikan DB + DI siap.
      final repo = sl<ExpeditionRepository>();
      final items = await repo.getAll();
      if (mounted) setState(() => _count = items.length);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Buku Ekspedisi Digital')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mark_email_read_outlined,
                  size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('Fondasi siap',
                  style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              _StatusRow(
                label: 'Konfigurasi Supabase',
                value: widget.isConfigured ? 'Terisi' : 'Belum diset',
                ok: widget.isConfigured,
              ),
              _StatusRow(
                label: 'Database lokal (SQLite)',
                value: _error != null
                    ? 'Error'
                    : _count == null
                        ? 'Memuat...'
                        : 'OK — $_count surat',
                ok: _error == null && _count != null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final bool ok;

  const _StatusRow({
    required this.label,
    required this.value,
    required this.ok,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ok ? Icons.check_circle : Icons.error_outline,
              size: 18,
              color: ok ? Colors.green : Theme.of(context).colorScheme.error),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}
