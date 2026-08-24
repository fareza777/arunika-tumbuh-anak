# Arunika — Tumbuh Kembang Anak

Aplikasi Android premium (Flutter) untuk memantau tinggi & berat badan anak,
dengan standar rujukan resmi dan klasifikasi sesuai aturan Indonesia.

**Arunika** (bahasa Sanskerta/Jawa: *cahaya matahari pagi*) — setiap
pengukuran adalah cahaya kecil yang menuntun tumbuh kembang anak.

## Fitur

- **Multi-profil anak** dengan foto, jenis kelamin, data lahir, dan tinggi orang tua.
- **Grafik pertumbuhan interaktif** (pinch-zoom & geser) dengan pita zona ala KMS:
  - WHO Child Growth Standards 2006 (0-5 tahun)
  - WHO Growth Reference 2007 (5-19 tahun)
  - CDC Growth Charts 2000 (2-20 tahun)
  - Mode otomatis yang memilih standar terbaik sesuai usia.
- **Z-score & persentil** dihitung dengan rumus LMS resmi, termasuk koreksi
  ekor WHO untuk nilai ekstrem (|z| > 3).
- **Klasifikasi status gizi** sesuai Permenkes RI No. 2 Tahun 2020
  (BB/U, TB/U, BB/TB, IMT/U, LK/U, LILA) lengkap dengan saran untuk orang tua.
- **Insight & prediksi**: kecepatan tumbuh (velocity), estimasi tinggi dewasa
  (jalur tumbuh + target genetik dari tinggi orang tua).
- **Milestone perkembangan** (52 item, 4 kategori) dengan penanda keterlambatan.
- **Jadwal imunisasi** program nasional Kemenkes + rekomendasi tambahan IDAI.
- **Laporan PDF premium** — kurva digambar sebagai vektor, siap dibawa ke dokter.
- **Pengingat pengukuran** via notifikasi lokal (mingguan / 2-mingguan / bulanan).
- **Offline-first & privat** — data inti tersimpan lokal (SQLite), tanpa server Arunika.
  Versi gratis memakai Google AdMob untuk iklan; pembelian satu kali melalui Google
  Play Billing tersedia untuk menghapus iklan.

## Sumber data resmi

Tabel LMS asli (bukan aproksimasi) dibundel sebagai aset JSON di
`assets/standards/`, dihasilkan oleh pipeline di `tool/standards/` dari berkas
resmi WHO (who.int) dan CDC (cdc.gov), dengan 23 pemeriksaan verifikasi nilai.

## Menjalankan & mem-build

Prasyarat: Flutter SDK 3.44+ dan Android SDK (via Android Studio).

```powershell
flutter pub get
flutter analyze        # harus: No issues found!
flutter test           # 21 unit test mesin z-score & klasifikasi
flutter run            # mode debug di perangkat/emulator
flutter build apk --release        # APK release
flutter build appbundle --release  # AAB untuk Play Store
```

Untuk build release dengan ID iklan produksi, gunakan file lokal yang tidak
di-commit:

```powershell
flutter build appbundle --release `
  --dart-define-from-file=tool/release/monetization.json
```

Format file tersebut:

```json
{
  "ADMOB_APP_ID": "ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy",
  "ADMOB_BANNER_ID": "ca-app-pub-xxxxxxxxxxxxxxxx/aaaaaaaaaa",
  "ADMOB_INTERSTITIAL_ID": "ca-app-pub-xxxxxxxxxxxxxxxx/bbbbbbbbbb"
}
```

Kebijakan privasi publik ada di [docs/privacy-policy.html](docs/privacy-policy.html) dan tersedia langsung di [URL publik](https://raw.githubusercontent.com/fareza777/arunika-tumbuh-anak/main/docs/privacy-policy.html).

Ikon launcher dibuat ulang bila perlu dengan:

```powershell
dart run flutter_launcher_icons
```

## Struktur kode

```
lib/
  core/        tema light-luxury, widget desain, util format Indonesia
  data/        model, SQLite (sqflite), repositori
  domain/      mesin LMS, resolusi standar, klasifikasi Permenkes,
               insight (velocity & prediksi), konten milestone/imunisasi,
               notifikasi, generator PDF
  state/       Riverpod providers & pengaturan persisten
  ui/          splash, onboarding, home, grafik, riwayat, insight,
               milestone, imunisasi, laporan, pengaturan
```

## Penafian

Aplikasi ini alat bantu pemantauan, bukan pengganti diagnosis tenaga
kesehatan. Selalu konsultasikan kondisi anak ke dokter/bidan.
