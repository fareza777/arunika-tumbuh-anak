import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ritual.dart';
import '../../state/monetization_provider.dart';
import '../../state/together_providers.dart';

class RitualEditorSheet extends ConsumerStatefulWidget {
  const RitualEditorSheet({super.key, this.initial});

  final Ritual? initial;

  @override
  ConsumerState<RitualEditorSheet> createState() => _RitualEditorSheetState();
}

class _RitualEditorSheetState extends ConsumerState<RitualEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late RitualTimeOfDay _timeOfDay;
  late Set<int> _repeatDays;
  late String _accentKey;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _descriptionController = TextEditingController(
      text: initial?.description ?? '',
    );
    _timeOfDay = initial?.timeOfDay ?? RitualTimeOfDay.anytime;
    _repeatDays = {
      ...(initial?.repeatDays ?? const {1, 2, 3, 4, 5, 6, 7}),
    };
    _accentKey = initial?.accentKey ?? 'sage';
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Beri ritual ini sebuah nama dulu.')),
      );
      return;
    }
    setState(() => _saving = true);
    final old = widget.initial;
    final ritual = Ritual(
      id: old?.id ?? const Uuid().v4(),
      title: title,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      timeOfDay: _timeOfDay,
      repeatDays: _repeatDays,
      accentKey: _accentKey,
      createdAt: old?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
    );
    await ref.read(togetherActionsProvider).saveRitual(ritual);
    if (!mounted) return;
    Navigator.of(context).pop();
    final monetization = ref.read(monetizationProvider.notifier);
    monetization.onMeaningfulSave();
    await monetization.maybeShowInterstitial();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.hairline,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.initial == null ? 'Buat ritual baru' : 'Edit ritual',
                    style: AppTheme.serif(size: 25, weight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Tutup',
                  icon: const PhosphorIcon(PhosphorIconsLight.x),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              autofocus: widget.initial == null,
              decoration: const InputDecoration(
                labelText: 'Nama ritual',
                hintText: 'Contoh: Jalan sore tanpa layar',
                prefixIcon: PhosphorIcon(PhosphorIconsLight.sparkle),
              ),
            ),
            const SizedBox(height: 13),
            TextField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Kalimat pengingat (opsional)',
                hintText: 'Apa yang ingin terasa di momen ini?',
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'WAKTU YANG TERASA PAS',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.sageDeep,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final time in RitualTimeOfDay.values)
                  ChoiceChip(
                    label: Text(time.label),
                    selected: _timeOfDay == time,
                    onSelected: (_) => setState(() => _timeOfDay = time),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'HARI BERULANG',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.sageDeep,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              children: [
                for (var day = 1; day <= 7; day++)
                  _DayChoice(
                    day: day,
                    selected: _repeatDays.contains(day),
                    onTap: () => setState(() => _toggleDay(day)),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'NUANSA',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.sageDeep,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final item in const [
                  ('sage', AppColors.sageDeep),
                  ('terracotta', AppColors.terracottaDeep),
                  ('gold', AppColors.goldDeep),
                ])
                  _AccentChoice(
                    key: ValueKey(item.$1),
                    color: item.$2,
                    selected: _accentKey == item.$1,
                    onTap: () => setState(() => _accentKey = item.$1),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const PhosphorIcon(PhosphorIconsLight.check),
                label: Text(_saving ? 'Menyimpan…' : 'Simpan ritual'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleDay(int day) {
    if (_repeatDays.length == 1 && _repeatDays.contains(day)) return;
    if (_repeatDays.contains(day)) {
      _repeatDays.remove(day);
    } else {
      _repeatDays.add(day);
    }
  }
}

class _DayChoice extends StatelessWidget {
  const _DayChoice({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final int day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const labels = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
    return Semantics(
      button: true,
      selected: selected,
      label: 'Hari ke $day',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 39,
          height: 39,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.sageDeep : AppColors.paper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.sageDeep : AppColors.hairline,
            ),
          ),
          child: Text(
            labels[day - 1],
            style: AppTheme.sans(
              size: 12,
              weight: FontWeight.w800,
              color: selected ? Colors.white : AppColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}

class _AccentChoice extends StatelessWidget {
  const _AccentChoice({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Semantics(
        button: true,
        selected: selected,
        label: 'Pilih warna ritual',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
              border: Border.all(
                color: selected ? color : color.withValues(alpha: 0.35),
                width: selected ? 3 : 1,
              ),
            ),
            child: Center(
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
