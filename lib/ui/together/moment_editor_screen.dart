import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/family_member.dart';
import '../../data/models/moment.dart';
import '../../state/monetization_provider.dart';
import '../../state/together_providers.dart';
import '../widgets/editorial_background.dart';
import '../widgets/editorial_card.dart';
import '../widgets/tag_chip.dart';

class MomentEditorScreen extends ConsumerStatefulWidget {
  const MomentEditorScreen({super.key, this.initial});

  final Moment? initial;

  @override
  ConsumerState<MomentEditorScreen> createState() => _MomentEditorScreenState();
}

class _MomentEditorScreenState extends ConsumerState<MomentEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late MomentTag _tag;
  late DateTime _capturedAt;
  String? _memberId;
  String? _photoPath;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _noteController = TextEditingController(text: initial?.note ?? '');
    _tag = initial?.tag ?? MomentTag.together;
    _capturedAt = initial?.capturedAt ?? DateTime.now();
    _memberId = initial?.memberId;
    _photoPath = initial?.photoPath;
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1600,
    );
    if (picked != null && mounted) setState(() => _photoPath = picked.path);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
      initialDate: _capturedAt,
    );
    if (date != null) setState(() => _capturedAt = date);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final note = _noteController.text.trim();
    if (title.isEmpty || note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tulis judul dan satu kalimat untuk momen ini.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final old = widget.initial;
    final moment = Moment(
      id: old?.id ?? const Uuid().v4(),
      title: title,
      note: note,
      tag: _tag,
      memberId: _memberId,
      photoPath: _photoPath,
      capturedAt: _capturedAt,
      createdAt: old?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
    );
    await ref.read(togetherActionsProvider).saveMoment(moment);
    if (!mounted) return;
    Navigator.of(context).pop();
    final monetization = ref.read(monetizationProvider.notifier);
    monetization.onMeaningfulSave();
    await monetization.maybeShowInterstitial();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final members =
        ref.watch(familyMembersProvider).valueOrNull ?? const <FamilyMember>[];
    return Scaffold(
      body: EditorialBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.ivory.withValues(alpha: 0.94),
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Kembali',
                  icon: const PhosphorIcon(PhosphorIconsLight.arrowLeft),
                ),
                title: Text(
                  widget.initial == null ? 'Catat momen' : 'Edit momen',
                  style: AppTheme.serif(size: 22, weight: FontWeight.w600),
                ),
                actions: [
                  TextButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? '…' : 'Simpan'),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _PhotoSlot(path: _photoPath, onPick: _pickPhoto),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _titleController,
                      autofocus: widget.initial == null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Judul momen',
                        hintText: 'Contoh: Hujan pertama bulan ini',
                        prefixIcon: PhosphorIcon(PhosphorIconsLight.sparkle),
                      ),
                    ),
                    const SizedBox(height: 13),
                    TextField(
                      controller: _noteController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 5,
                      minLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Ceritakan sedikit',
                        hintText: 'Apa yang ingin kalian ingat dari hari ini?',
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'RASANYA SEPERTI…',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.terracottaDeep,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in MomentTag.values)
                          MomentTagChip(
                            tag: tag,
                            selected: _tag == tag,
                            onTap: () => setState(() => _tag = tag),
                          ),
                      ],
                    ),
                    if (members.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'BERSAMA SIAPA?',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.terracottaDeep,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String?>(
                        initialValue: _memberId,
                        decoration: const InputDecoration(
                          prefixIcon: PhosphorIcon(
                            PhosphorIconsLight.usersThree,
                          ),
                          labelText: 'Pilih anggota (opsional)',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Semua yang hadir'),
                          ),
                          ...members.map(
                            (member) => DropdownMenuItem<String?>(
                              value: member.id,
                              child: Text(member.name),
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() => _memberId = value),
                      ),
                    ],
                    const SizedBox(height: 24),
                    EditorialCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 4,
                      ),
                      shadow: false,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const PhosphorIcon(
                          PhosphorIconsLight.calendarBlank,
                          color: AppColors.terracottaDeep,
                        ),
                        title: Text(
                          'Tanggal momen',
                          style: AppTheme.sans(
                            size: 12.5,
                            weight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          DateFormat(
                            'EEEE, d MMMM yyyy',
                            'id_ID',
                          ).format(_capturedAt),
                          style: AppTheme.sans(
                            size: 11.5,
                            color: AppColors.inkSoft,
                          ),
                        ),
                        trailing: const PhosphorIcon(
                          PhosphorIconsLight.caretRight,
                          size: 18,
                          color: AppColors.inkFaint,
                        ),
                        onTap: _pickDate,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const PhosphorIcon(PhosphorIconsLight.check),
                        label: Text(_saving ? 'Menyimpan…' : 'Simpan momen'),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({required this.path, required this.onPick});

  final String? path;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = path != null && path!.isNotEmpty;
    return EditorialCard(
      padding: EdgeInsets.zero,
      shadow: false,
      onTap: onPick,
      semanticLabel: hasPhoto ? 'Ganti foto momen' : 'Tambah foto momen',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: SizedBox(
          height: 175,
          width: double.infinity,
          child: hasPhoto
              ? Image.file(
                  File(path!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
                )
              : const _PhotoPlaceholder(),
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.sageGradient),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const PhosphorIcon(
            PhosphorIconsLight.camera,
            size: 37,
            color: AppColors.sageDeep,
          ),
          const SizedBox(height: 10),
          Text(
            'Tambah foto (opsional)',
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
