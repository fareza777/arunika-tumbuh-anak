import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/gender_avatar.dart';
import '../../core/widgets/gold_button.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/child.dart';
import '../../state/providers.dart';

/// Form tambah/ubah profil anak.
class ChildFormScreen extends ConsumerStatefulWidget {
  const ChildFormScreen({super.key, this.existing});

  final Child? existing;

  @override
  ConsumerState<ChildFormScreen> createState() => _ChildFormScreenState();
}

class _ChildFormScreenState extends ConsumerState<ChildFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late Gender _gender;
  late DateTime _birthDate;
  String? _photoPath;
  bool _clearPhoto = false;

  late final TextEditingController _birthWeight;
  late final TextEditingController _birthHeight;
  late final TextEditingController _birthHead;
  late final TextEditingController _fatherHeight;
  late final TextEditingController _motherHeight;
  late final TextEditingController _gestationalWeeks;

  var _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _gender = e?.gender ?? Gender.girl;
    _birthDate = e?.birthDate ?? DateTime.now();
    _photoPath = e?.photoPath;
    _birthWeight = TextEditingController(text: _num(e?.birthWeight));
    _birthHeight = TextEditingController(text: _num(e?.birthHeight));
    _birthHead = TextEditingController(text: _num(e?.birthHead));
    _fatherHeight = TextEditingController(text: _num(e?.fatherHeight));
    _motherHeight = TextEditingController(text: _num(e?.motherHeight));
    _gestationalWeeks = TextEditingController(
      text: e?.gestationalWeeks?.toString() ?? '',
    );
  }

  String _num(double? v) => v == null ? '' : v.toString().replaceAll('.', ',');

  double? _parse(String text) {
    final cleaned = text.trim().replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthWeight.dispose();
    _birthHeight.dispose();
    _birthHead.dispose();
    _fatherHeight.dispose();
    _motherHeight.dispose();
    _gestationalWeeks.dispose();
    super.dispose();
  }

  int? _parseWeeks() {
    final text = _gestationalWeeks.text.trim();
    if (text.isEmpty) return null;
    final parsed = int.tryParse(text);
    if (parsed == null || parsed < 22 || parsed > 42) return null;
    // Cukup bulan (>= 37 mgg) tidak butuh koreksi — simpan null.
    return parsed >= 37 ? null : parsed;
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    // Salin ke direktori aplikasi agar tidak hilang saat galeri dibersihkan.
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'child_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}';
    final saved = await File(picked.path).copy(p.join(dir.path, fileName));
    setState(() {
      _photoPath = saved.path;
      _clearPhoto = false;
    });
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(2005),
      lastDate: DateTime.now(),
      helpText: 'Tanggal Lahir',
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final notifier = ref.read(childrenProvider.notifier);
      if (_isEdit) {
        final updated = widget.existing!.copyWith(
          name: _nameController.text.trim(),
          gender: _gender,
          birthDate: _birthDate,
          photoPath: _photoPath,
          clearPhoto: _clearPhoto,
          birthWeight: _parse(_birthWeight.text),
          birthHeight: _parse(_birthHeight.text),
          birthHead: _parse(_birthHead.text),
          fatherHeight: _parse(_fatherHeight.text),
          motherHeight: _parse(_motherHeight.text),
          gestationalWeeks: _parseWeeks(),
          clearGestational: _parseWeeks() == null,
        );
        await notifier.updateChild(updated);
      } else {
        final child = Child(
          id: newChildId(),
          name: _nameController.text.trim(),
          gender: _gender,
          birthDate: _birthDate,
          photoPath: _photoPath,
          birthWeight: _parse(_birthWeight.text),
          birthHeight: _parse(_birthHeight.text),
          birthHead: _parse(_birthHead.text),
          fatherHeight: _parse(_fatherHeight.text),
          motherHeight: _parse(_motherHeight.text),
          gestationalWeeks: _parseWeeks(),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
        await notifier.addChild(child);
        ref.read(selectedChildIdProvider.notifier).select(child.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit ? 'Profil diperbarui.' : 'Profil anak ditambahkan.',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Ubah Profil' : 'Tambah Anak')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            // ── Foto ────────────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Stack(
                      children: [
                        GenderAvatar(
                          name: _nameController.text.isEmpty
                              ? '?'
                              : _nameController.text,
                          isBoy: _gender == Gender.boy,
                          photoPath: _clearPhoto ? null : _photoPath,
                          size: 96,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: AppColors.goldGradient,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.ivory,
                                width: 2.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.photo_camera_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_photoPath != null && !_clearPhoto)
                    TextButton(
                      onPressed: () => setState(() => _clearPhoto = true),
                      child: const Text(
                        'Hapus foto',
                        style: TextStyle(color: AppColors.danger, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Nama ────────────────────────────────────────────────────
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama Anak',
                hintText: 'mis. Kimi Arunika',
                prefixIcon: Icon(Icons.face_rounded),
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 18),

            // ── Jenis kelamin ───────────────────────────────────────────
            const SectionHeader(title: 'Jenis Kelamin'),
            Row(
              children: [
                Expanded(
                  child: _GenderCard(
                    label: 'Perempuan',
                    icon: Icons.girl_rounded,
                    selected: _gender == Gender.girl,
                    color: AppColors.girl,
                    soft: AppColors.girlSoft,
                    onTap: () => setState(() => _gender = Gender.girl),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _GenderCard(
                    label: 'Laki-laki',
                    icon: Icons.boy_rounded,
                    selected: _gender == Gender.boy,
                    color: AppColors.boy,
                    soft: AppColors.boySoft,
                    onTap: () => setState(() => _gender = Gender.boy),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Tanggal lahir ───────────────────────────────────────────
            GestureDetector(
              onTap: _pickBirthDate,
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Lahir',
                    prefixIcon: Icon(Icons.cake_rounded),
                  ),
                  controller: TextEditingController(
                    text: Format.dateFull(_birthDate),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Data lahir (opsional) ───────────────────────────────────
            const SectionHeader(title: 'Data Saat Lahir (Opsional)'),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    controller: _birthWeight,
                    label: 'Berat (kg)',
                    icon: Icons.monitor_weight_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumberField(
                    controller: _birthHeight,
                    label: 'Panjang (cm)',
                    icon: Icons.straighten_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumberField(
                    controller: _birthHead,
                    label: 'L. Kepala (cm)',
                    icon: Icons.circle_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Usia kehamilan (koreksi prematur) ───────────────────────
            const SectionHeader(title: 'Kelahiran Prematur (Opsional)'),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Bila anak lahir sebelum 37 minggu, isi usia kehamilan agar penilaian '
                'memakai usia terkoreksi sampai usia 2 tahun (sesuai anjuran WHO).',
                style: AppTheme.sans(
                  size: 12,
                  color: AppColors.inkSoft,
                  height: 1.5,
                ),
              ),
            ),
            TextFormField(
              controller: _gestationalWeeks,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Usia kehamilan saat lahir (minggu)',
                hintText: 'mis. 34 — kosongkan bila cukup bulan',
                prefixIcon: Icon(Icons.pregnant_woman_rounded),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final parsed = int.tryParse(v.trim());
                if (parsed == null || parsed < 22 || parsed > 42) {
                  return 'Isi antara 22-42 minggu, atau kosongkan';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // ── Tinggi orang tua (untuk prediksi) ───────────────────────
            const SectionHeader(title: 'Tinggi Orang Tua (Opsional)'),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Dipakai untuk memprediksi potensi tinggi dewasa anak.',
                style: AppTheme.sans(size: 12, color: AppColors.inkSoft),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    controller: _fatherHeight,
                    label: 'Ayah (cm)',
                    icon: Icons.man_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumberField(
                    controller: _motherHeight,
                    label: 'Ibu (cm)',
                    icon: Icons.woman_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            GoldButton(
              label: _saving
                  ? 'Menyimpan...'
                  : (_isEdit ? 'Simpan Perubahan' : 'Tambah Anak'),
              icon: Icons.check_rounded,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  const _GenderCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.soft,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final Color soft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: selected ? soft : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? color : AppColors.hairline,
          width: selected ? 1.8 : 1,
        ),
        boxShadow: selected ? AppColors.softShadow(opacity: 0.1) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 34,
                  color: selected ? color : AppColors.inkFaint,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: AppTheme.sans(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: selected ? color : AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        final parsed = double.tryParse(v.trim().replaceAll(',', '.'));
        if (parsed == null || parsed <= 0) return 'Angka tidak valid';
        return null;
      },
    );
  }
}
