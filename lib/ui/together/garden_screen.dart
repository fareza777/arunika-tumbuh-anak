import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/family_member.dart';
import '../../state/app_settings.dart';
import '../../state/together_providers.dart';
import '../settings/settings_screen.dart';
import '../widgets/editorial_background.dart';
import '../widgets/editorial_card.dart';
import 'family_member_editor_sheet.dart';

class GardenScreen extends ConsumerWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(familyMembersProvider);
    final moments = ref.watch(momentsProvider).valueOrNull ?? const [];
    final rituals = ref.watch(ritualsProvider).valueOrNull ?? const [];
    final settings = ref.watch(settingsProvider);

    return EditorialBackground(
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.goldDeep,
          onRefresh: () async {
            ref.invalidate(familyMembersProvider);
            ref.invalidate(momentsProvider);
            ref.invalidate(ritualsProvider);
            await Future<void>.delayed(const Duration(milliseconds: 180));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 118),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RUANG ${settings.familyName.toUpperCase()}',
                          style: AppTheme.sans(
                            size: 10,
                            weight: FontWeight.w800,
                            color: AppColors.goldDeep,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Taman yang\nkalian tumbuhkan.',
                          style: AppTheme.serif(
                            size: 32,
                            weight: FontWeight.w600,
                            height: 1.08,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    tooltip: 'Pengaturan',
                    icon: const PhosphorIcon(
                      PhosphorIconsLight.gearSix,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              EditorialCard(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const PhosphorIcon(
                          PhosphorIconsLight.treeStructure,
                          color: AppColors.sageDeep,
                          size: 21,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'BENANG-BENANG YANG TERHUBUNG',
                          style: AppTheme.sans(
                            size: 10,
                            weight: FontWeight.w800,
                            color: AppColors.sageDeep,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${moments.length} momen',
                          style: AppTheme.sans(
                            size: 10.5,
                            weight: FontWeight.w800,
                            color: AppColors.inkFaint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 245,
                      child: GardenConstellation(
                        members: members.valueOrNull ?? const [],
                        momentCount: moments.length,
                        ritualCount: rituals.length,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Setiap momen adalah cahaya. Setiap ritual adalah akar.',
                      style: AppTheme.sans(
                        size: 11.5,
                        color: AppColors.inkSoft,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Orang-orang di sini',
                      style: AppTheme.serif(size: 21, weight: FontWeight.w600),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _addMember(context),
                    icon: const PhosphorIcon(PhosphorIconsLight.plus, size: 16),
                    label: const Text('Tambah'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              members.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, _) => const EditorialCard(
                  child: Text('Anggota belum dapat dimuat.'),
                ),
                data: (items) => items.isEmpty
                    ? _EmptyMembers(onAdd: () => _addMember(context))
                    : Column(
                        children: [
                          for (final member in items) ...[
                            _MemberTile(member: member),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addMember(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const FamilyMemberEditorSheet(),
    );
  }
}

class GardenConstellation extends StatelessWidget {
  const GardenConstellation({
    super.key,
    required this.members,
    required this.momentCount,
    required this.ritualCount,
  });

  final List<FamilyMember> members;
  final int momentCount;
  final int ritualCount;

  @override
  Widget build(BuildContext context) {
    final nodes = members.isEmpty ? const <FamilyMember>[] : members;
    return LayoutBuilder(
      builder: (context, constraints) {
        final center = Offset(
          constraints.maxWidth / 2,
          constraints.maxHeight / 2,
        );
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ConstellationPainter(
                  count: nodes.length,
                  center: center,
                ),
              ),
            ),
            Positioned(
              left: center.dx - 36,
              top: center.dy - 36,
              child: _GardenCore(
                momentCount: momentCount,
                ritualCount: ritualCount,
              ),
            ),
            for (var index = 0; index < nodes.length; index++)
              _GardenNodePosition(
                member: nodes[index],
                index: index,
                total: nodes.length,
                center: center,
                size: constraints.biggest,
              ),
          ],
        );
      },
    );
  }
}

class _GardenNodePosition extends StatelessWidget {
  const _GardenNodePosition({
    required this.member,
    required this.index,
    required this.total,
    required this.center,
    required this.size,
  });

  final FamilyMember member;
  final int index;
  final int total;
  final Offset center;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final radius = math.min(size.width, size.height) * 0.35;
    final angle = -math.pi / 2 + (math.pi * 2 * index / math.max(total, 1));
    final point = Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );
    return Positioned(
      left: point.dx - 28,
      top: point.dy - 28,
      child: Tooltip(
        message: member.name,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.paper,
            border: Border.all(color: AppColors.goldSoft, width: 2),
            boxShadow: AppColors.softShadow(opacity: 0.1, blur: 13, y: 5),
          ),
          child: Center(
            child: Text(
              _initials(member.name),
              style: AppTheme.serif(
                size: 16,
                weight: FontWeight.w600,
                color: AppColors.goldDeep,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
}

class _ConstellationPainter extends CustomPainter {
  _ConstellationPainter({required this.count, required this.center});

  final int count;
  final Offset center;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width, size.height) * 0.35;
    final line = Paint()
      ..color = AppColors.goldSoft.withValues(alpha: 0.72)
      ..strokeWidth = 1.2;
    final glow = Paint()..color = AppColors.gold.withValues(alpha: 0.14);
    canvas.drawCircle(center, 62, glow);
    if (count == 0) return;
    for (var i = 0; i < count; i++) {
      final angle = -math.pi / 2 + (math.pi * 2 * i / math.max(count, 1));
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      canvas.drawLine(center, point, line);
      canvas.drawCircle(
        point,
        4,
        Paint()..color = AppColors.terracotta.withValues(alpha: 0.65),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) =>
      oldDelegate.count != count;
}

class _GardenCore extends StatelessWidget {
  const _GardenCore({required this.momentCount, required this.ritualCount});

  final int momentCount;
  final int ritualCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.sunrise,
        boxShadow: AppColors.softShadow(opacity: 0.16, blur: 18, y: 8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const PhosphorIcon(
            PhosphorIconsLight.sun,
            size: 22,
            color: AppColors.espresso,
          ),
          const SizedBox(height: 2),
          Text(
            '$momentCount',
            style: AppTheme.sans(
              size: 12,
              weight: FontWeight.w800,
              color: AppColors.espresso,
            ),
          ),
          Text(
            'momen',
            style: AppTheme.sans(
              size: 8.5,
              weight: FontWeight.w700,
              color: AppColors.espresso.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final FamilyMember member;

  @override
  Widget build(BuildContext context) {
    return EditorialCard(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.goldMist,
            ),
            child: Center(
              child: Text(
                member.name.characters.first.toUpperCase(),
                style: AppTheme.serif(
                  size: 17,
                  weight: FontWeight.w600,
                  color: AppColors.goldDeep,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: AppTheme.sans(size: 13.5, weight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  member.roleLabel,
                  style: AppTheme.sans(size: 11, color: AppColors.inkFaint),
                ),
              ],
            ),
          ),
          const PhosphorIcon(
            PhosphorIconsLight.sparkle,
            size: 19,
            color: AppColors.gold,
          ),
        ],
      ),
    );
  }
}

class _EmptyMembers extends StatelessWidget {
  const _EmptyMembers({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => EditorialCard(
    onTap: onAdd,
    color: AppColors.goldMist,
    shadow: false,
    child: Row(
      children: [
        const PhosphorIcon(
          PhosphorIconsLight.usersThree,
          size: 30,
          color: AppColors.goldDeep,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Tambahkan orang-orang yang membuat ruang ini terasa pulang.',
            style: AppTheme.sans(
              size: 12.5,
              color: AppColors.inkSoft,
              height: 1.45,
            ),
          ),
        ),
        const PhosphorIcon(PhosphorIconsLight.plus, color: AppColors.goldDeep),
      ],
    ),
  );
}
