import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/gender_avatar.dart';
import '../../core/widgets/luxe_card.dart';
import '../../data/models/child.dart';
import '../../state/providers.dart';
import 'child_form_screen.dart';

/// Daftar semua anak + aksi kelola (ubah/hapus).
class ChildrenScreen extends ConsumerWidget {
  const ChildrenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenProvider);
    final selectedId = ref.watch(selectedChildIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Anak')),
      body: childrenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
        data: (children) {
          if (children.isEmpty) {
            return EmptyState(
              icon: Icons.child_care_rounded,
              title: 'Belum Ada Profil',
              message:
                  'Tambahkan profil anak pertama untuk mulai memantau tumbuh kembangnya.',
              actionLabel: 'Tambah Anak',
              onAction: () => _openForm(context, null),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: children.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              final child = children[i];
              final isSelected = child.id == selectedId;
              return LuxeCard(
                padding: const EdgeInsets.all(16),
                borderColor: isSelected ? AppColors.gold : AppColors.hairline,
                onTap: () {
                  ref.read(selectedChildIdProvider.notifier).select(child.id);
                  Navigator.of(context).maybePop();
                },
                child: Row(
                  children: [
                    GenderAvatar(
                      name: child.name,
                      isBoy: child.isBoy,
                      photoPath: child.photoPath,
                      size: 56,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  child.name,
                                  style: AppTheme.serif(
                                    size: 17.5,
                                    weight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: AppColors.gold,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${child.ageLabel} • ${child.gender.label}',
                            style: AppTheme.sans(
                              size: 12.5,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: AppColors.inkSoft,
                      ),
                      onPressed: () => _openForm(context, child),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: AppColors.danger,
                      ),
                      onPressed: () => _confirmDelete(context, ref, child),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, null),
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Anak'),
      ),
    );
  }

  void _openForm(BuildContext context, Child? child) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ChildFormScreen(existing: child)));
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Child child,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus ${child.name}?'),
        content: const Text(
          'Seluruh riwayat pengukuran, milestone, dan imunisasi anak ini akan ikut terhapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(childrenProvider.notifier).deleteChild(child.id);
    }
  }
}
