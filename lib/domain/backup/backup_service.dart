import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/repo/child_repository.dart';
import '../../data/repo/measurement_repository.dart';
import '../../data/repo/nutrition_repository.dart';
import '../../data/repo/progress_repository.dart';

/// Ringkasan hasil impor cadangan.
class ImportSummary {
  const ImportSummary({
    required this.childrenAdded,
    required this.measurementsAdded,
    required this.progressAdded,
  });

  final int childrenAdded;
  final int measurementsAdded;
  final int progressAdded;

  int get totalAdded => childrenAdded + measurementsAdded + progressAdded;
}

/// Cadangan & pemulihan seluruh data aplikasi dalam satu berkas JSON.
class BackupService {
  BackupService({
    ChildRepository? children,
    MeasurementRepository? measurements,
    ProgressRepository? progress,
    NutritionRepository? nutrition,
  }) : _children = children ?? ChildRepository(),
       _measurements = measurements ?? MeasurementRepository(),
       _progress = progress ?? ProgressRepository(),
       _nutrition = nutrition ?? NutritionRepository();

  final ChildRepository _children;
  final MeasurementRepository _measurements;
  final ProgressRepository _progress;
  final NutritionRepository _nutrition;

  static const _formatVersion = 1;

  /// Menulis seluruh data ke berkas JSON di direktori sementara.
  /// Mengembalikan berkas untuk dibagikan/disimpan pengguna.
  Future<File> exportToFile() async {
    final payload = <String, Object?>{
      'app': 'id.arunika.arunika_growth',
      'format': _formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'children': await _children.getAllRaw(),
      'measurements': await _measurements.getAllRaw(),
      'milestoneStatus': await _progress.getAllMilestoneRaw(),
      'immunizationStatus': await _progress.getAllImmunizationRaw(),
      'nutritionLog': await _nutrition.getAllRaw(),
    };

    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('-', '')
        .split('.')
        .first;
    final file = File(p.join(dir.path, 'arunika_cadangan_$stamp.json'));
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(payload));
    return file;
  }

  /// Mengimpor berkas cadangan. Data dengan ID yang sudah ada dilewati
  /// (mode gabung, aman dijalankan berulang kali).
  Future<ImportSummary> importFromFile(String path) async {
    final raw = await File(path).readAsString();
    final decoded = json.decode(raw);
    if (decoded is! Map<String, dynamic> ||
        decoded['app'] != 'id.arunika.arunika_growth') {
      throw const FormatException('Berkas bukan cadangan Arunika yang valid.');
    }

    List<Map<String, Object?>> rows(String key) {
      final list = decoded[key];
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((e) => Map<String, Object?>.from(e))
          .toList();
    }

    var childrenAdded = 0;
    for (final row in rows('children')) {
      if (await _children.insertRawIfNew(row)) childrenAdded++;
    }
    var measurementsAdded = 0;
    for (final row in rows('measurements')) {
      if (await _measurements.insertRawIfNew(row)) measurementsAdded++;
    }
    var progressAdded = 0;
    for (final row in rows('milestoneStatus')) {
      if (await _progress.insertMilestoneRawIfNew(row)) progressAdded++;
    }
    for (final row in rows('immunizationStatus')) {
      if (await _progress.insertImmunizationRawIfNew(row)) progressAdded++;
    }
    for (final row in rows('nutritionLog')) {
      if (await _nutrition.insertRawIfNew(row)) progressAdded++;
    }

    return ImportSummary(
      childrenAdded: childrenAdded,
      measurementsAdded: measurementsAdded,
      progressAdded: progressAdded,
    );
  }
}
