import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/family_member.dart';
import '../../state/together_providers.dart';

class FamilyMemberEditorSheet extends ConsumerStatefulWidget {
  const FamilyMemberEditorSheet({super.key, this.initial});

  final FamilyMember? initial;

  @override
  ConsumerState<FamilyMemberEditorSheet> createState() =>
      _FamilyMemberEditorSheetState();
}

class _FamilyMemberEditorSheetState
    extends ConsumerState<FamilyMemberEditorSheet> {
  late final TextEditingController _nameController;
  late String _role;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _role = widget.initial?.role ?? 'family';
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    final initial = widget.initial;
    if (initial == null) {
      await ref
          .read(togetherActionsProvider)
          .addMember(name: name, role: _role);
    } else {
      await ref
          .read(togetherActionsProvider)
          .updateMember(initial.copyWith(name: name, role: _role));
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, inset + 20),
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
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.initial == null ? 'Tambah anggota' : 'Edit anggota',
                    style: AppTheme.serif(size: 24, weight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Tutup',
                  icon: const PhosphorIcon(PhosphorIconsLight.x),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama panggilan',
                prefixIcon: PhosphorIcon(PhosphorIconsLight.user),
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(
                labelText: 'Peran di keluarga',
                prefixIcon: PhosphorIcon(PhosphorIconsLight.usersThree),
              ),
              items: const [
                DropdownMenuItem(value: 'family', child: Text('Keluarga')),
                DropdownMenuItem(value: 'parent', child: Text('Orang tua')),
                DropdownMenuItem(
                  value: 'grandparent',
                  child: Text('Kakek/nenek'),
                ),
                DropdownMenuItem(value: 'sibling', child: Text('Kakak/adik')),
              ],
              onChanged: (value) => setState(() => _role = value ?? 'family'),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const PhosphorIcon(PhosphorIconsLight.check),
                label: Text(_saving ? 'Menyimpan…' : 'Simpan anggota'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
