import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/gold_button.dart';
import '../../core/widgets/luxe_card.dart';
import '../../core/widgets/stat_ring.dart';
import '../../data/models/measurement.dart';
import '../../domain/zscore/zscore_service.dart';
import '../../state/app_settings.dart';
import '../../state/monetization_provider.dart';
import '../../state/providers.dart';

/// Form pencatatan pengukuran dengan analisis z-score secara langsung.
class AddMeasurementScreen extends ConsumerStatefulWidget {
  const AddMeasurementScreen({super.key, this.existing});

  /// Bila diisi, layar menjadi mode ubah.
  final Measurement? existing;

  @override
  ConsumerState<AddMeasurementScreen> createState() =>
      _AddMeasurementScreenState();
}

class _AddMeasurementScreenState extends ConsumerState<AddMeasurementScreen> {
  late DateTime _date;
  late final TextEditingController _weight;
  late final TextEditingController _height;
  late final TextEditingController _head;
  late final TextEditingController _muac;
  late final TextEditingController _note;
  var _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _date = e?.date ?? DateTime.now();
    _weight = TextEditingController(text: _num(e?.weight));
    _height = TextEditingController(text: _num(e?.height));
    _head = TextEditingController(text: _num(e?.head));
    _muac = TextEditingController(text: _num(e?.muac));
    _note = TextEditingController(text: e?.note ?? '');
  }

  String _num(double? v) => v == null ? '' : v.toString().replaceAll('.', ',');

  double? _parse(String text) {
    final cleaned = text.trim().replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();
    _head.dispose();
    _muac.dispose();
    _note.dispose();
    super.dispose();
  }

  MeasurementAnalysis? _preview() {
    final child = ref.read(selectedChildProvider);
    if (child == null) return null;
    final w = _parse(_weight.text);
    final h = _parse(_height.text);
    final hc = _parse(_head.text);
    final mu = _parse(_muac.text);
    if (w == null && h == null && hc == null && mu == null) return null;

    final draft = Measurement(
      id: 'draft',
      childId: child.id,
      date: _date,
      weight: w,
      height: h,
      head: hc,
      muac: mu,
      createdAt: 0,
    );
    return ref
        .read(zScoreServiceProvider)
        .analyze(
          child: child,
          measurement: draft,
          standard: ref.read(settingsProvider).standard,
        );
  }

  Future<void> _pickDate() async {
    final child = ref.read(selectedChildProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: child?.birthDate ?? DateTime(2005),
      lastDate: DateTime.now(),
      helpText: 'Tanggal Pengukuran',
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        );
      });
    }
  }

  /// Rentang kewajaran absolut untuk menangkap salah ketik fatal.
  String? _rangeError(double? w, double? h, double? hc, double? mu) {
    if (w != null && (w < 1.5 || w > 120)) {
      return 'Berat badan ${Format.decimal(w)} kg tampak salah ketik (rentang wajar 1,5-120 kg).';
    }
    if (h != null && (h < 30 || h > 200)) {
      return 'Tinggi/panjang ${Format.decimal(h)} cm tampak salah ketik (rentang wajar 30-200 cm).';
    }
    if (hc != null && (hc < 25 || hc > 65)) {
      return 'Lingkar kepala ${Format.decimal(hc)} cm tampak salah ketik (rentang wajar 25-65 cm).';
    }
    if (mu != null && (mu < 8 || mu > 30)) {
      return 'LILA ${Format.decimal(mu)} cm tampak salah ketik (rentang wajar 8-30 cm).';
    }
    return null;
  }

  /// Minta konfirmasi bila z-score sangat ekstrem (umumnya salah ketik).
  Future<bool> _confirmIfExtreme(MeasurementAnalysis analysis) async {
    final extreme = analysis.results.where((r) => r.z.abs() > 4).toList();
    if (extreme.isEmpty) return true;
    final detail = extreme
        .map((e) => '${e.indicator.shortLabel} ${Format.z(e.z)}')
        .join(', ');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.warn,
          size: 32,
        ),
        title: const Text('Nilai Sangat Tidak Biasa'),
        content: Text(
          'Hasil hitungan sangat ekstrem ($detail). Ini biasanya tanda salah ketik '
          'atau salah satuan. Yakin nilai yang diisi sudah benar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Periksa Lagi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Sudah Benar'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _save() async {
    final child = ref.read(selectedChildProvider);
    if (child == null) return;

    final w = _parse(_weight.text);
    final h = _parse(_height.text);
    final hc = _parse(_head.text);
    final mu = _parse(_muac.text);
    if (w == null && h == null && hc == null && mu == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi minimal satu nilai pengukuran.')),
      );
      return;
    }

    // Validasi kewajaran sebelum menyimpan.
    final error = _rangeError(w, h, hc, mu);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
      return;
    }

    // Konfirmasi bila hasil analisis sangat ekstrem.
    final standard = ref.read(settingsProvider).standard;
    final draftAnalysis = ref
        .read(zScoreServiceProvider)
        .analyze(
          child: child,
          measurement: Measurement(
            id: 'draft',
            childId: child.id,
            date: _date,
            weight: w,
            height: h,
            head: hc,
            muac: mu,
            createdAt: 0,
          ),
          standard: standard,
        );
    if (!mounted) return;
    if (!await _confirmIfExtreme(draftAnalysis)) return;

    setState(() => _saving = true);
    try {
      final actions = ref.read(measurementActionsProvider);
      Measurement saved;
      if (_isEdit) {
        saved = widget.existing!.copyWith(
          date: _date,
          weight: w,
          height: h,
          head: hc,
          muac: mu,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        );
        await actions.update(saved);
      } else {
        saved = await actions.add(
          childId: child.id,
          date: _date,
          weight: w,
          height: h,
          head: hc,
          muac: mu,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        );
      }

      if (!mounted) return;
      HapticFeedback.lightImpact();
      ref.read(monetizationProvider.notifier).onMeasurementSaved();
      final analysis = ref
          .read(zScoreServiceProvider)
          .analyze(child: child, measurement: saved, standard: standard);
      await _showResultSheet(analysis);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showResultSheet(MeasurementAnalysis analysis) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ResultSheet(analysis: analysis, isEdit: _isEdit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(selectedChildProvider);
    final analysis = _preview();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Ubah Pengukuran' : 'Pengukuran Baru'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          if (child != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'untuk ${child.name} • ${Format.ageFromMonths(child.effectiveAgeMonthsAt(_date))}'
                '${child.usesCorrectedAge ? ' (usia terkoreksi)' : ''}',
                style: AppTheme.sans(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppColors.inkSoft,
                ),
              ),
            ),

          // ── Tanggal ───────────────────────────────────────────────────
          GestureDetector(
            onTap: _pickDate,
            child: AbsorbPointer(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Tanggal Pengukuran',
                  prefixIcon: Icon(Icons.event_rounded),
                ),
                controller: TextEditingController(
                  text: Format.dateWithDay(_date),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _MeasureField(
                  controller: _weight,
                  label: 'Berat Badan',
                  unit: 'kg',
                  icon: Icons.monitor_weight_rounded,
                  color: AppColors.gold,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MeasureField(
                  controller: _height,
                  label: child != null && child.effectiveAgeMonthsAt(_date) < 24
                      ? 'Panjang Badan'
                      : 'Tinggi Badan',
                  unit: 'cm',
                  icon: Icons.straighten_rounded,
                  color: AppColors.boy,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          // Panduan posisi ukur sesuai usia (WHO).
          if (child != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.straighten_rounded,
                    size: 14,
                    color: AppColors.goldDeep,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      child.effectiveAgeMonthsAt(_date) < 24
                          ? 'Di bawah 2 tahun: ukur panjang badan dalam posisi BERBARING (infantometer).'
                          : 'Usia 2 tahun ke atas: ukur tinggi badan dalam posisi BERDIRI (stadiometer).',
                      style: AppTheme.sans(
                        size: 11,
                        weight: FontWeight.w600,
                        color: AppColors.inkSoft,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MeasureField(
                  controller: _head,
                  label: 'Lingkar Kepala',
                  unit: 'cm',
                  icon: Icons.circle_outlined,
                  color: AppColors.girl,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MeasureField(
                  controller: _muac,
                  label: 'LILA (opsional)',
                  unit: 'cm',
                  icon: Icons.fitness_center_rounded,
                  color: AppColors.good,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _note,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Catatan (opsional)',
              hintText: 'mis. diukur di Posyandu Melati',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
          const SizedBox(height: 20),

          // ── Pratinjau analisis langsung ───────────────────────────────
          if (analysis != null && analysis.results.isNotEmpty) ...[
            Text(
              'Analisis Langsung (${analysis.standardUsed.shortLabel})',
              style: AppTheme.serif(size: 17, weight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            LuxeCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final r in analysis.results)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 56,
                            child: Text(
                              r.indicator.shortLabel,
                              style: AppTheme.sans(
                                size: 12,
                                weight: FontWeight.w800,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _ZBar(z: r.z, color: r.classification.color),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 74,
                            child: Text(
                              Format.z(r.z),
                              textAlign: TextAlign.end,
                              style: AppTheme.sans(
                                size: 12,
                                weight: FontWeight.w800,
                                color: r.classification.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (analysis.muacClassification != null) ...[
                    const Divider(height: 20),
                    Row(
                      children: [
                        Icon(
                          analysis.muacClassification!.icon,
                          size: 16,
                          color: analysis.muacClassification!.color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'LILA: ${analysis.muacClassification!.label}',
                            style: AppTheme.sans(
                              size: 12.5,
                              weight: FontWeight.w700,
                              color: analysis.muacClassification!.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          GoldButton(
            label: _saving
                ? 'Menyimpan...'
                : (_isEdit ? 'Simpan Perubahan' : 'Simpan Pengukuran'),
            icon: Icons.check_rounded,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _MeasureField extends StatelessWidget {
  const _MeasureField({
    required this.controller,
    required this.label,
    required this.unit,
    required this.icon,
    required this.color,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String unit;
  final IconData icon;
  final Color color;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      style: AppTheme.sans(size: 16, weight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        prefixIcon: Icon(icon, color: color, size: 20),
        suffixStyle: AppTheme.sans(
          size: 13,
          weight: FontWeight.w700,
          color: AppColors.inkFaint,
        ),
      ),
    );
  }
}

/// Bilah posisi z-score pada rentang -3 s.d. +3.
class _ZBar extends StatelessWidget {
  const _ZBar({required this.z, required this.color});

  final double z;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final clamped = z.clamp(-3.0, 3.0);
    final fraction = (clamped + 3) / 6;

    return SizedBox(
      height: 22,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.dangerSoft,
                      AppColors.warnSoft,
                      AppColors.goodSoft,
                      AppColors.warnSoft,
                      AppColors.dangerSoft,
                    ],
                  ),
                ),
              ),
              // Penanda zona normal (z -2 s.d. +2).
              Positioned(
                left: constraints.maxWidth * (1 / 6),
                right: constraints.maxWidth * (1 / 6),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.good.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Positioned(
                left: (constraints.maxWidth - 14) * fraction,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: AppColors.softShadow(
                      opacity: 0.2,
                      blur: 6,
                      y: 2,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Lembar hasil setelah pengukuran tersimpan.
class _ResultSheet extends StatelessWidget {
  const _ResultSheet({required this.analysis, required this.isEdit});

  final MeasurementAnalysis analysis;
  final bool isEdit;

  @override
  Widget build(BuildContext context) {
    final headline = analysis.headline;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.hairline,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (headline?.color ?? AppColors.good).withValues(
                    alpha: 0.14,
                  ),
                ),
                child: Icon(
                  headline?.icon ?? Icons.check_circle_rounded,
                  size: 36,
                  color: headline?.color ?? AppColors.good,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                isEdit ? 'Pengukuran Diperbarui' : 'Tercatat dengan Baik',
                style: AppTheme.serif(size: 22, weight: FontWeight.w600),
              ),
            ),
            if (headline != null) ...[
              const SizedBox(height: 6),
              Center(
                child: Text(
                  headline.label,
                  style: AppTheme.sans(
                    size: 15,
                    weight: FontWeight.w800,
                    color: headline.color,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 22),
            for (final r in analysis.results) ...[
              LuxeCard(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.indicator.label,
                            style: AppTheme.sans(
                              size: 13,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ),
                        ZBadge(
                          label:
                              '${Format.z(r.z)} • ${Format.percentile(r.percentile)}',
                          color: r.classification.color,
                          dense: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      r.classification.label,
                      style: AppTheme.serif(
                        size: 16,
                        weight: FontWeight.w600,
                        color: r.classification.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      r.classification.advice,
                      style: AppTheme.sans(
                        size: 12.5,
                        color: AppColors.inkSoft,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (analysis.warnings.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  analysis.warnings.join('\n'),
                  style: AppTheme.sans(
                    size: 11.5,
                    color: AppColors.inkFaint,
                    height: 1.5,
                  ),
                ),
              ),
            const SizedBox(height: 14),
            GoldButton(
              label: 'Selesai',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
