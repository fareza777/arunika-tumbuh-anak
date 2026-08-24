import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/moment.dart';
import '../../state/together_providers.dart';
import '../widgets/editorial_background.dart';
import '../widgets/editorial_card.dart';
import '../widgets/tag_chip.dart';
import 'moment_editor_screen.dart';

class MomentsScreen extends ConsumerStatefulWidget {
  const MomentsScreen({super.key, required this.onOpenMoment});

  final VoidCallback onOpenMoment;

  @override
  ConsumerState<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends ConsumerState<MomentsScreen> {
  MomentTag? _filter;

  @override
  Widget build(BuildContext context) {
    final moments = ref.watch(momentsProvider);
    return EditorialBackground(
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.terracotta,
          onRefresh: () async {
            ref.invalidate(momentsProvider);
            await Future<void>.delayed(const Duration(milliseconds: 180));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 118),
            children: [
              _MomentHeader(onAdd: widget.onOpenMoment),
              const SizedBox(height: 22),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: MomentTag.values.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final tag = index == 0 ? null : MomentTag.values[index - 1];
                    return _FilterChip(
                      label: tag?.label ?? 'Semua',
                      selected: _filter == tag,
                      onTap: () => setState(() => _filter = tag),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              moments.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, _) => const EditorialCard(
                  child: Text('Momen belum dapat dimuat. Coba lagi sebentar.'),
                ),
                data: (items) {
                  final filtered = _filter == null
                      ? items
                      : items.where((item) => item.tag == _filter).toList();
                  if (filtered.isEmpty) {
                    return _EmptyMoments(onAdd: widget.onOpenMoment);
                  }
                  return Column(
                    children: [
                      for (final moment in filtered) ...[
                        _MomentTile(moment: moment, onTap: () => _edit(moment)),
                        const SizedBox(height: 13),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(Moment moment) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MomentEditorScreen(initial: moment)),
    );
  }
}

class _MomentHeader extends StatelessWidget {
  const _MomentHeader({required this.onAdd});

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
              Text(
                'ARSIP HANGAT',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.terracottaDeep,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Momen yang\ningin diingat.',
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
          label: 'Catat momen baru',
          child: IconButton.filled(
            onPressed: onAdd,
            icon: const PhosphorIcon(PhosphorIconsLight.plus, size: 23),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.terracottaDeep,
              foregroundColor: Colors.white,
              minimumSize: const Size(52, 52),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Filter $label',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.terracottaDeep : AppColors.paper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.terracottaDeep : AppColors.hairline,
            ),
          ),
          child: Text(
            label,
            style: AppTheme.sans(
              size: 11.5,
              weight: FontWeight.w800,
              color: selected ? Colors.white : AppColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}

class _MomentTile extends StatelessWidget {
  const _MomentTile({required this.moment, required this.onTap});

  final Moment moment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = moment.photoPath != null && moment.photoPath!.isNotEmpty;
    return EditorialCard(
      onTap: onTap,
      semanticLabel: 'Edit momen ${moment.title}',
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: SizedBox(
              width: 78,
              height: 92,
              child: hasPhoto
                  ? Image.file(
                      File(moment.photoPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _MomentIllustration(),
                    )
                  : const _MomentIllustration(),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MomentTagChip(tag: moment.tag),
                    const Spacer(),
                    Text(
                      DateFormat(
                        'd MMM yyyy',
                        'id_ID',
                      ).format(moment.capturedAt),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.serif(size: 19, weight: FontWeight.w600),
                ),
                const SizedBox(height: 5),
                Text(
                  moment.note,
                  maxLines: 3,
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

class _MomentIllustration extends StatelessWidget {
  const _MomentIllustration();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppColors.terracottaMistGradient,
      ),
      child: Center(
        child: PhosphorIcon(
          PhosphorIconsLight.sunHorizon,
          size: 31,
          color: AppColors.terracottaDeep.withValues(alpha: 0.76),
        ),
      ),
    );
  }
}

class _EmptyMoments extends StatelessWidget {
  const _EmptyMoments({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return EditorialCard(
      color: AppColors.terracottaMist,
      onTap: onAdd,
      semanticLabel: 'Catat momen pertama',
      child: Column(
        children: [
          const PhosphorIcon(
            PhosphorIconsLight.images,
            size: 45,
            color: AppColors.terracottaDeep,
          ),
          const SizedBox(height: 15),
          Text(
            'Belum ada cerita yang disimpan.',
            style: AppTheme.serif(
              size: 20,
              weight: FontWeight.w600,
              color: AppColors.terracottaDeep,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Foto, kalimat, atau suara tawa—semuanya boleh dimulai dari hal sederhana.',
            textAlign: TextAlign.center,
            style: AppTheme.sans(
              size: 12.5,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Catat momen pertama →',
            style: AppTheme.sans(
              size: 12,
              weight: FontWeight.w800,
              color: AppColors.terracottaDeep,
            ),
          ),
        ],
      ),
    );
  }
}
