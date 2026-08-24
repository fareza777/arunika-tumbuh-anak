import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'growth_standards.dart';
import 'lms_table.dart';

/// Memuat dan menyediakan tabel LMS resmi:
/// WHO 2006 (0-5 th), WHO 2007 (5-19 th), dan CDC 2000 (0-20 th).
///
/// Data bersumber dari berkas resmi who.int dan cdc.gov
/// (lihat tool/standards untuk pipeline konversinya).
class StandardsRepository {
  StandardsRepository._();

  static final StandardsRepository instance = StandardsRepository._();

  final Map<String, Map<String, LmsTable>> _who2006 = {};
  final Map<String, Map<String, LmsTable>> _who2007 = {};
  final Map<String, Map<String, LmsTable>> _cdc2000 = {};

  bool _loaded = false;
  Future<void>? _loading;

  Future<void> ensureLoaded() {
    if (_loaded) return Future.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    Future<void> readInto(
      String asset,
      Map<String, Map<String, LmsTable>> target,
    ) async {
      final raw = await rootBundle.loadString(asset);
      final decoded = json.decode(raw) as Map<String, dynamic>;
      decoded.forEach((tableKey, sexes) {
        final sexMap = <String, LmsTable>{};
        (sexes as Map<String, dynamic>).forEach((sex, cols) {
          sexMap[sex] = LmsTable.fromJson(cols as Map<String, dynamic>);
        });
        target[tableKey] = sexMap;
      });
    }

    await readInto('assets/standards/who2006.json', _who2006);
    await readInto('assets/standards/who2007.json', _who2007);
    await readInto('assets/standards/cdc2000.json', _cdc2000);
    _loaded = true;
  }

  LmsTable? _lookup(
    Map<String, Map<String, LmsTable>> source,
    String tableKey,
    bool isBoy,
  ) {
    final sexMap = source[tableKey];
    if (sexMap == null) return null;
    return sexMap[isBoy ? 'boys' : 'girls'];
  }

  /// Memilih tabel LMS yang tepat untuk kombinasi standar, indikator,
  /// jenis kelamin, dan umur anak. Mengembalikan null bila indikator
  /// tidak tersedia untuk standar/umur tersebut.
  LmsTable? tableFor({
    required GrowthStandard standard,
    required GrowthIndicator indicator,
    required bool isBoy,
    double? ageMonths,
  }) {
    switch (standard) {
      case GrowthStandard.whoAuto:
        // Balita → WHO 2006; di atas 5 tahun → WHO 2007.
        final age = ageMonths ?? 0;
        final chosen = age <= 60.5
            ? GrowthStandard.who2006
            : GrowthStandard.who2007;
        return tableFor(
          standard: chosen,
          indicator: indicator,
          isBoy: isBoy,
          ageMonths: ageMonths,
        );

      case GrowthStandard.who2006:
        switch (indicator) {
          case GrowthIndicator.wfa:
            return _lookup(_who2006, 'wfa', isBoy);
          case GrowthIndicator.lhfa:
            return _lookup(_who2006, 'lhfa', isBoy);
          case GrowthIndicator.bfa:
            return _lookup(_who2006, 'bfa', isBoy);
          case GrowthIndicator.hcfa:
            return _lookup(_who2006, 'hcfa', isBoy);
          case GrowthIndicator.wflh:
            // WHO: BB/PB untuk < 2 tahun, BB/TB untuk >= 2 tahun.
            final useWfl = (ageMonths ?? 0) < 24;
            return _lookup(_who2006, useWfl ? 'wfl' : 'wfh', isBoy);
        }

      case GrowthStandard.who2007:
        switch (indicator) {
          case GrowthIndicator.bfa:
            return _lookup(_who2007, 'bfa', isBoy);
          case GrowthIndicator.lhfa:
            return _lookup(_who2007, 'hfa', isBoy);
          case GrowthIndicator.wfa:
            return _lookup(_who2007, 'wfa', isBoy); // hanya 61-120 bulan
          case GrowthIndicator.wflh:
          case GrowthIndicator.hcfa:
            return null; // tidak tersedia pada rujukan 5-19 tahun
        }

      case GrowthStandard.cdc2000:
        final infant = (ageMonths ?? 0) < 24;
        switch (indicator) {
          case GrowthIndicator.wfa:
            return _lookup(_cdc2000, infant ? 'wtageinf' : 'wtage', isBoy);
          case GrowthIndicator.lhfa:
            return _lookup(_cdc2000, infant ? 'lenageinf' : 'statage', isBoy);
          case GrowthIndicator.wflh:
            return _lookup(_cdc2000, infant ? 'wtleninf' : 'wtstat', isBoy);
          case GrowthIndicator.bfa:
            // CDC BMI-for-age resmi mulai usia 2 tahun.
            if ((ageMonths ?? 24) < 24) return null;
            return _lookup(_cdc2000, 'bmiage', isBoy);
          case GrowthIndicator.hcfa:
            if (!infant && (ageMonths ?? 0) > 36.5) return null;
            return _lookup(_cdc2000, 'hcageinf', isBoy);
        }
    }
  }

  /// Daftar indikator yang tersedia untuk standar + umur tertentu.
  List<GrowthIndicator> availableIndicators({
    required GrowthStandard standard,
    required bool isBoy,
    required double ageMonths,
  }) {
    return GrowthIndicator.values
        .where(
          (ind) =>
              tableFor(
                standard: standard,
                indicator: ind,
                isBoy: isBoy,
                ageMonths: ageMonths,
              ) !=
              null,
        )
        .toList();
  }

  /// Standar efektif yang dipakai bila pengguna memilih mode otomatis.
  GrowthStandard resolveEffective(GrowthStandard standard, double ageMonths) {
    if (standard != GrowthStandard.whoAuto) return standard;
    return ageMonths <= 60.5 ? GrowthStandard.who2006 : GrowthStandard.who2007;
  }
}
