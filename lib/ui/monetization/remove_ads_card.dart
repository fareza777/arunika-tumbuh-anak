import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/monetization_provider.dart';

class RemoveAdsCard extends ConsumerWidget {
  const RemoveAdsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monetizationProvider);
    final controller = ref.read(monetizationProvider.notifier);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final price = state.productPrice;
    final canPurchase =
        state.storeAvailable && price != null && price.trim().isNotEmpty;
    final status =
        state.message ??
        (state.isVerifying
            ? 'Memeriksa pembelian dan harga di Google Play…'
            : canPurchase
            ? 'Pembayaran sekali, tanpa langganan.'
            : 'Harga belum tersedia. Hubungkan ke Google Play untuk memuatnya.');

    return Card(
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    state.adsRemoved
                        ? Icons.verified_outlined
                        : Icons.hide_source_rounded,
                    color: state.adsRemoved ? colors.secondary : colors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    state.adsRemoved ? 'Bebas Iklan Aktif' : 'Bebas Iklan',
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              state.adsRemoved
                  ? 'Terima kasih telah mendukung Arunika. Nikmati jurnal keluarga tanpa iklan.'
                  : 'Satu kali bayar untuk menghapus iklan. Jurnal, kebiasaan, dan kenangan tetap gratis.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (!state.adsRemoved) ...[
              const SizedBox(height: 16),
              const _Benefit(
                icon: Icons.hide_source_rounded,
                label: 'Tanpa semua jenis iklan',
              ),
              const _Benefit(
                icon: Icons.payments_outlined,
                label: 'Sekali bayar',
              ),
              const _Benefit(
                icon: Icons.restore_rounded,
                label: 'Pulihkan kapan saja',
              ),
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 52),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onPressed: state.isVerifying
                      ? null
                      : canPurchase
                      ? controller.buyRemoveAds
                      : controller.reconnectStore,
                  child: Text(
                    state.isVerifying
                        ? 'Memproses…'
                        : canPurchase
                        ? 'Beli sekali · $price'
                        : 'Hubungkan ke Google Play',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onPressed: state.isVerifying
                      ? null
                      : controller.restorePurchases,
                  child: const Text(
                    'Pulihkan pembelian',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(icon, size: 18, color: theme.colorScheme.secondary),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
