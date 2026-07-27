import 'package:flutter/material.dart';

import '../../core/config/app_constants.dart';
import '../expeditions/data/expedition_model.dart';
import '../home/widgets/surat_task_card.dart';

class HistoryPage extends StatelessWidget {
  final List<Expedition> suratList;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Expedition) onOpen;

  const HistoryPage({
    super.key,
    required this.suratList,
    required this.onRefresh,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final items = suratList
        .where((item) => item.status == ExpeditionStatus.diterima)
        .toList()
      ..sort((a, b) => (b.tanggalDiterima ?? b.createdAt ?? '')
          .compareTo(a.tanggalDiterima ?? a.createdAt ?? ''));
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Riwayat pengiriman',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${items.length} surat telah selesai dikirim.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (items.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'Belum ada riwayat pengiriman.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              sliver: SliverList.builder(
                itemCount: items.length,
                itemBuilder: (context, index) => SuratTaskCard(
                  surat: items[index],
                  onTap: () => onOpen(items[index]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
