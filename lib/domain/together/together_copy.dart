const togetherAppName = 'Arunika';
const togetherProductName = 'Tumbuh Bersama';

String greetingFor(DateTime now) {
  final hour = now.hour;
  if (hour < 11) return 'Selamat pagi';
  if (hour < 16) return 'Selamat siang';
  if (hour < 19) return 'Selamat sore';
  return 'Selamat malam';
}

String ritualCountCopy(int done, int total) {
  if (total == 0) return 'Belum ada ritual hari ini';
  if (done == total) return 'Semua ritual hari ini dirayakan';
  return '$done dari $total ritual sudah dirayakan';
}

String momentCountCopy(int count) {
  if (count == 0) return 'Belum ada catatan hangat minggu ini';
  if (count == 1) return '1 momen hangat tersimpan';
  return '$count momen hangat tersimpan';
}
