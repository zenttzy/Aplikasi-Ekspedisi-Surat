import 'package:flutter/material.dart';

import '../../core/config/app_constants.dart';
import '../expeditions/data/expedition_model.dart';
import '../home/widgets/surat_task_card.dart';

class ActivityPage extends StatefulWidget {
  final List<Expedition> suratList;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Expedition) onTake;
  final Future<void> Function(Expedition) onOpen;

  const ActivityPage({
    super.key,
    required this.suratList,
    required this.onRefresh,
    required this.onTake,
    required this.onOpen,
  });

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  int _filterIndex = 0;

  List<Expedition> get _items {
    return switch (_filterIndex) {
      1 => widget.suratList
          .where((item) => item.status == ExpeditionStatus.draft)
          .toList(),
      2 => widget.suratList
          .where((item) => item.status == ExpeditionStatus.dikirim)
          .toList(),
      _ => widget.suratList
          .where((item) => item.status != ExpeditionStatus.diterima)
          .toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aktivitas pengiriman',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kelola surat baru dan pengiriman yang sedang berjalan.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Semua')),
                      ButtonSegment(value: 1, label: Text('Baru')),
                      ButtonSegment(value: 2, label: Text('Dikirim')),
                    ],
                    selected: {_filterIndex},
                    onSelectionChanged: (value) {
                      setState(() => _filterIndex = value.first);
                    },
                    showSelectedIcon: false,
                  ),
                ],
              ),
            ),
          ),
          if (_items.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyActivity(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              sliver: SliverList.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final surat = _items[index];
                  return SuratTaskCard(
                    surat: surat,
                    onTap: () => widget.onOpen(surat),
                    onTake: surat.status == ExpeditionStatus.draft
                        ? () => widget.onTake(surat)
                        : null,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.task_alt_outlined,
                size: 36,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Semua tugas sudah tertangani',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tarik layar ke bawah untuk memeriksa surat terbaru.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
