import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/monetization_provider.dart';

/// An optional ad exchange; every journal feature remains available without it.
class RewardedBreakCard extends ConsumerWidget {
  const RewardedBreakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(rewardedAdManagerProvider).isEnabled) {
      return const SizedBox.shrink();
    }
    final state = ref.watch(monetizationProvider);
    if (state.adsRemoved) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final paused = state.adPauseUntil != null;
    final status =
        state.rewardedMessage ??
        (state.rewardedAvailable
            ? 'Pilihan ini sepenuhnya sukarela. Semua fitur tetap gratis.'
            : 'Iklan untuk jeda belum tersedia saat ini. Semua fitur tetap gratis.');

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
                    Icons.pause_circle_outline,
                    color: colors.secondary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    paused ? 'Jeda iklan aktif' : 'Jeda iklan 30 menit',
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              paused
                  ? 'Banner dan iklan setelah menyimpan dijeda. Sisa sekitar ${state.adPauseMinutesRemaining} menit.'
                  : 'Tonton satu iklan hingga hadiah diperoleh untuk jeda 30 menit tanpa banner dan iklan setelah menyimpan.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                status,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            if (!paused) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 52),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onPressed: !state.rewardedAvailable || state.isRewardedBusy
                      ? null
                      : () async {
                          final route = ModalRoute.of(context);
                          await ref
                              .read(monetizationProvider.notifier)
                              .watchRewardedBreak(
                                canPresent: () =>
                                    context.mounted &&
                                    (route?.isCurrent ?? false) &&
                                    WidgetsBinding.instance.lifecycleState ==
                                        AppLifecycleState.resumed,
                              );
                        },
                  child: Text(
                    state.isRewardedBusy
                        ? 'Memuat iklan…'
                        : state.rewardedAvailable
                        ? 'Tonton untuk jeda 30 menit'
                        : 'Iklan belum tersedia',
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
