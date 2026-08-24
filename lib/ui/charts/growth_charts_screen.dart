import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/luxe_card.dart';
import '../../core/widgets/stat_ring.dart';
import '../../data/models/measurement.dart';
import '../../domain/standards/growth_standards.dart';
import '../../state/app_settings.dart';
import '../../state/providers.dart';
import 'widgets/growth_chart.dart';

/// Layar grafik pertumbuhan multi-standar dengan pemilih indikator.
class GrowthChartsScreen extends ConsumerStatefulWidget {
  const GrowthChartsScreen({super.key});

  @override
  ConsumerState<GrowthChartsScreen> createState() => _GrowthChartsScreenState();
}

class _GrowthChartsScreenState extends ConsumerState<GrowthChartsScreen> {
  GrowthIndicator _indicator = GrowthIndicator.wfa;
  GrowthStandard? _standardOverride;
  final _transformationController = TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(selectedChildProvider);
    final standardsAsync = ref.watch(standardsProvider);
    final settings = ref.watch(settingsProvider);
    final measurements =
        ref.watch(measurementsProvider).valueOrNull ?? const <Measurement>[];

    final standard = _standardOverride ?? settings.standard;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grafik Pertumbuhan'),
        actions: [
          IconButton(
            tooltip: 'Perbesar',
            icon: const Icon(Icons.zoom_in_rounded),
            onPressed: () => _zoom(1.5),
          ),
          IconButton(
            tooltip: 'Perkecil',
            icon: const Icon(Icons.zoom_out_rounded),
            onPressed: () => _zoom(1 / 1.5),
          ),
          IconButton(
            tooltip: 'Atur ulang tampilan',
            icon: const Icon(Icons.fit_screen_rounded),
            onPressed: () {
              _transformationController.value = Matrix4.identity();
            },
          ),
        ],
      ),
      body: child == null
          ? const EmptyState(
              icon: Icons.show_chart_rounded,
              title: 'Belum Ada Anak Terpilih',
              message:
                  'Tambahkan profil anak untuk melihat grafik pertumbuhannya.',
            )
          : standardsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Gagal memuat standar: $e')),
              data: (standards) {
                final ageMonths = child.effectiveAgeInMonths;
                final available = standards.availableIndicators(
                  standard: standard,
                  isBoy: child.isBoy,
                  ageMonths: ageMonths,
                );
                if (!available.contains(_indicator)) {
                  _indicator = available.isNotEmpty
                      ? available.first
                      : GrowthIndicator.wfa;
                }

                final table = standards.tableFor(
                  standard: standard,
                  indicator: _indicator,
                  isBoy: child.isBoy,
                  ageMonths: ageMonths,
                );

                final childPoints = _buildPoints(measurements, child, standard);
                final effective = standards.resolveEffective(
                  standard,
                  ageMonths,
                );

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                  children: [
                    // ── Pemilih standar ──────────────────────────────────
                    _StandardSelector(
                      selected: standard,
                      onChanged: (s) => setState(() => _standardOverride = s),
                    ),
                    const SizedBox(height: 12),

                    // ── Pemilih indikator ────────────────────────────────
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: available.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final ind = available[i];
                          final selected = ind == _indicator;
                          return _IndicatorChip(
                            label: ind.shortLabel,
                            selected: selected,
                            onTap: () => setState(() => _indicator = ind),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Kartu grafik ─────────────────────────────────────
                    LuxeCard(
                      padding: const EdgeInsets.fromLTRB(10, 18, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 10, bottom: 4),
                            child: Text(
                              '${_indicator.label} • ${effective.label}',
                              style: AppTheme.sans(
                                size: 12.5,
                                weight: FontWeight.w800,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ),
                          Semantics(
                            label:
                                'Grafik kurva pertumbuhan ${_indicator.label} dengan ${childPoints.length} titik pengukuran anak',
                            child: SizedBox(
                              height: 380,
                              child: table == null
                                  ? const Center(
                                      child: Text('Tabel tidak tersedia'),
                                    )
                                  : GrowthChart(
                                      table: table,
                                      indicator: _indicator,
                                      childPoints: childPoints,
                                      isBoy: child.isBoy,
                                      currentAgeMonths: ageMonths,
                                      transformationController:
                                          _transformationController,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const _Legend(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Posisi terkini ───────────────────────────────────
                    _CurrentPositionCard(
                      indicator: _indicator,
                      measurements: measurements,
                      standard: standard,
                    ),
                    const SizedBox(height: 16),

                    // ── Keterangan standar ───────────────────────────────
                    SoftCard(
                      color: AppColors.goldMist,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            size: 18,
                            color: AppColors.goldDeep,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              standard.description,
                              style: AppTheme.sans(
                                size: 11.5,
                                color: AppColors.inkSoft,
                                height: 1.55,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  void _zoom(double factor) {
    final current = _transformationController.value;
    final scaled = current.clone()..scaleByDouble(factor, 1.0, 1.0, 1.0);
    _transformationController.value = scaled;
  }

  List<ChildPoint> _buildPoints(
    List<Measurement> measurements,
    dynamic child,
    GrowthStandard standard,
  ) {
    final standards = ref.read(standardsProvider).valueOrNull;
    if (standards == null) return const [];

    final points = <ChildPoint>[];
    for (final m in measurements) {
      final age = child.effectiveAgeMonthsAt(m.date) as double;
      double? x;
      double? y;
      String label;

      switch (_indicator) {
        case GrowthIndicator.wfa:
          if (m.weight == null) continue;
          x = age;
          y = m.weight;
          label = '${Format.ageFromMonths(age)} • ${Format.kg(y)}';
        case GrowthIndicator.lhfa:
          if (m.height == null) continue;
          x = age;
          y = m.height;
          label = '${Format.ageFromMonths(age)} • ${Format.cm(y)}';
        case GrowthIndicator.wflh:
          if (m.weight == null || m.height == null) continue;
          x = m.height;
          y = m.weight;
          label = '${Format.cm(m.height)} • ${Format.kg(y)}';
        case GrowthIndicator.bfa:
          if (m.bmi == null) continue;
          x = age;
          y = m.bmi;
          label =
              '${Format.ageFromMonths(age)} • IMT ${y!.toStringAsFixed(1).replaceAll('.', ',')}';
        case GrowthIndicator.hcfa:
          if (m.head == null) continue;
          x = age;
          y = m.head;
          label = '${Format.ageFromMonths(age)} • ${Format.cm(y)}';
      }

      if (x == null || y == null) continue;
      final table = standards.tableFor(
        standard: standard,
        indicator: _indicator,
        isBoy: child.isBoy as bool,
        ageMonths: age,
      );
      final z = table?.zFor(y, x);
      points.add(ChildPoint(x: x, y: y, z: z, tooltipLabel: label));
    }
    points.sort((a, b) => a.x.compareTo(b.x));
    return points;
  }
}

class _StandardSelector extends StatelessWidget {
  const _StandardSelector({required this.selected, required this.onChanged});

  final GrowthStandard selected;
  final ValueChanged<GrowthStandard> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: GrowthStandard.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final s = GrowthStandard.values[i];
          final isSelected = s == selected;
          return GestureDetector(
            onTap: () => onChanged(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.goldGradient : null,
                color: isSelected ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: isSelected ? Colors.transparent : AppColors.hairline,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                s.shortLabel,
                style: AppTheme.sans(
                  size: 12.5,
                  weight: FontWeight.w800,
                  color: isSelected ? Colors.white : AppColors.inkSoft,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _IndicatorChip extends StatelessWidget {
  const _IndicatorChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.hairline,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.sans(
            size: 12.5,
            weight: FontWeight.w800,
            color: selected ? Colors.white : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget line(Color color, String label, {bool dash = false}) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 3,
            decoration: BoxDecoration(
              color: dash ? null : color,
              borderRadius: BorderRadius.circular(2),
              border: dash ? Border.all(color: color, width: 1.6) : null,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTheme.sans(
              size: 10,
              weight: FontWeight.w700,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
      child: Wrap(
        spacing: 14,
        runSpacing: 8,
        children: [
          line(AppColors.gold, 'Median (0)'),
          line(AppColors.warn, '±2 SD'),
          line(AppColors.danger, '±3 SD', dash: true),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.goldDeep,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Anak Anda',
                style: AppTheme.sans(
                  size: 10,
                  weight: FontWeight.w700,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Kartu posisi z-score terkini untuk indikator terpilih.
class _CurrentPositionCard extends ConsumerWidget {
  const _CurrentPositionCard({
    required this.indicator,
    required this.measurements,
    required this.standard,
  });

  final GrowthIndicator indicator;
  final List<Measurement> measurements;
  final GrowthStandard standard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider);
    if (child == null || measurements.isEmpty) return const SizedBox.shrink();

    // Cari pengukuran terakhir yang punya nilai untuk indikator ini.
    final service = ref.read(zScoreServiceProvider);
    for (final m in measurements.reversed) {
      final hasValue = switch (indicator) {
        GrowthIndicator.wfa => m.weight != null,
        GrowthIndicator.lhfa => m.height != null,
        GrowthIndicator.wflh => m.weight != null && m.height != null,
        GrowthIndicator.bfa => m.bmi != null,
        GrowthIndicator.hcfa => m.head != null,
      };
      if (!hasValue) continue;

      final analysis = service.analyze(
        child: child,
        measurement: m,
        standard: standard,
      );
      final result = analysis.resultFor(indicator);
      if (result == null) return const SizedBox.shrink();

      final percentileProgress = (result.percentile / 100).clamp(0.0, 1.0);

      return LuxeCard(
        child: Row(
          children: [
            StatRing(
              progress: percentileProgress,
              size: 96,
              color: result.classification.color,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Format.percentile(result.percentile),
                    style: AppTheme.serif(size: 19, weight: FontWeight.w600),
                  ),
                  Text(
                    'persentil',
                    style: AppTheme.sans(
                      size: 9.5,
                      weight: FontWeight.w600,
                      color: AppColors.inkFaint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Posisi ${indicator.shortLabel} Terkini',
                    style: AppTheme.sans(
                      size: 11,
                      weight: FontWeight.w700,
                      color: AppColors.inkFaint,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    result.classification.label,
                    style: AppTheme.serif(
                      size: 17.5,
                      weight: FontWeight.w600,
                      color: result.classification.color,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Z-score ${Format.z(result.z)} • ${Format.date(m.date)}',
                    style: AppTheme.sans(
                      size: 11.5,
                      weight: FontWeight.w600,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SoftCard(
      color: AppColors.cream,
      child: Text(
        'Belum ada data ${indicator.shortLabel} untuk ditampilkan posisinya.',
        style: AppTheme.sans(size: 12.5, color: AppColors.inkSoft),
      ),
    );
  }
}
