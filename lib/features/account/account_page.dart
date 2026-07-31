import 'package:flutter/material.dart';

class AccountPage extends StatelessWidget {
  final String name;
  final String email;
  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  final Future<void> Function() onSync;
  final VoidCallback onOpenGuide;
  final Future<void> Function() onLogout;

  final String? divisiNama;
  final String? assignedTuNama;

  const AccountPage({
    super.key,
    required this.name,
    required this.email,
    this.divisiNama,
    this.assignedTuNama,
    required this.isOnline,
    required this.isSyncing,
    required this.pendingCount,
    required this.onSync,
    required this.onOpenGuide,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = name.trim().isEmpty ? 'K' : name.trim()[0].toUpperCase();
    final hasDivision = divisiNama?.trim().isNotEmpty == true;
    final hasAssignedTu = assignedTuNama?.trim().isNotEmpty == true;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        Text(
          'Akun',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Kurir' : name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Divisi: ${hasDivision ? divisiNama!.trim() : 'Belum ditugaskan'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: hasDivision
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Penanggung Jawab: ${hasAssignedTu ? assignedTuNama!.trim() : 'Belum ditugaskan'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: hasAssignedTu
                              ? const Color(0xFF16A34A)
                              : theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Chip(
                        avatar: Icon(Icons.verified_user_outlined, size: 17),
                        label: Text('Kurir aktif'),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Penyimpanan & sinkronisasi',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.menu_book_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Cara Pemakaian'),
                subtitle: const Text('Panduan langkah penggunaan aplikasi kurir'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onOpenGuide,
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  isOnline ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                  color: isOnline
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFF59E0B),
                ),
                title: Text(isOnline ? 'Terhubung ke server' : 'Mode offline'),
                subtitle: Text(
                  pendingCount == 0
                      ? 'Semua perubahan sudah tersinkron'
                      : '$pendingCount perubahan tersimpan di perangkat',
                ),
                trailing: isSyncing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        tooltip: 'Sinkronkan sekarang',
                        onPressed: isOnline ? onSync : null,
                        icon: const Icon(Icons.sync),
                      ),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.notifications_outlined),
                title: Text('Notifikasi'),
                subtitle: Text('Aktif untuk surat baru'),
                trailing: Icon(Icons.check_circle, color: Color(0xFF16A34A)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFFDC2626)),
                title: const Text(
                  'Keluar dari akun',
                  style: TextStyle(color: Color(0xFFDC2626)),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: onLogout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
