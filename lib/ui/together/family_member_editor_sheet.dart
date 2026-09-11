import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/family_member.dart';
import '../../state/together_providers.dart';
import '../widgets/editor_guard.dart';

class FamilyMemberEditorSheet extends ConsumerStatefulWidget {
  const FamilyMemberEditorSheet({super.key, this.initial});
  final FamilyMember? initial;
  @override
  ConsumerState<FamilyMemberEditorSheet> createState() =>
      _FamilyMemberEditorSheetState();
}

class _FamilyMemberEditorSheetState
    extends ConsumerState<FamilyMemberEditorSheet> {
  static const _roles = {
    'family': 'Keluarga',
    'parent': 'Orang tua',
    'grandparent': 'Kakek/nenek',
    'sibling': 'Kakak/adik',
  };
  final _guardKey = GlobalKey<EditorGuardState>();
  final _formKey = GlobalKey<FormState>();
  final _errorKey = GlobalKey();
  late final String _id;
  late final TextEditingController _nameController;
  late String _role;
  var _saving = false;
  var _submitted = false;
  String? _error;

  bool get _dirty =>
      _nameController.text != (widget.initial?.name ?? '') ||
      _role != (widget.initial?.role ?? 'family');

  @override
  void initState() {
    super.initState();
    _id = widget.initial?.id ?? const Uuid().v4();
    _nameController = TextEditingController(text: widget.initial?.name ?? '')
      ..addListener(_changed);
    _role = widget.initial?.role ?? 'family';
  }

  void _changed() => setState(() {});

  void _showError(String message) {
    setState(() => _error = message);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _errorKey.currentContext != null) {
        Scrollable.ensureVisible(_errorKey.currentContext!);
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final name = _nameController.text.trim();
      final initial = widget.initial;
      final actions = ref.read(togetherActionsProvider);
      if (initial == null) {
        await actions.addMember(id: _id, name: name, role: _role);
      } else {
        await actions.updateMember(initial.copyWith(name: name, role: _role));
      }
      if (mounted) _guardKey.currentState?.closeAfterSave();
    } catch (_) {
      if (mounted) {
        _showError(
          'Belum berhasil menyimpan anggota. Isian tetap ada; coba simpan lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final initial = widget.initial;
    if (_saving || initial == null) return;
    final confirmed = await confirmEditorAction(
      context,
      title: 'Hapus ${initial.name} dari keluarga?',
      message:
          'Momen tetap tersimpan. Hanya kaitannya dengan anggota ini yang dihapus.${_dirty ? ' Perubahan yang belum disimpan juga akan dibuang.' : ''}',
      confirmLabel: 'Hapus anggota',
      destructive: true,
    );
    if (!confirmed || !mounted || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(togetherActionsProvider).deleteMember(initial.id);
      if (mounted) _guardKey.currentState?.closeAfterSave();
    } catch (_) {
      if (mounted) _showError('Belum berhasil menghapus anggota. Coba lagi.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return EditorGuard(
      key: _guardKey,
      isDirty: () => _dirty,
      isBusy: () => _saving,
      child: EditorSheetFrame(
        title: widget.initial == null ? 'Tambah anggota' : 'Edit anggota',
        onClose: _saving ? null : () => _guardKey.currentState?.requestClose(),
        saveButton: FilledButton.icon(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          icon: Icon(
            _saving ? Icons.hourglass_top_rounded : Icons.check_rounded,
          ),
          label: Text(_saving ? 'Menyimpan…' : 'Simpan anggota'),
        ),
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
                'Gunakan nama yang akrab. Anggota bisa ditandai dalam momen keluarga.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                enabled: !_saving,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Nama panggilan',
                  hintText: 'Contoh: Nara',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                  errorMaxLines: 3,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Tulis nama panggilan terlebih dahulu.';
                  }
                  if (value.characters.length > 60) {
                    return 'Nama paling panjang 60 karakter.';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _role,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Peran di keluarga',
                  prefixIcon: Icon(Icons.people_outline_rounded),
                ),
                items: [
                  for (final role in _roles.entries)
                    DropdownMenuItem(value: role.key, child: Text(role.value)),
                  if (!_roles.containsKey(_role))
                    DropdownMenuItem(
                      value: _role,
                      child: const Text('Peran tersimpan'),
                    ),
                ],
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _role = value ?? 'family'),
              ),
              if (widget.initial != null) ...[
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: _saving ? null : _delete,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  icon: const Icon(Icons.person_remove_outlined),
                  label: const Text('Hapus anggota'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
