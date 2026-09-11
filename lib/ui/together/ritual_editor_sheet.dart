import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/ritual.dart';
import '../../state/together_providers.dart';
import '../widgets/editor_guard.dart';

class RitualEditorSheet extends ConsumerStatefulWidget {
  const RitualEditorSheet({super.key, this.initial});
  final Ritual? initial;
  @override
  ConsumerState<RitualEditorSheet> createState() => _RitualEditorSheetState();
}

class _RitualEditorSheetState extends ConsumerState<RitualEditorSheet> {
  final _guardKey = GlobalKey<EditorGuardState>();
  final _formKey = GlobalKey<FormState>();
  final _errorKey = GlobalKey();
  final _daysKey = GlobalKey();
  late final String _id;
  late final int _createdAt;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late RitualTimeOfDay _timeOfDay;
  late Set<int> _repeatDays;
  late String _accentKey;
  var _saving = false;
  var _submitted = false;
  String? _error;

  bool get _dirty =>
      _titleController.text != (widget.initial?.title ?? '') ||
      _descriptionController.text != (widget.initial?.description ?? '') ||
      _timeOfDay != (widget.initial?.timeOfDay ?? RitualTimeOfDay.anytime) ||
      !setEquals(
        _repeatDays,
        widget.initial?.repeatDays ?? const {1, 2, 3, 4, 5, 6, 7},
      ) ||
      _accentKey != (widget.initial?.accentKey ?? 'sage');

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _id = initial?.id ?? const Uuid().v4();
    _createdAt = initial?.createdAt ?? DateTime.now().millisecondsSinceEpoch;
    _titleController = TextEditingController(text: initial?.title ?? '')
      ..addListener(_changed);
    _descriptionController = TextEditingController(
      text: initial?.description ?? '',
    )..addListener(_changed);
    _timeOfDay = initial?.timeOfDay ?? RitualTimeOfDay.anytime;
    _repeatDays = {
      ...(initial?.repeatDays ?? const {1, 2, 3, 4, 5, 6, 7}),
    };
    _accentKey = initial?.accentKey ?? 'sage';
  }

  void _changed() => setState(() {});

  void _reveal(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && key.currentContext != null) {
        Scrollable.ensureVisible(key.currentContext!);
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) {
      _reveal(_formKey);
      return;
    }
    if (_repeatDays.isEmpty) {
      _reveal(_daysKey);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final description = _descriptionController.text.trim();
    final ritual = Ritual(
      id: _id,
      title: _titleController.text.trim(),
      description: description.isEmpty ? null : description,
      timeOfDay: _timeOfDay,
      repeatDays: {..._repeatDays},
      accentKey: _accentKey,
      isArchived: widget.initial?.isArchived ?? false,
      createdAt: _createdAt,
    );
    try {
      await ref.read(togetherActionsProvider).saveRitual(ritual);
      if (mounted) _guardKey.currentState?.closeAfterSave();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Belum berhasil menyimpan ritual. Isian tetap ada; coba simpan lagi.',
        );
        _reveal(_errorKey);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changeArchive() async {
    final initial = widget.initial;
    if (_saving || initial == null) return;
    final restoring = initial.isArchived;
    final confirmed = await confirmEditorAction(
      context,
      title: restoring ? 'Aktifkan ritual kembali?' : 'Arsipkan ritual ini?',
      message:
          '${restoring ? 'Ritual akan muncul lagi sesuai hari yang dijadwalkan.' : 'Ritual akan disimpan di arsip. Riwayat kegiatan tetap ada dan ritual bisa diaktifkan kembali.'}${_dirty ? ' Perubahan yang belum disimpan akan dibuang.' : ''}',
      confirmLabel: restoring ? 'Aktifkan' : 'Arsipkan',
    );
    if (!confirmed || !mounted || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final actions = ref.read(togetherActionsProvider);
      if (restoring) {
        await actions.saveRitual(initial.copyWith(isArchived: false));
      } else {
        await actions.archiveRitual(initial.id);
      }
      if (mounted) _guardKey.currentState?.closeAfterSave();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = restoring
              ? 'Belum berhasil mengaktifkan ritual. Coba lagi.'
              : 'Belum berhasil mengarsipkan ritual. Coba lagi.',
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
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const fullDays = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    final accents = [
      ('sage', 'Daun', colors.secondary),
      ('terracotta', 'Senja', colors.primary),
      ('gold', 'Madu', colors.tertiary),
    ];
    return EditorGuard(
      key: _guardKey,
      isDirty: () => _dirty,
      isBusy: () => _saving,
      child: EditorSheetFrame(
        title: widget.initial == null ? 'Buat ritual baru' : 'Edit ritual',
        onClose: _saving ? null : () => _guardKey.currentState?.requestClose(),
        saveButton: FilledButton.icon(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          icon: Icon(
            _saving ? Icons.hourglass_top_rounded : Icons.check_rounded,
          ),
          label: Text(_saving ? 'Menyimpan…' : 'Simpan ritual'),
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
                widget.initial?.isArchived == true
                    ? 'Ritual ini ada di arsip. Menyimpan perubahan tidak akan mengaktifkannya.'
                    : 'Mulai dari kebiasaan kecil yang ingin dilakukan bersama.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                enabled: !_saving,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Nama ritual',
                  hintText: 'Contoh: Cerita sebelum tidur',
                  prefixIcon: Icon(Icons.auto_awesome_outlined),
                  errorMaxLines: 3,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Beri nama untuk ritual ini.';
                  }
                  if (value.characters.length > 80) {
                    return 'Nama ritual paling panjang 80 karakter.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                enabled: !_saving,
                textCapitalization: TextCapitalization.sentences,
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Pengingat (opsional)',
                  hintText: 'Satu cerita, satu pelukan, tanpa buru-buru.',
                  errorMaxLines: 3,
                ),
                validator: (value) =>
                    value != null && value.characters.length > 500
                    ? 'Pengingat paling panjang 500 karakter.'
                    : null,
              ),
              const SizedBox(height: 22),
              Text('Waktu bersama', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final time in RitualTimeOfDay.values)
                    ChoiceChip(
                      label: Text(time.label),
                      selected: _timeOfDay == time,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      onSelected: _saving
                          ? null
                          : (_) => setState(() => _timeOfDay = time),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Hari berulang',
                key: _daysKey,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih hari ritual muncul di halaman Hari ini.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var day = 1; day <= 7; day++)
                    FilterChip(
                      label: Text(days[day - 1]),
                      tooltip: fullDays[day - 1],
                      selected: _repeatDays.contains(day),
                      showCheckmark: false,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      onSelected: _saving
                          ? null
                          : (selected) => setState(() {
                              if (selected) {
                                _repeatDays.add(day);
                              } else {
                                _repeatDays.remove(day);
                              }
                            }),
                    ),
                ],
              ),
              if (_submitted && _repeatDays.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      'Pilih sedikitnya satu hari.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.error,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              Text('Nuansa', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final accent in accents)
                    ChoiceChip(
                      avatar: Icon(Icons.circle, size: 16, color: accent.$3),
                      label: Text(accent.$2),
                      selected: _accentKey == accent.$1,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      onSelected: _saving
                          ? null
                          : (_) => setState(() => _accentKey = accent.$1),
                    ),
                  if (!accents.any((accent) => accent.$1 == _accentKey))
                    const Chip(label: Text('Nuansa tersimpan')),
                ],
              ),
              if (widget.initial != null) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _changeArchive,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  icon: Icon(
                    widget.initial!.isArchived
                        ? Icons.unarchive_outlined
                        : Icons.archive_outlined,
                  ),
                  label: Text(
                    widget.initial!.isArchived
                        ? 'Aktifkan kembali'
                        : 'Arsipkan ritual',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
