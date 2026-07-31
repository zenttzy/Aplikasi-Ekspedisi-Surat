import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_constants.dart';
import '../../expeditions/data/expedition_model.dart';

class SuratTaskCard extends StatelessWidget {
  final Expedition surat;
  final VoidCallback onTap;
  final VoidCallback? onTake;

  const SuratTaskCard({
    super.key,
    required this.surat,
    required this.onTap,
    this.onTake,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDraft = surat.status == ExpeditionStatus.draft;
    final statusColor = switch (surat.status) {
      ExpeditionStatus.dikirim => const Color(0xFFF59E0B),
      ExpeditionStatus.diterima => const Color(0xFF16A34A),
      _ => theme.colorScheme.primary,
    };
    final statusLabel = switch (surat.status) {
      ExpeditionStatus.dikirim => 'Dalam pengiriman',
      ExpeditionStatus.diterima => 'Selesai',
      _ => 'Tugas baru',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isDraft
                          ? Icons.mark_email_unread_outlined
                          : Icons.local_shipping_outlined,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          surat.nomorSurat ?? 'Tanpa nomor surat',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          surat.perihal,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _RouteRow(
                icon: Icons.apartment_outlined,
                label: surat.divisiPengirim.isEmpty
                    ? 'Divisi pengirim belum tersedia'
                    : surat.divisiPengirim,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 9),
                child: SizedBox(
                  height: 14,
                  child: VerticalDivider(width: 1, thickness: 1),
                ),
              ),
              _RouteRow(
                icon: Icons.location_on_outlined,
                label: surat.divisiTujuan.isEmpty
                    ? 'Divisi tujuan belum tersedia'
                    : surat.divisiTujuan,
              ),
              if (surat.pendingTake || surat.needsUpload) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 16,
                        color: Color(0xFFC2410C),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Menunggu sinkronisasi',
                        style: TextStyle(
                          color: Color(0xFF9A3412),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(surat.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const Spacer(),
                  if (isDraft && onTake != null)
                    FilledButton.icon(
                      onPressed: onTake,
                      icon: const Icon(Icons.delivery_dining_outlined, size: 18),
                      label: const Text('Ambil tugas'),
                    )
                  else
                    TextButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Detail'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null) return 'Tanggal belum tersedia';
    try {
      return DateFormat('dd MMM yyyy, HH:mm', 'id')
          .format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RouteRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
