/// Util format tanggal & angka berbahasa Indonesia.
library;

const List<String> _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

const List<String> _monthNamesFull = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

const List<String> _dayNames = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

class Format {
  Format._();

  /// "12 Jan 2026"
  static String date(DateTime d) =>
      '${d.day} ${_monthNames[d.month - 1]} ${d.year}';

  /// "12 Januari 2026"
  static String dateFull(DateTime d) =>
      '${d.day} ${_monthNamesFull[d.month - 1]} ${d.year}';

  /// "Senin, 12 Jan 2026"
  static String dateWithDay(DateTime d) =>
      '${_dayNames[d.weekday - 1]}, ${date(d)}';

  /// "Januari 2026"
  static String monthYear(DateTime d) =>
      '${_monthNamesFull[d.month - 1]} ${d.year}';

  /// "9,7 kg"
  static String kg(double? v, {int decimals = 1}) =>
      v == null ? '—' : '${_fixed(v, decimals)} kg';

  /// "75,5 cm"
  static String cm(double? v, {int decimals = 1}) =>
      v == null ? '—' : '${_fixed(v, decimals)} cm';

  /// "+0,79 SD" / "-1,24 SD"
  static String z(double? v) {
    if (v == null) return '—';
    final sign = v >= 0 ? '+' : '';
    return '$sign${_fixed(v, 2)} SD';
  }

  /// "P58" (persentil ke-58)
  static String percentile(double? v) =>
      v == null ? '—' : 'P${v.toStringAsFixed(0)}';

  /// Angka desimal dengan koma tanpa satuan: "9,7".
  static String decimal(double v, {int decimals = 1}) => _fixed(v, decimals);

  /// Angka desimal dengan koma (gaya Indonesia).
  static String _fixed(double v, int decimals) =>
      v.toStringAsFixed(decimals).replaceAll('.', ',');

  /// Umur dalam bulan → label sumbu grafik: "9 bln", "2 th".
  static String axisMonths(double months) {
    if (months < 24) return '${months.round()}';
    final years = months / 12;
    return years == years.roundToDouble()
        ? '${years.round()} th'
        : years.toStringAsFixed(1).replaceAll('.', ',');
  }

  /// Umur (bulan desimal) → "2 th 3 bln".
  static String ageFromMonths(double months) {
    final total = months.floor();
    if (total < 24) return '$total bln';
    final y = total ~/ 12;
    final m = total % 12;
    return m == 0 ? '$y th' : '$y th $m bln';
  }
}
