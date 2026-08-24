import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/moment.dart';
import '../../data/models/ritual.dart';
import '../../domain/together/together_copy.dart';
import '../../state/app_settings.dart';
import '../../state/together_providers.dart';
import '../widgets/editorial_background.dart';
import '../widgets/editorial_card.dart';
import '../widgets/ritual_check.dart';
import '../widgets/sunrise_progress.dart';
import '../widgets/tag_chip.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({
    super.key,
    required this.onOpenMoment,
    required this.onOpenRitual,
    this.onOpenGarden,
  });

  final VoidCallback onOpenMoment;
  final VoidCallback onOpenRitual;
  final VoidCallback? onOpenGarden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final member = ref.watch(activeFamilyMemberProvider);
    final rituals = ref.watch(todayRitualsProvider);
    final completed = ref.watch(todayCompletedRitualIdsProvider);
    final moments = ref.watch(momentsProvider);
    final recap = ref.watch(recapProvider);
    final now = DateTime.now();
    final date = DateFormat('EEEE, d MMMM', 'id_ID').format(now);

    return EditorialBackground(
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.terracotta,
          onRefresh: () async {
            ref.invalidate(todayRitualsProvider);
            ref.invalidate(todayCompletedRitualIdsProvider);
            ref.invalidate(momentsProvider);
            ref.invalidate(recapProvider);
            await Future<void>.delayed(const Duration(milliseconds: 180));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 118),
            children: [
              _TodayHeader(
                date: date,
                familyName: settings.familyName,
                memberName: member?.name,
              ),
              const SizedBox(height: 24),
              _SunriseHero(
                familyName: settings.familyName,
                rituals: rituals,
                completed: completed,
                onOpenRitual: onOpenRitual,
              ),
              const SizedBox(height: 22),
              _SectionHeader(
                eyebrow: 'LANGKAH HARI INI',
                title: 'Ritual yang menunggu',
                actionLabel: 'Lihat semua',
                onAction: onOpenRitual,
              ),
              const SizedBox(height: 11),
              _NextRitualCard(
                rituals: rituals.valueOrNull ?? const [],
                completed: completed.valueOrNull ?? const {},
                loading: rituals.isLoading || completed.isLoading,
                onOpenRitual: onOpenRitual,
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                eyebrow: 'SEPEKAN DALAM CERITA',
                title: 'Recap kecil untuk kalian',
                actionLabel: 'Buka Taman',
                onAction: onOpenGarden ?? onOpenRitual,
              ),
              const SizedBox(height: 11),
              _RecapStrip(recap: recap),
              const SizedBox(height: 24),
              _SectionHeader(
                eyebrow: 'MOMEN TERBARU',
                title: 'Yang ingin diingat',
                actionLabel: 'Tambah momen',
                onAction: onOpenMoment,
              ),
              const SizedBox(height: 11),
              _LatestMoment(
                moments: moments.valueOrNull ?? const [],
                loading: moments.isLoading,
                onOpenMoment: onOpenMoment,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayHeader extends StatelessWidget {
  const _TodayHeader({
    required this.date,
    required this.familyName,
    this.memberName,
  });

  final String date;
  final String familyName;
  final String? memberName;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: AppTheme.sans(
                  size: 12,
                  weight: FontWeight.w700,
                  color: AppColors.terracottaDeep,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                '${greetingFor(DateTime.now())}, ${memberName ?? familyName}.',
                style: AppTheme.serif(
                  size: 28,
                  weight: FontWeight.w600,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Mari beri ruang untuk yang penting hari ini.',
                style: AppTheme.sans(
                  size: 12.5,
                  color: AppColors.inkSoft,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.paper,
            border: Border.all(color: AppColors.goldSoft),
          ),
          child: const PhosphorIcon(
            PhosphorIconsLight.sun,
            color: AppColors.goldDeep,
            size: 24,
          ),
        ),
      ],
    );
  }
}

class _SunriseHero extends StatelessWidget {
  const _SunriseHero({
    required this.familyName,
    required this.rituals,
    required this.completed,
    required this.onOpenRitual,
  });

  final String familyName;
  final AsyncValue<List<Ritual>> rituals;
  final AsyncValue<Set<String>> completed;
  final VoidCallback onOpenRitual;

  @override
  Widget build(BuildContext context) {
    final list = rituals.valueOrNull ?? const <Ritual>[];
    final done = completed.valueOrNull ?? const <String>{};
    final progress = list.isEmpty
        ? 0.0
        : done.intersection(list.map((e) => e.id).toSet()).length / list.length;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.sunrise,
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppColors.softShadow(opacity: 0.14, blur: 26, y: 12),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -34,
            child: Icon(
              PhosphorIconsLight.sunHorizon,
              size: 132,
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const PhosphorIcon(
                    PhosphorIconsLight.sun,
                    size: 21,
                    color: AppColors.espresso,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ENERGI HARI INI',
                    style: AppTheme.sans(
                      size: 10,
                      weight: FontWeight.w800,
                      color: AppColors.espresso,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                list.isEmpty
                    ? 'Satu ruang kosong\nuntuk cerita baru.'
                    : '${ritualCountCopy(done.length, list.length)}.',
                style: AppTheme.serif(
                  size: 26,
                  weight: FontWeight.w600,
                  color: AppColors.espresso,
                  height: 1.13,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                list.isEmpty
                    ? 'Mulai dengan satu kebiasaan yang terasa sederhana.'
                    : 'Setiap tanda hadir membuat ${familyName.toLowerCase()} terasa lebih dekat.',
                style: AppTheme.sans(
                  size: 12.5,
                  color: AppColors.espresso.withValues(alpha: 0.76),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              SunriseProgress(value: progress, height: 8),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '${(progress * 100).round()}% hari ini',
                    style: AppTheme.sans(
                      size: 11,
                      weight: FontWeight.w800,
                      color: AppColors.espresso,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onOpenRitual,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.espresso,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(44, 32),
                    ),
                    child: Text(
                      list.isEmpty ? 'Buat ritual' : 'Rayakan',
                      style: AppTheme.sans(
                        size: 11,
                        weight: FontWeight.w800,
                        color: AppColors.espresso,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String eyebrow;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EditorialEyebrow(eyebrow),
              const SizedBox(height: 5),
              Text(
                title,
                style: AppTheme.serif(size: 21, weight: FontWeight.w600),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(
            actionLabel,
            style: AppTheme.sans(
              size: 11,
              weight: FontWeight.w800,
              color: AppColors.terracottaDeep,
            ),
          ),
        ),
      ],
    );
  }
}

class _NextRitualCard extends ConsumerWidget {
  const _NextRitualCard({
    required this.rituals,
    required this.completed,
    required this.loading,
    required this.onOpenRitual,
  });

  final List<Ritual> rituals;
  final Set<String> completed;
  final bool loading;
  final VoidCallback onOpenRitual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (loading) {
      return const EditorialCard(
        child: SizedBox(
          height: 72,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }
    final next = rituals.cast<Ritual?>().firstWhere(
      (ritual) => !completed.contains(ritual!.id),
      orElse: () => null,
    );
    if (next == null) {
      return EditorialCard(
        color: AppColors.sageMist,
        onTap: onOpenRitual,
        semanticLabel: 'Semua ritual hari ini selesai',
        child: Row(
          children: [
            const RitualCheck(value: true, onChanged: _noop),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                'Hari ini sudah diberi ruang.\nTerima kasih sudah hadir.',
                style: AppTheme.sans(
                  size: 13.5,
                  weight: FontWeight.w700,
                  color: AppColors.sageDeep,
                  height: 1.45,
                ),
              ),
            ),
            const PhosphorIcon(
              PhosphorIconsLight.arrowRight,
              size: 20,
              color: AppColors.sageDeep,
            ),
          ],
        ),
      );
    }
    final ritual = next;
    return EditorialCard(
      onTap: onOpenRitual,
      semanticLabel: 'Ritual berikutnya ${ritual.title}',
      child: Row(
        children: [
          RitualCheck(
            value: false,
            onChanged: (value) => ref
                .read(togetherActionsProvider)
                .setRitualCheckIn(ritual.id, value),
            label: 'Rayakan ${ritual.title}',
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ritual.timeOfDay.label,
                  style: AppTheme.sans(
                    size: 10,
                    weight: FontWeight.w800,
                    color: AppColors.terracottaDeep,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  ritual.title,
                  style: AppTheme.serif(size: 19, weight: FontWeight.w600),
                ),
                if (ritual.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    ritual.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.sans(
                      size: 11.5,
                      color: AppColors.inkSoft,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          const PhosphorIcon(
            PhosphorIconsLight.arrowUpRight,
            size: 21,
            color: AppColors.inkFaint,
          ),
        ],
      ),
    );
  }

  static void _noop(bool _) {}
}

class _RecapStrip extends StatelessWidget {
  const _RecapStrip({required this.recap});

  final AsyncValue<dynamic> recap;

  @override
  Widget build(BuildContext context) {
    return recap.when(
      loading: () => const SizedBox(
        height: 114,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => const EditorialCard(
        child: Text('Recap akan muncul setelah ada cerita pertama.'),
      ),
      data: (value) => SizedBox(
        height: 150,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: value.cards.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, index) {
            final card = value.cards[index];
            final colors = [
              AppColors.sageMist,
              AppColors.terracottaMist,
              AppColors.lavenderMist,
            ];
            return SizedBox(
              width: 235,
              child: EditorialCard(
                color: colors[index % colors.length],
                shadow: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EditorialEyebrow(card.eyebrow, color: AppColors.sageDeep),
                    const Spacer(),
                    Text(
                      card.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.serif(
                        size: 18,
                        weight: FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      card.detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.sans(
                        size: 11,
                        color: AppColors.inkSoft,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LatestMoment extends StatelessWidget {
  const _LatestMoment({
    required this.moments,
    required this.loading,
    required this.onOpenMoment,
  });

  final List<Moment> moments;
  final bool loading;
  final VoidCallback onOpenMoment;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const EditorialCard(
        child: SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }
    if (moments.isEmpty) {
      return EditorialCard(
        onTap: onOpenMoment,
        semanticLabel: 'Catat momen pertama',
        color: AppColors.paper,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.terracottaMist,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const PhosphorIcon(
                PhosphorIconsLight.images,
                color: AppColors.terracottaDeep,
                size: 25,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Simpan satu kalimat dari hari ini.',
                style: AppTheme.sans(
                  size: 13.5,
                  weight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ),
            const PhosphorIcon(
              PhosphorIconsLight.plus,
              color: AppColors.terracottaDeep,
            ),
          ],
        ),
      );
    }
    final moment = moments.first;
    return EditorialCard(
      onTap: onOpenMoment,
      semanticLabel: 'Momen ${moment.title}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.goldMist,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const PhosphorIcon(
              PhosphorIconsLight.sparkle,
              color: AppColors.goldDeep,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MomentTagChip(tag: moment.tag),
                    const Spacer(),
                    Text(
                      DateFormat('d MMM', 'id_ID').format(moment.capturedAt),
                      style: AppTheme.sans(
                        size: 10,
                        color: AppColors.inkFaint,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  moment.title,
                  style: AppTheme.serif(size: 18, weight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  moment.note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.sans(
                    size: 11.5,
                    color: AppColors.inkSoft,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
