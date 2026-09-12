import '../../data/models/moment.dart';
import '../../data/models/ritual.dart';
import '../../data/models/ritual_check_in.dart';

class WeekDayMark {
  const WeekDayMark({required this.date, required this.active});

  final DateTime date;
  final bool active;

  String get shortLabel {
    const labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return labels[date.weekday - 1];
  }
}

class WeeklyRecap {
  const WeeklyRecap({
    required this.momentCount,
    required this.ritualCount,
    required this.topTag,
    required this.activeDays,
    required this.week,
    required this.cards,
  });

  final int momentCount;
  final int ritualCount;
  final MomentTag? topTag;
  final int activeDays;
  final List<WeekDayMark> week;
  final List<RecapCardData> cards;
}

class RecapCardData {
  const RecapCardData({
    required this.eyebrow,
    required this.title,
    required this.detail,
  });

  final String eyebrow;
  final String title;
  final String detail;
}

class RecapService {
  const RecapService._();

  static WeeklyRecap build({
    required List<Moment> moments,
    required List<RitualCheckIn> checkIns,
    required List<Ritual> rituals,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    final start = today.subtract(const Duration(days: 6));
    final recentMoments = moments
        .where(
          (moment) =>
              !_before(moment.capturedAt, start) &&
              !_dateOnly(moment.capturedAt).isAfter(today),
        )
        .toList();
    final recentCheckIns = checkIns
        .where((checkIn) => _keyInRange(checkIn.dayKey, start, today))
        .toList();

    final tagCounts = <MomentTag, int>{};
    for (final moment in recentMoments) {
      tagCounts[moment.tag] = (tagCounts[moment.tag] ?? 0) + 1;
    }
    MomentTag? topTag;
    if (tagCounts.isNotEmpty) {
      topTag = tagCounts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    }

    final activeKeys = <String>{
      ...recentMoments.map((moment) => ritualDayKey(moment.capturedAt)),
      ...recentCheckIns.map((checkIn) => checkIn.dayKey),
    };
    final week = <WeekDayMark>[
      for (var i = 6; i >= 0; i--)
        WeekDayMark(
          date: today.subtract(Duration(days: i)),
          active: activeKeys.contains(
            ritualDayKey(today.subtract(Duration(days: i))),
          ),
        ),
    ];

    final cards = <RecapCardData>[
      RecapCardData(
        eyebrow: 'MOMEN',
        title: recentMoments.isEmpty
            ? 'Ada ruang untuk cerita baru'
            : '${recentMoments.length} cerita kecil jadi kenangan',
        detail: recentMoments.isEmpty
            ? 'Satu kalimat pun cukup untuk memulai.'
            : 'Yang sederhana sering paling ingin kita ingat.',
      ),
      RecapCardData(
        eyebrow: 'KEBIASAAN',
        title: recentCheckIns.isEmpty
            ? 'Kebiasaan pertama menunggu'
            : '${recentCheckIns.length} kali memilih hadir',
        detail: rituals.isEmpty
            ? 'Buat satu kebiasaan kecil yang terasa milik kalian.'
            : 'Konsistensi tidak harus ramai untuk terasa berarti.',
      ),
    ];
    if (topTag != null) {
      cards.add(
        RecapCardData(
          eyebrow: 'BENANG MERAH',
          title: 'Tema minggu ini: ${topTag.label.toLowerCase()}',
          detail: 'Biarkan pola hangat ini menemani minggu berikutnya.',
        ),
      );
    }

    return WeeklyRecap(
      momentCount: recentMoments.length,
      ritualCount: recentCheckIns.length,
      topTag: topTag,
      activeDays: activeKeys.length,
      week: week,
      cards: cards,
    );
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool _before(DateTime value, DateTime start) =>
      _dateOnly(value).isBefore(start);

  static bool _keyInRange(String key, DateTime start, DateTime end) {
    final parsed = DateTime.tryParse(key);
    if (parsed == null) return false;
    final date = _dateOnly(parsed);
    return !date.isBefore(start) && !date.isAfter(end);
  }
}
