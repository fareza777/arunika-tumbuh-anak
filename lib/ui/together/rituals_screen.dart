import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ritual.dart';
import '../../state/together_providers.dart';
import '../widgets/editorial_background.dart';
import '../widgets/editorial_card.dart';
import '../widgets/ritual_check.dart';
import 'ritual_editor_sheet.dart';

class RitualsScreen extends ConsumerWidget {
  const RitualsScreen({super.key, required this.onOpenRitual});

  final VoidCallback onOpenRitual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rituals = ref.watch(ritualsProvider);
    final completed = ref.watch(todayCompletedRitualIdsProvider);
    return EditorialBackground(
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.sageDeep,
          onRefresh: () async {
            ref.invalidate(ritualsProvider);
            ref.invalidate(todayCompletedRitualIdsProvider);
            await Future<void>.delayed(const Duration(milliseconds: 180));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 118),
            children: [
              _PageHeader(onAdd: onOpenRitual),
              const SizedBox(height: 24),
              rituals.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, _) => const EditorialCard(
                  child: Text('Ritual belum dapat dimuat. Coba lagi sebentar.'),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return _EmptyRituals(onAdd: onOpenRitual);
                  }
                  return completed.when(
                    loading: () => Column(
                      children: items
                          .map(
                            (ritual) => _RitualTile(
                              ritual: ritual,
                              completed: false,
                              onEdit: () => _edit(context, ritual),
                            ),
                          )
                          .toList(),
                    ),
                    error: (_, _) => Column(
                      children: items
                          .map(
                            (ritual) => _RitualTile(
                              ritual: ritual,
                              completed: false,
                              onEdit: () => _edit(context, ritual),
                            ),
                          )
                          .toList(),
                    ),
                    data: (done) => Column(
                      children: [
                        for (final ritual in items) ...[
                          _RitualTile(
                            ritual: ritual,
                            completed: done.contains(ritual.id),
                            onEdit: () => _edit(context, ritual),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, Ritual ritual) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RitualEditorSheet(initial: ritual),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Eyebrow(),
              SizedBox(height: 8),
              Text(
                'Ritual kecil,\nruang yang besar.',
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  height: 1.08,
                ),
              ),
            ],
          ),
        ),
        Semantics(
          button: true,
          label: 'Buat ritual baru',
          child: IconButton.filled(
            onPressed: onAdd,
            icon: const PhosphorIcon(PhosphorIconsLight.plus, size: 23),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.sageDeep,
              foregroundColor: Colors.white,
              minimumSize: const Size(52, 52),
            ),
          ),
        ),
      ],
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow();

  @override
  Widget build(BuildContext context) => const Text(
    'KEBIASAAN YANG DIPILIH',
    style: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 10,
      fontWeight: FontWeight.w800,
      color: AppColors.sageDeep,
      letterSpacing: 1.5,
    ),
  );
}

class _RitualTile extends ConsumerWidget {
  const _RitualTile({
    required this.ritual,
    required this.completed,
    required this.onEdit,
  });

  final Ritual ritual;
  final bool completed;
  final VoidCallback onEdit;

  Color get _accent {
    switch (ritual.accentKey) {
      case 'terracotta':
        return AppColors.terracottaDeep;
      case 'gold':
        return AppColors.goldDeep;
      default:
        return AppColors.sageDeep;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EditorialCard(
      color: completed ? AppColors.sageMist : AppColors.paper,
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
      child: Row(
        children: [
          RitualCheck(
            value: completed,
            size: 48,
            label: 'Tandai ${ritual.title}',
            onChanged: (value) => ref
                .read(togetherActionsProvider)
                .setRitualCheckIn(ritual.id, value),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      ritual.timeOfDay.label,
                      style: AppTheme.sans(
                        size: 10,
                        weight: FontWeight.w800,
                        color: _accent,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  ritual.title,
                  style: AppTheme.serif(
                    size: 18,
                    weight: FontWeight.w600,
                    color: completed ? AppColors.sageDeep : AppColors.ink,
                  ),
                ),
                if (ritual.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    ritual.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.sans(size: 11.2, color: AppColors.inkSoft),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _daysLabel(ritual.repeatDays),
                  style: AppTheme.sans(
                    size: 10.5,
                    color: AppColors.inkFaint,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            tooltip: 'Edit ritual',
            icon: const PhosphorIcon(
              PhosphorIconsLight.dotsThreeVertical,
              color: AppColors.inkFaint,
            ),
          ),
        ],
      ),
    );
  }

  String _daysLabel(Set<int> days) {
    if (days.length == 7) return 'Setiap hari';
    const labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final sortedDays = days.toList()..sort();
    return sortedDays.map((day) => labels[day - 1]).join(' · ');
  }
}

class _EmptyRituals extends StatelessWidget {
  const _EmptyRituals({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return EditorialCard(
      color: AppColors.sageMist,
      onTap: onAdd,
      semanticLabel: 'Buat ritual pertama',
      child: Column(
        children: [
          const PhosphorIcon(
            PhosphorIconsLight.leaf,
            size: 42,
            color: AppColors.sageDeep,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada kebiasaan di sini.',
            style: AppTheme.serif(
              size: 20,
              weight: FontWeight.w600,
              color: AppColors.sageDeep,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pilih satu hal sederhana yang ingin kalian ulangi bersama.',
            textAlign: TextAlign.center,
            style: AppTheme.sans(
              size: 12.5,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Buat ritual pertama →',
            style: AppTheme.sans(
              size: 12,
              weight: FontWeight.w800,
              color: AppColors.sageDeep,
            ),
          ),
        ],
      ),
    );
  }
}
