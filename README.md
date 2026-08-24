# Arunika: Tumbuh Bersama

Arunika adalah ruang privat offline-first untuk keluarga yang ingin merayakan
ritual kecil, menyimpan momen hangat, dan melihat cerita kebersamaan tumbuh
dari hari ke hari.

Arunika tidak meminta akun, tidak memerlukan koneksi untuk catatan inti, dan
tidak mengubah cerita keluarga menjadi target atau penilaian. Data inti
tersimpan lokal di perangkat; pengguna memilih sendiri ketika ingin berbagi
atau mengekspor scrapbook.

## Fitur utama

- **Hari Ini** — sapaan sunrise, progres ritual, recap mingguan, dan momen
  terbaru dalam satu halaman bento yang tenang.
- **Ritual** — buat kebiasaan berulang dengan hari, waktu, dan nuansa pilihan;
  rayakan dengan satu ketukan tanpa streak yang menghakimi.
- **Momen** — simpan judul, satu cerita, tag suasana, anggota yang hadir, dan
  foto opsional dari galeri perangkat.
- **Taman** — visualisasi constellation sederhana yang menghubungkan orang,
  ritual, dan momen yang sudah dirayakan.
- **Scrapbook PDF** — ekspor kenangan dan ritual menjadi dokumen yang bisa
  dibagikan atau dicetak ketika keluarga menginginkannya.
- **Privasi lokal** — tidak ada server Arunika untuk menyimpan catatan keluarga;
  foto hanya dipakai ketika pengguna memilihnya.
- **Bebas Iklan** — versi gratis memakai banner AdMob yang stabil di area jelajah;
  satu pembelian US$4.99 menghapus iklan dan dapat dipulihkan melalui Google Play.

## Teknologi

Flutter, Riverpod, SQLite/sqflite, Phosphor Icons, Fraunces, Plus Jakarta Sans,
image_picker, pdf/printing, Google Mobile Ads, dan Google Play Billing.

## Menjalankan & mem-build

Prasyarat: Flutter SDK 3.44+ dan Android SDK.

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
flutter build appbundle --release
```

Untuk build release dengan ID AdMob produksi gunakan file lokal yang tidak
di-commit:

```powershell
flutter build appbundle --release `
  --dart-define-from-file=tool/release/monetization.json
```

Kebijakan privasi publik: [docs/privacy-policy.html](docs/privacy-policy.html)
dan [URL publik](https://raw.githubusercontent.com/fareza777/arunika-tumbuh-anak/main/docs/privacy-policy.html).

## Struktur kode aktif

```text
lib/
  core/      tema Editorial Sunrise dan widget desain reusable
  data/      model SQLite untuk keluarga, ritual, check-in, dan momen
  domain/    recap lokal, scrapbook PDF, monetisasi, dan layanan inti
  state/     Riverpod providers, preferensi lokal, dan aksi produk
  ui/        splash, onboarding, Hari Ini, Ritual, Momen, Taman, settings
```

Kode legacy pengukuran tetap berada di repository untuk migrasi data perangkat
lama, tetapi tidak lagi dijangkau dari shell dan onboarding produk aktif.

## Catatan rilis

- Package ID tetap `id.arunika.arunika_growth` agar pembaruan aplikasi lama
  tetap dapat dipasang.
- Store positioning: **Lifestyle / Family Journal**, bukan aplikasi kesehatan.
- Banner hanya berada di browse shell dengan slot tinggi yang dicadangkan;
  compose momen dan ritual bebas iklan.
