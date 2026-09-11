import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/family_member.dart';
import '../../data/models/moment.dart';
import '../../state/together_providers.dart';
import '../widgets/editor_guard.dart';

class MomentEditorScreen extends ConsumerStatefulWidget {
  const MomentEditorScreen({super.key, this.initial});
  final Moment? initial;
  @override
  ConsumerState<MomentEditorScreen> createState() => _MomentEditorScreenState();
}

class _MomentEditorScreenState extends ConsumerState<MomentEditorScreen> {
  final _guardKey = GlobalKey<EditorGuardState>();
  final _formKey = GlobalKey<FormState>();
  final _errorKey = GlobalKey();
  late final String _id;
  late final int _createdAt;
  late final DateTime _initialCapturedAt;
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late MomentTag _tag;
  late DateTime _capturedAt;
  String? _memberId;
  String? _photoPath;
  String? _error;
  var _saving = false;
  var _pickingPhoto = false;
  var _submitted = false;

  bool get _busy => _saving || _pickingPhoto;
  bool get _dirty =>
      _titleController.text != (widget.initial?.title ?? '') ||
      _noteController.text != (widget.initial?.note ?? '') ||
      _tag != (widget.initial?.tag ?? MomentTag.together) ||
      _capturedAt != _initialCapturedAt ||
      _memberId != widget.initial?.memberId ||
      _photoPath != widget.initial?.photoPath;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _id = initial?.id ?? const Uuid().v4();
    _createdAt = initial?.createdAt ?? DateTime.now().millisecondsSinceEpoch;
    _titleController = TextEditingController(text: initial?.title ?? '')
      ..addListener(_changed);
    _noteController = TextEditingController(text: initial?.note ?? '')
      ..addListener(_changed);
    _tag = initial?.tag ?? MomentTag.together;
    _initialCapturedAt = initial?.capturedAt ?? DateTime.now();
    _capturedAt = _initialCapturedAt;
    _memberId = initial?.memberId;
    _photoPath = initial?.photoPath;
  }

  void _changed() => setState(() {});

  void _reveal(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && key.currentContext != null) {
        Scrollable.ensureVisible(key.currentContext!);
      }
    });
  }

  Future<void> _pickPhoto() async {
    if (_busy) return;
    setState(() {
      _pickingPhoto = true;
      _error = null;
    });
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1600,
      );
      if (picked != null && mounted) setState(() => _photoPath = picked.path);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Foto belum berhasil dibuka. Coba lagi atau pilih foto lain. Isian tetap tersimpan di halaman ini.',
        );
        _reveal(_errorKey);
      }
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  Future<void> _pickDate() async {
    if (_busy) return;
    final today = DateUtils.dateOnly(DateTime.now());
    final firstDate = DateTime(1900);
    final selected = DateUtils.dateOnly(_capturedAt);
    final initialDate = selected.isBefore(firstDate)
        ? firstDate
        : selected.isAfter(today)
        ? today
        : selected;
    final date = await showDatePicker(
      context: context,
      firstDate: firstDate,
      lastDate: today,
      initialDate: initialDate,
      helpText: 'Tanggal momen',
    );
    if (date != null && mounted) setState(() => _capturedAt = date);
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) {
      _reveal(_formKey);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // A deleted member must not leave an invalid foreign-key association.
      // Await the list so a temporarily loading provider never clears a valid one.
      final members = await ref.read(familyMembersProvider.future);
      if (!mounted) return;
      final memberId = members.any((member) => member.id == _memberId)
          ? _memberId
          : null;
      final moment = Moment(
        id: _id,
        title: _titleController.text.trim(),
        note: _noteController.text.trim(),
        tag: _tag,
        memberId: memberId,
        photoPath: _photoPath,
        capturedAt: _capturedAt,
        createdAt: _createdAt,
      );
      await ref.read(togetherActionsProvider).saveMoment(moment);
      if (mounted) _guardKey.currentState?.closeAfterSave(saved: true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Belum berhasil menyimpan momen. Cerita dan foto pilihan tetap ada; coba simpan lagi.',
        );
        _reveal(_errorKey);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final members = ref.watch(familyMembersProvider);
    return EditorGuard(
      key: _guardKey,
      isDirty: () => _dirty,
      isBusy: () => _busy,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          leading: IconButton(
            onPressed: _busy
                ? null
                : () => _guardKey.currentState?.requestClose(),
            tooltip: 'Kembali',
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(
            widget.initial == null ? 'Catat momen' : 'Edit momen',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            TextButton(
              onPressed: _busy ? null : _save,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: const Text('Simpan'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _submitted
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null) ...[
                          EditorError(key: _errorKey, message: _error!),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          'Satu cerita kecil untuk diingat kembali.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _PhotoSlot(
                          path: _photoPath,
                          busy: _pickingPhoto,
                          onPick: _busy ? null : _pickPhoto,
                        ),
                        if (_photoPath != null && _photoPath!.isNotEmpty)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () => setState(() => _photoPath = null),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(48, 48),
                              ),
                              icon: const Icon(Icons.close_rounded, size: 18),
                              label: const Text('Hapus foto'),
                            ),
                          ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _titleController,
                          enabled: !_busy,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.next,
                          maxLength: 100,
                          decoration: const InputDecoration(
                            labelText: 'Judul momen',
                            hintText: 'Contoh: Hujan pertama bulan ini',
                            prefixIcon: Icon(Icons.auto_awesome_outlined),
                            errorMaxLines: 3,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Tulis judul untuk momen ini.';
                            }
                            if (value.characters.length > 100) {
                              return 'Judul paling panjang 100 karakter.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _noteController,
                          enabled: !_busy,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 3,
                          maxLines: 8,
                          maxLength: 4000,
                          decoration: const InputDecoration(
                            labelText: 'Ceritakan sedikit',
                            hintText:
                                'Apa yang ingin kalian ingat dari hari ini?',
                            alignLabelWithHint: true,
                            errorMaxLines: 3,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Tulis setidaknya satu kalimat.';
                            }
                            if (value.characters.length > 4000) {
                              return 'Cerita paling panjang 4.000 karakter.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Rasanya seperti…',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final tag in MomentTag.values)
                              ChoiceChip(
                                label: Text(tag.label),
                                selected: _tag == tag,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.padded,
                                onSelected: _busy
                                    ? null
                                    : (_) => setState(() => _tag = tag),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        members.when(
                          data: _memberField,
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: LinearProgressIndicator(
                              semanticsLabel: 'Memuat anggota keluarga',
                            ),
                          ),
                          error: (_, _) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Daftar anggota belum bisa dimuat.'),
                              TextButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () =>
                                          ref.invalidate(familyMembersProvider),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Coba lagi'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Material(
                          color: colors.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(color: colors.outlineVariant),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            leading: Icon(
                              Icons.calendar_today_outlined,
                              color: colors.primary,
                            ),
                            title: const Text('Tanggal momen'),
                            subtitle: Text(
                              DateFormat(
                                'EEEE, d MMMM yyyy',
                                'id_ID',
                              ).format(_capturedAt),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            onTap: _busy ? null : _pickDate,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: FilledButton.icon(
                  onPressed: _busy ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  icon: Icon(
                    _saving ? Icons.hourglass_top_rounded : Icons.check_rounded,
                  ),
                  label: Text(
                    _saving
                        ? 'Menyimpan…'
                        : _pickingPhoto
                        ? 'Membuka foto…'
                        : 'Simpan momen',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _memberField(List<FamilyMember> members) {
    final hasMember = members.any((member) => member.id == _memberId);
    final missingMember = _memberId != null && !hasMember;
    if (members.isEmpty && !missingMember) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(
            '${hasMember ? _memberId : 'all'}:${members.map((member) => member.id).join(',')}',
          ),
          initialValue: hasMember ? _memberId : null,
          isExpanded: true,
          itemHeight: null,
          decoration: const InputDecoration(
            labelText: 'Bersama siapa?',
            prefixIcon: Icon(Icons.people_outline_rounded),
          ),
          hint: const Text('Semua yang hadir'),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Semua yang hadir'),
            ),
            for (final member in members)
              DropdownMenuItem(
                value: member.id,
                child: Text(member.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: _busy
              ? null
              : (value) => setState(() => _memberId = value),
        ),
        if (missingMember) ...[
          const SizedBox(height: 8),
          Text(
            'Anggota yang dahulu ditandai sudah tidak ada. Momen akan disimpan tanpa kaitan anggota tersebut.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    required this.path,
    required this.busy,
    required this.onPick,
  });
  final String? path;
  final bool busy;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasPhoto = path != null && path!.isNotEmpty;
    return Semantics(
      button: true,
      label: hasPhoto ? 'Ganti foto momen' : 'Tambah foto momen',
      child: Material(
        color: colors.secondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPick,
          child: hasPhoto
              ? Image.file(
                  File(path!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const _PhotoPlaceholder(unavailable: true),
                )
              : _PhotoPlaceholder(busy: busy),
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({this.unavailable = false, this.busy = false});
  final bool unavailable;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onSecondaryContainer;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 168),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              unavailable
                  ? Icons.image_not_supported_outlined
                  : Icons.add_photo_alternate_outlined,
              size: 36,
              color: foreground,
            ),
            const SizedBox(height: 12),
            Text(
              busy
                  ? 'Membuka foto…'
                  : unavailable
                  ? 'Foto tidak tersedia. Ketuk untuk mengganti.'
                  : 'Tambah foto (opsional)',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
