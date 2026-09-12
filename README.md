# Arunika: Tumbuh Bersama

Jurnal keluarga berbahasa Indonesia untuk menyimpan cerita, merawat kebiasaan kecil, dan membaca kembali waktu bersama. Produk aktif ditujukan kepada orang dewasa, orang tua, wali, dan pengasuh.

Versi **1.4.1+9** memperbarui seluruh alur aktif: pembuka, pengaturan awal, empat menu, seluruh formulir, detail cerita, pengaturan, privasi, bantuan, dan pembelian Bebas Iklan.

## Alur sehari-hari

1. **Hari ini:** lihat kebiasaan yang dijadwalkan, tandai selesai, dan gunakan pertanyaan harian untuk mulai menulis.
2. **Kebiasaan:** atur hari dan waktu, lihat semua kebiasaan, serta arsipkan atau pulihkan tanpa kehilangan riwayat.
3. **Momen:** simpan judul, cerita, suasana, anggota, tanggal, dan foto pilihan. Cari isi cerita dan buka detail untuk mengedit, berbagi, atau menghapus.
4. **Keluarga:** kelola anggota dan baca ringkasan tujuh hari terakhir.
5. **Pengaturan:** pengingat harian opsional, mode gelap, pengurangan animasi, cadangan lengkap beserta foto, pemulihan, dan scrapbook PDF.

Catatan inti bekerja tanpa internet dan tanpa akun. Foto pilihan disalin ke penyimpanan privat aplikasi. Data tidak disinkronkan otomatis antarperangkat; cadangan manual membantu pindah ponsel. Berkas cadangan tidak dienkripsi, sehingga pengguna perlu memilih tempat penyimpanan yang sesuai.

Semua tab dan fitur inti gratis. Banner ada di area jelajah; interstitial terbatas setelah penyimpanan berhasil dan kembali ke jelajah (minimal tiga penyimpanan, cooldown sepuluh menit). Formulir bebas iklan. Rewarded dinonaktifkan untuk versi ini sesuai keputusan pemilik produk. Harga pembelian Bebas Iklan berasal dari Google Play dan dapat dipulihkan dengan akun pembelian yang sama. AdMob dapat memproses data perangkat dan interaksi iklan; klaim lokal berlaku untuk isi jurnal, bukan seluruh aktivitas SDK.

## Pengembangan

Flutter **3.44.6**, Dart **3.12.2**, JDK 21, Android SDK 36. Paket Android tetap `id.arunika.arunika_growth` agar pembaruan mempertahankan identitas aplikasi.

```powershell
flutter pub get
flutter analyze
flutter test --concurrency=2
flutter run
```

Release memerlukan kunci upload asli melalui `android/key.properties` dan konfigurasi monetisasi lokal (`ADMOB_APP_ID`, `ADMOB_BANNER_ID`, `ADMOB_INTERSTITIAL_ID`). Berkas tersebut diabaikan Git; jangan memasukkan rahasianya ke repo. Release tanpa signing yang valid ditolak, bukan ditandatangani dengan kunci debug.

```powershell
flutter build apk --release --dart-define-from-file=tool/release/monetization.json
flutter build appbundle --release --dart-define-from-file=tool/release/monetization.json
```

Build menghasilkan APK untuk pemasangan lokal dan AAB untuk Play Console. Membuat build tidak memublikasikan aplikasi.

## Pemeriksaan mutu

- Uji SQLite asli: pembaruan kebiasaan mempertahankan check-in, sejarah lengkap, serta migrasi tabel lama.
- Uji berkas: foto tersimpan permanen, pembersihan foto aman, validasi dan pemulihan cadangan atomik, serta scrapbook dengan catatan panjang.
- Uji interaksi: validasi formulir, kegagalan simpan dan coba lagi, perlindungan isian, navigasi, pencarian, jadwal, dan arsip.
- Uji tampilan: 320 × 640 dan 390 × 844, tema terang/gelap, ukuran teks 1×/2× menggunakan font aplikasi sebenarnya.
- CI menjalankan analisis dan tes; bukti dan batas pengujian rilis ada di [laporan audit](docs/qa/2026-09-05/audit-release.md).

## Struktur

- `lib/ui/`: halaman dan komponen aktif.
- `lib/state/`: preferensi, provider dan aksi yang menghubungkan UI ke data.
- `lib/data/`: model dan SQLite; perubahan induk mempertahankan relasi.
- `lib/domain/together/`: ringkasan, media, cadangan, dan PDF.
- `lib/domain/notifications/` dan `lib/domain/monetization/`: integrasi Android.

Kode pengukuran lama dipertahankan untuk kompatibilitas data, tetapi tidak dijangkau dari navigasi produk aktif. Screenshot dan promosi lama tidak mewakili versi 1.4.1.

## Materi rilis

[Deskripsi toko](store/aso.md), [kebijakan privasi](docs/privacy-policy.html), [aset terbaru](store/assets/README.md), dan [audit rilis](docs/qa/2026-09-05/audit-release.md).

Kebijakan privasi publik: https://fareza777.github.io/arunika-tumbuh-anak/privacy-policy.html. Gunakan URL GitHub Pages ini di Play Console; URL raw GitHub hanya menyajikan kode HTML sebagai teks.
