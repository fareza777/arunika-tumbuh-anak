import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/fade_slide.dart';
import '../../core/widgets/gender_avatar.dart';
import '../../core/widgets/luxe_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_ring.dart';
import '../../data/models/child.dart';
import '../../data/models/measurement.dart';
import '../../domain/zscore/zscore_service.dart';
import '../../state/providers.dart';
import '../charts/growth_charts_screen.dart';
import '../children/child_form_screen.dart';
import '../insights/insights_screen.dart';
import '../measure/add_measurement_screen.dart';

/// Beranda: ringkasan anak terpilih, status gizi, tren, dan aksi cepat.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(childrenProvider);
    final child = ref.watch(selectedChildProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: children.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
          data: (list) {
            if (list.isEmpty || child == null) {
              return EmptyState(
                icon: Icons.child_care_rounded,
                title: 'Selamat Datang di Arunika',
                message:
                    'Mulai dengan menambahkan profil si kecil, lalu catat pengukuran pertamanya.',
                actionLabel: 'Tambah Profil Anak',
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChildFormScreen()),
                ),
              );
            }
            return _HomeContent(child: child, siblings: list);
          },
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.child, required this.siblings});

  final Child child;
  final List<Child> siblings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measurements =
        ref.watch(measurementsProvider).valueOrNull ?? const [];
    final analysis = ref.watch(latestAnalysisProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: StaggeredColumn(
              children: [
                _GreetingHeader(child: child),
                const SizedBox(height: 18),
                _ChildSwitcher(children: siblings, selected: child),
                const SizedBox(height: 20),
                _HeroCard(
                  child: child,
                  measurements: measurements,
                  analysis: analysis,
                ),
                const SizedBox(height: 20),
                if (analysis != null) ...[
                  _StatusCard(analysis: analysis),
                  const SizedBox(height: 20),
                ],
                if (measurements.where((m) => m.weight != null).length >=
                    2) ...[
                  _TrendCard(measurements: measurements, isBoy: child.isBoy),
                  const SizedBox(height: 20),
                ],
                const _QuickActions(),
                const SizedBox(height: 110),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Sapaan ───────────────────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.child});

  final Child child;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 19) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_greeting, Bunda',
                style: AppTheme.sans(
                  size: 13.5,
                  weight: FontWeight.w600,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kabar ${child.name} hari ini',
                style: AppTheme.serif(size: 24, weight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.goldMist,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.goldSoft),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                size: 15,
                color: AppColors.goldDeep,
              ),
              const SizedBox(width: 7),
              Text(
                Format.date(DateTime.now()),
                style: AppTheme.sans(
                  size: 12,
                  weight: FontWeight.w700,
                  color: AppColors.goldDeep,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Pemilih anak ─────────────────────────────────────────────────────────────

class _ChildSwitcher extends ConsumerWidget {
  const _ChildSwitcher({required this.children, required this.selected});

  final List<Child> children;
  final Child selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (children.length <= 1) return const SizedBox.shrink();

    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final c = children[i];
          final isSelected = c.id == selected.id;
          return GestureDetector(
            onTap: () =>
                ref.read(selectedChildIdProvider.notifier).select(c.id),
            child: Column(
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.0 : 0.88,
                  duration: const Duration(milliseconds: 250),
                  child: GenderAvatar(
                    name: c.name,
                    isBoy: c.isBoy,
                    photoPath: c.photoPath,
                    size: 54,
                    showRing: isSelected,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  c.name.split(' ').first,
                  style: AppTheme.sans(
                    size: 11.5,
                    weight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? AppColors.ink : AppColors.inkFaint,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Kartu utama ──────────────────────────────────────────────────────────────

class _HeroCard extends ConsumerWidget {
  const _HeroCard({
    required this.child,
    required this.measurements,
    required this.analysis,
  });

  final Child child;
  final List<Measurement> measurements;
  final MeasurementAnalysis? analysis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = measurements.isEmpty ? null : measurements.last;
    final prevWeight = _previousWith(measurements, (m) => m.weight);
    final prevHeight = _previousWith(measurements, (m) => m.height);

    return LuxeCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFFBF4E2)],
      ),
      borderColor: AppColors.goldSoft,
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Row(
            children: [
              GenderAvatar(
                name: child.name,
                isBoy: child.isBoy,
                photoPath: child.photoPath,
                size: 62,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.name,
                      style: AppTheme.serif(size: 21, weight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _MiniTag(
                          label: child.ageLabel,
                          color: AppColors.goldDeep,
                          background: AppColors.goldMist,
                        ),
                        const SizedBox(width: 8),
                        _MiniTag(
                          label: child.gender.label,
                          color: AppColors.forGenderDeep(child.isBoy),
                          background: AppColors.forGenderSoft(child.isBoy),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 1,
            color: AppColors.goldSoft.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 18),
          if (latest == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  Text(
                    'Belum ada pengukuran',
                    style: AppTheme.sans(size: 14, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tekan tombol + di bawah untuk mencatat\npengukuran pertama ${child.name}.',
                    textAlign: TextAlign.center,
                    style: AppTheme.sans(
                      size: 12.5,
                      color: AppColors.inkSoft,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _HeroStat(
                    label: 'Berat',
                    value: Format.kg(latest.weight),
                    delta: _delta(latest.weight, prevWeight?.weight, 'kg'),
                  ),
                ),
                _VDivider(),
                Expanded(
                  child: _HeroStat(
                    label: 'Tinggi',
                    value: Format.cm(latest.height),
                    delta: _delta(latest.height, prevHeight?.height, 'cm'),
                  ),
                ),
                _VDivider(),
                Expanded(
                  child: _HeroStat(
                    label: 'IMT',
                    value: latest.bmi == null
                        ? '—'
                        : latest.bmi!.toStringAsFixed(1).replaceAll('.', ','),
                    delta: Format.date(latest.date),
                  ),
                ),
              ],
            ),
          if (analysis != null && analysis!.results.isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final r in analysis!.results.take(3))
                  ZBadge(
                    label:
                        '${r.indicator.shortLabel}: ${r.classification.label}',
                    color: r.classification.color,
                    icon: r.classification.icon,
                    dense: true,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Measurement? _previousWith(
    List<Measurement> list,
    double? Function(Measurement) pick,
  ) {
    final withValue = list.where((m) => pick(m) != null).toList();
    if (withValue.length < 2) return null;
    return withValue[withValue.length - 2];
  }

  String _delta(double? current, double? previous, String unit) {
    if (current == null || previous == null) return 'pengukuran terbaru';
    final diff = current - previous;
    if (diff.abs() < 0.001) return 'stabil';
    final sign = diff > 0 ? '+' : '-';
    return '$sign${diff.abs().toStringAsFixed(1).replaceAll('.', ',')} $unit';
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.delta,
  });

  final String label;
  final String value;
  final String delta;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTheme.sans(
            size: 10,
            weight: FontWeight.w800,
            color: AppColors.inkFaint,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(value, style: AppTheme.serif(size: 19, weight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          delta,
          style: AppTheme.sans(
            size: 10.5,
            weight: FontWeight.w600,
            color: AppColors.inkSoft,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.goldSoft.withValues(alpha: 0.7),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTheme.sans(size: 10.5, weight: FontWeight.w700, color: color),
      ),
    );
  }
}

// ── Kartu status gizi ────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.analysis});

  final MeasurementAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final headline = analysis.headline;
    if (headline == null) return const SizedBox.shrink();

    return LuxeCard(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const InsightsScreen())),
      child: Row(
        children: [
          IconTile(
            icon: headline.icon,
            color: headline.color,
            size: 52,
            iconSize: 26,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Gizi (${analysis.standardUsed.shortLabel})',
                  style: AppTheme.sans(
                    size: 11,
                    weight: FontWeight.w700,
                    color: AppColors.inkFaint,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  headline.label,
                  style: AppTheme.serif(
                    size: 18.5,
                    weight: FontWeight.w600,
                    color: headline.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  headline.description,
                  style: AppTheme.sans(
                    size: 12,
                    color: AppColors.inkSoft,
                    height: 1.45,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
        ],
      ),
    );
  }
}

// ── Kartu tren mini ──────────────────────────────────────────────────────────

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.measurements, required this.isBoy});

  final List<Measurement> measurements;
  final bool isBoy;

  @override
  Widget build(BuildContext context) {
    final points = measurements
        .where((m) => m.weight != null)
        .toList()
        .reversed
        .take(8)
        .toList()
        .reversed
        .toList();

    return LuxeCard(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const GrowthChartsScreen())),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tren Berat Badan',
                  style: AppTheme.serif(size: 17, weight: FontWeight.w600),
                ),
              ),
              Text(
                '${points.length} pengukuran',
                style: AppTheme.sans(
                  size: 11.5,
                  weight: FontWeight.w600,
                  color: AppColors.inkFaint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 88,
            width: double.infinity,
            child: CustomPaint(
              painter: _SparklinePainter(
                values: [for (final m in points) m.weight!],
                color: AppColors.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.001 ? 1.0 : maxV - minV;

    Offset pointAt(int i) {
      final x = size.width * i / (values.length - 1);
      final y =
          size.height - 8 - ((values[i] - minV) / range) * (size.height - 20);
      return Offset(x, y);
    }

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < values.length; i++) {
      final prev = pointAt(i - 1);
      final curr = pointAt(i);
      final midX = (prev.dx + curr.dx) / 2;
      path.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
    }

    // Isian lembut di bawah garis.
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.0)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Titik terakhir menonjol.
    final last = pointAt(values.length - 1);
    canvas.drawCircle(last, 7, Paint()..color = AppColors.goldSoft);
    canvas.drawCircle(last, 4.2, Paint()..color = AppColors.goldDeep);
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.values != values;
}

// ── Aksi cepat ───────────────────────────────────────────────────────────────

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider);

    final actions = [
      (
        Icons.straighten_rounded,
        'Ukur\nSekarang',
        AppColors.gold,
        () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddMeasurementScreen(),
              fullscreenDialog: true,
            ),
          );
        },
      ),
      (
        Icons.insights_rounded,
        'Grafik\nPertumbuhan',
        AppColors.boy,
        () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const GrowthChartsScreen()));
        },
      ),
      (
        Icons.favorite_rounded,
        'Insight &\nPrediksi',
        AppColors.girl,
        () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const InsightsScreen()));
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Aksi Cepat'),
        Row(
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: actions[i].$1,
                  label: actions[i].$2,
                  color: actions[i].$3,
                  onTap: child == null ? null : actions[i].$4,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return LuxeCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: Column(
        children: [
          IconTile(icon: icon, color: color),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.sans(
              size: 11.5,
              weight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
