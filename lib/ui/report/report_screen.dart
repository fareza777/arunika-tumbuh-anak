import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/gold_button.dart';
import '../../core/widgets/luxe_card.dart';
import '../../core/widgets/section_header.dart';
import '../../domain/report/pdf_report.dart';
import '../../state/app_settings.dart';
import '../../state/providers.dart';

/// Ekspor laporan PDF premium untuk dibawa ke dokter / disimpan.
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  bool _includeCharts = true;
  bool _includeHistory = true;
  bool _generating = false;

  Future<Uint8List> _buildPdf() async {
    final child = ref.read(selectedChildProvider)!;
    final measurements = ref.read(measurementsProvider).valueOrNull ?? const [];
    final analysis = ref.read(latestAnalysisProvider);
    final standard = ref.read(settingsProvider).standard;
    final standards = await ref.read(standardsProvider.future);

    return PdfReportBuilder(standards: standards).build(
      child: child,
      measurements: measurements,
      latestAnalysis: analysis,
      standard: standard,
      includeCharts: _includeCharts,
      includeHistory: _includeHistory,
    );
  }

  Future<void> _run(
    Future<void> Function(Uint8List bytes, String filename) action,
  ) async {
    setState(() => _generating = true);
    try {
      final bytes = await _buildPdf();
      final child = ref.read(selectedChildProvider)!;
      final safeName = child.name.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
      await action(bytes, 'Arunika_Laporan_$safeName.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(selectedChildProvider);
    final measurements =
        ref.watch(measurementsProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan PDF')),
      body: child == null
          ? const EmptyState(
              icon: Icons.picture_as_pdf_rounded,
              title: 'Belum Ada Anak Terpilih',
              message:
                  'Tambahkan profil anak untuk membuat laporan tumbuh kembang.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                // ── Kartu pratinjau ──────────────────────────────────────
                LuxeCard(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFFFFF), Color(0xFFFBF4E2)],
                  ),
                  borderColor: AppColors.goldSoft,
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.description_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Laporan ${child.name.split(' ').first}',
                              style: AppTheme.serif(
                                size: 17,
                                weight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${measurements.length} pengukuran tercatat • siap diekspor',
                              style: AppTheme.sans(
                                size: 11.5,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ── Opsi isi ─────────────────────────────────────────────
                const SectionHeader(title: 'Isi Laporan'),
                LuxeCard(
                  child: Column(
                    children: [
                      _OptionRow(
                        icon: Icons.show_chart_rounded,
                        title: 'Kurva Pertumbuhan',
                        subtitle: 'BB/U, TB/U, IMT/U dengan pita standar',
                        value: _includeCharts,
                        onChanged: (v) => setState(() => _includeCharts = v),
                      ),
                      const Divider(height: 24),
                      _OptionRow(
                        icon: Icons.table_rows_rounded,
                        title: 'Riwayat Lengkap',
                        subtitle: 'Tabel seluruh pengukuran',
                        value: _includeHistory,
                        onChanged: (v) => setState(() => _includeHistory = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SoftCard(
                  color: AppColors.goldMist,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppColors.goldDeep,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Laporan memuat identitas anak, ringkasan z-score & status gizi terakhir, '
                          'serta bagian yang Anda pilih di atas. Grafik digambar sebagai vektor agar tajam saat dicetak.',
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
                const SizedBox(height: 26),

                // ── Aksi ─────────────────────────────────────────────────
                GoldButton(
                  label: 'Pratinjau PDF',
                  icon: Icons.visibility_rounded,
                  isLoading: _generating,
                  onPressed: _generating
                      ? null
                      : () => _run(
                          (bytes, filename) => Printing.layoutPdf(
                            onLayout: (_) async => bytes,
                            name: filename,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                GoldButton(
                  label: 'Bagikan / Simpan PDF',
                  icon: Icons.share_rounded,
                  outlined: true,
                  onPressed: _generating
                      ? null
                      : () => _run(
                          (bytes, filename) => Printing.sharePdf(
                            bytes: bytes,
                            filename: filename,
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconTile(icon: icon, color: AppColors.gold, size: 42, iconSize: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.sans(size: 13.5, weight: FontWeight.w800),
              ),
              Text(
                subtitle,
                style: AppTheme.sans(size: 11, color: AppColors.inkFaint),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
