import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/gold_button.dart';
import '../../core/widgets/luxe_card.dart';
import '../../state/monetization_provider.dart';

class RemoveAdsCard extends ConsumerWidget {
  const RemoveAdsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monetizationProvider);
    final controller = ref.read(monetizationProvider.notifier);

    if (state.adsRemoved) {
      return LuxeCard(
        borderColor: AppColors.good.withValues(alpha: 0.5),
        color: AppColors.goodSoft,
        child: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.good, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bebas Iklan Aktif',
                    style: AppTheme.sans(size: 14, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Terima kasih telah mendukung Arunika.',
                    style: AppTheme.sans(size: 11.5, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final isBusy = state.isVerifying;
    final price = state.productPrice ?? 'US\$4.99';
    final statusMessage =
        state.message ??
        (state.isVerifying
            ? 'Menghubungkan ke Google Play…'
            : state.storeAvailable
            ? 'Pembayaran sekali · tanpa langganan'
            : 'Buka dari Google Play untuk melanjutkan.');
    return LuxeCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 13),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFFBF4E2)],
      ),
      borderColor: AppColors.goldSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconTile(
                icon: Icons.auto_awesome_rounded,
                color: AppColors.gold,
                size: 44,
                iconSize: 21,
                radius: 14,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bebas Iklan',
                      style: AppTheme.serif(size: 17, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Satu kali bayar untuk ruang keluarga yang lebih tenang.',
                      style: AppTheme.sans(
                        size: 11.5,
                        color: AppColors.inkSoft,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.goldMist,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.goldSoft),
                ),
                child: Text(
                  price,
                  style: AppTheme.sans(
                    size: 11,
                    weight: FontWeight.w800,
                    color: AppColors.goldDeep,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(
                child: _Benefit(
                  icon: Icons.hide_source_rounded,
                  label: 'Tanpa banner',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _Benefit(
                  icon: Icons.payments_outlined,
                  label: 'Sekali bayar',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _Benefit(
                  icon: Icons.restore_rounded,
                  label: 'Pulihkan kapan saja',
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          _PurchaseStatus(
            message: statusMessage,
            isError: state.message != null,
          ),
          const SizedBox(height: 13),
          GoldButton(
            label: isBusy
                ? 'Menghubungkan ke Play Store'
                : state.storeAvailable
                ? 'Beli sekali • $price'
                : 'Coba lagi di Play Store',
            icon: Icons.shield_moon_rounded,
            isLoading: isBusy,
            onPressed: isBusy ? null : controller.buyRemoveAds,
            dense: true,
          ),
          const SizedBox(height: 3),
          Center(
            child: TextButton(
              onPressed: isBusy ? null : controller.restorePurchases,
              child: const Text('Sudah pernah membeli? Pulihkan'),
            ),
          ),
        ],
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
    return Column(
      children: [
        Icon(icon, size: 17, color: AppColors.goldDeep),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.sans(
            size: 9.5,
            weight: FontWeight.w700,
            color: AppColors.inkSoft,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _PurchaseStatus extends StatelessWidget {
  const _PurchaseStatus({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.danger : AppColors.sageDeep;
    final background = isError ? AppColors.dangerSoft : AppColors.sageMist;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.info_outline_rounded : Icons.lock_outline_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTheme.sans(
                size: 10.5,
                weight: FontWeight.w600,
                color: color,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
