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
    return LuxeCard(
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
            children: [
              const IconTile(
                icon: Icons.auto_awesome_rounded,
                color: AppColors.gold,
              ),
              const SizedBox(width: 14),
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
                      'Nikmati Arunika tanpa iklan dengan satu pembelian.',
                      style: AppTheme.sans(
                        size: 11.5,
                        color: AppColors.inkSoft,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (state.message != null) ...[
            const SizedBox(height: 12),
            Text(
              state.message!,
              style: AppTheme.sans(
                size: 11.5,
                color: AppColors.danger,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 16),
          GoldButton(
            label: isBusy
                ? 'Memeriksa Play Store'
                : 'Hapus Iklan • ${state.productPrice ?? 'US\$4.99'}',
            icon: Icons.shield_moon_rounded,
            isLoading: isBusy,
            onPressed: isBusy ? null : controller.buyRemoveAds,
            dense: true,
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: isBusy ? null : controller.restorePurchases,
              child: const Text('Pulihkan pembelian'),
            ),
          ),
        ],
      ),
    );
  }
}
