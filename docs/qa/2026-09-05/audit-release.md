# Arunika 1.4 — audit dan kesiapan rilis

Tanggal: 5 September 2026. Baseline: `459a33e` (1.3.3+7). Paket tetap `id.arunika.arunika_growth`. Audit mencakup semua halaman yang bisa dijangkau dari navigasi produk aktif; tabel dan kode pengukuran lama dipertahankan untuk kompatibilitas data.

## Hasil perombakan

| Area | Perubahan yang sudah diterapkan |
| --- | --- |
| Pembuka dan pengaturan awal | Ilustrasi asli, manfaat konkret, dua langkah, data opsional, kebiasaan awal yang bisa dipilih, coba lagi tanpa duplikasi. |
| Navigasi | Empat tab berlabel Hari ini, Kebiasaan, Momen, Keluarga; pengaturan terlihat; tombol kembali menuju Hari ini sebelum keluar. Semua tab dan fitur inti gratis. |
| Hari ini | Jadwal sebenarnya, progres yang akurat, pertanyaan harian, ringkasan lengkap, lihat-semua menuju daftar, momen terbaru menuju detail. |
| Kebiasaan | Hari ini/Semua/Arsip, tombol selesai aman, jadwal hari lain tidak bisa dicentang sebagai hari ini, pemulihan arsip. |
| Momen dan detail | Pencarian judul/isi, filter suasana, daftar panjang bertahap, baca lengkap, edit, berbagi, dan konfirmasi hapus. |
| Keluarga | Pengelolaan anggota serta ringkasan tujuh hari terakhir yang mengabaikan tanggal masa depan. |
| Formulir | Validasi, batas isian, tanggal aman, tombol simpan saat keyboard terbuka, perlindungan perubahan, percobaan ulang, penolakan simpan ganda. |
| Tampilan | Fraunces/Jakarta dibundel, terracotta/sage/ivory, warna gelap semantik, target sentuh besar, dukungan huruf sistem dan pengurangan animasi. |
| Penyimpanan | Pembaruan induk tidak lagi menghapus relasi/check-in; pembacaan lengkap tanpa batas 50/100/500 tersembunyi. |
| Foto | Disalin ke penyimpanan privat sebelum disimpan; pembersihan hanya foto milik aplikasi yang tidak direferensikan, dengan rollback saat simpan gagal. |
| Cadangan | Semua anggota, kebiasaan termasuk arsip, check-in, cerita dan foto; validasi format, impor atomik, ID lama tidak ditimpa, pelaporan foto lama yang hilang. |
| PDF | Seluruh cerita dan foto, font dibundel, paragraf panjang melanjutkan ke halaman berikutnya. |
| Pengingat | Opsional, izin Android saat diaktifkan, waktu lokal perangkat, penjadwalan setelah boot dan pembaruan aplikasi. |
| Privasi | Halaman di aplikasi, cadangan cloud OS dinonaktifkan, pemilih foto tanpa akses seluruh galeri, kontak bantuan yang menjelaskan sifat publik. |
| Monetisasi | Semua fitur inti gratis; banner, interstitial terbatas setelah selesai menulis, serta pembelian Bebas Iklan opsional sesuai arahan pengguna. |
| Distribusi | Versi 1.4.0+8, target API 36, signing asli diwajibkan, konfigurasi AdMob produksi dipasok melalui berkas lokal; CI analisis dan tes. |

## Bukti verifikasi

- Baseline: 64 tes lulus dan analisis bersih.
- Integrasi sebelum penambahan rewarded/interstitial: **248 tes lulus** pada 5 September 2026; seluruh suite selesai dalam sekitar satu menit setelah pemuatan.
- Uji visual awal: 88 kombinasi halaman/ukuran/tema/skala. Ditemukan dan diperbaiki posisi gulir onboarding, overflow header, warna kartu bawaan, kontras gelap, judul sempit, serta ikon status bar di halaman dengan AppBar.
- Uji data menggunakan SQLite asli dan berkas sementara. PDF delapan halaman diperiksa; seluruh 500 kalimat uji dan foto tetap ada.
- AAB pertama berhasil dibuat (67,0 MB). Pemeriksaan delapan pustaka native arm64-v8a/x86_64 menunjukkan seluruh segmen LOAD selaras setidaknya 16 KiB.
- Hasil suite, build dan pemeriksaan paket final setelah penambahan iklan dicatat di bagian verifikasi final di bawah. Pemeriksaan negatif release juga membuktikan konfigurasi tanpa ADMOB_APP_ID produksi ditolak dengan pesan yang jelas.

Screenshot memakai font asli aplikasi dan data sintetis. Galeri: [preview.html](preview.html). Screenshot widget bukan pengganti uji instalasi APK. Capture perangkat dan detail verifikasi disimpan dalam folder ini.

## Batas yang dibuat eksplisit

- Cadangan maksimal 256 MB JSON, gabungan foto 128 MB, dan 100.000 rekaman per berkas. Foto maksimal 20 MB/24 MP; kegagalan diberitahukan tanpa pemotongan diam-diam.
- Foto lama yang sudah hilang dari cache sebelum pembaruan tidak dapat diciptakan kembali. Cerita tetap dapat diedit dan ekspor memberitahukan foto yang hilang.
- Tidak ada sinkronisasi cloud atau akun keluarga. Cadangan JSON dan PDF tidak dienkripsi.
- Pengingat bisa ditunda oleh kebijakan baterai perangkat. Penayangan iklan juga bergantung pada jaringan, consent dan inventori AdMob.
- Seluruh kode lama pengukuran berada di luar alur aktif, tetapi data lama tidak dihapus.

## Sebelum dipublikasikan ke Google Play

1. **URL privasi publik:** file HTML sudah diperbarui. Pemeriksaan HTTP ke `https://fareza777.github.io/arunika-tumbuh-anak/privacy-policy.html` menghasilkan 404 pada 5 September 2026; URL raw GitHub menyajikan kode HTML sebagai teks. Publikasikan halaman HTTPS yang terbaca dan isi kontak pengembang di Play Console. Ketentuan Google meminta kebijakan di dalam aplikasi dan pada URL publik. [Kebijakan data pengguna Google Play](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en).
2. **Data safety, iklan dan audiens:** jurnal lokal tidak berarti SDK iklan tidak mengumpulkan data. Cocokkan pernyataan IP/lokasi umum, pengenal, interaksi dan diagnostik dengan SDK serta konfigurasi akun. Lengkapi rating konten dan target pengguna dewasa. [Pengungkapan data Google Mobile Ads](https://developers.google.com/admob/android/privacy/play-data-disclosure).
3. **Billing dan iklan produksi:** instal melalui internal testing dengan akun penguji untuk membuktikan pembelian, pembatalan, pemulihan, consent, banner, interstitial. Rewarded ditunda oleh pemilik produk dan dinonaktifkan untuk versi ini; tidak ada tawaran atau permintaan iklan rewarded.
4. **Perangkat:** uji pengingat setelah reboot, hemat baterai, penolakan izin, perubahan zona waktu, pemulihan antarponsel, TalkBack, kamera/galeri beragam, dan pemeriksaan pra-peluncuran Play. Validasi target API 36 dan 16 KiB pada laporan bundle Play. [Persyaratan target API](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en), [dukungan ukuran halaman](https://developer.android.com/guide/practices/page-sizes).
5. **Listing:** pakai screenshot 1.4 yang sesuai APK final dan deskripsi baru di `store/aso.md`. Arsip gambar/video lama belum menggambarkan semua fitur baru dan tidak boleh diterbitkan begitu saja.

Tidak ada commit, push, unggahan ke Play Console, pembelian sungguhan, atau publikasi yang dilakukan dalam pengerjaan ini. Potensi unduhan dan pemakaian rutin masih perlu diuji dengan pengguna; hasil audit tidak menjanjikan metrik tersebut.

## Verifikasi final

**288 tes lulus** pada suite final; `flutter analyze --no-pub` bersih tanpa temuan. Semua 98 pemeriksaan tampilan/teks/batas iklan baru juga lulus secara terarah. Bukti lengkap: [tests.txt](tests.txt), [analyze.txt](analyze.txt).

| Artefak final | Ukuran | Hasil |
| --- | --- | --- |
| `build/app/outputs/flutter-apk/app-release.apk` | 71.070.151 byte (67,8 MiB) | Dibangun 5 September 2026, 20:35 WIB; signing APK v2 terverifikasi. |
| `build/app/outputs/bundle/release/app-release.aab` | 70.332.406 byte (67,1 MiB) | Dibangun 5 September 2026, 20:34 WIB. |

Paket beridentitas `id.arunika.arunika_growth`, versionName 1.4.0, versionCode 8, minSdk 24 dan targetSdk 36. Resource AdMob native pada APK cocok dengan konfigurasi privat produksi, tanpa memuat ID produksi dalam source resource yang dilacak Git. Rewarded dinonaktifkan secara default di debug dan release serta dihapus dari halaman Pengaturan.

Pemeriksaan APK: tanda tangan valid, ZIP alignment 16 KiB lulus, dan semua 8 pustaka arm64-v8a/x86_64 di bundle final memiliki LOAD alignment minimal 16 KiB. [Bukti native](native-alignment.txt), [SHA256 artefak](SHA256SUMS.txt). Manifest gabungan mengonfirmasi `allowBackup=false` dan `fullBackupContent=false`; tidak ada izin baca seluruh galeri, lokasi presisi, atau alarm tepat waktu. Izin internet, iklan, billing, notifikasi dan dependensi pendukung dicatat dari APK final.

Uji perangkat menggunakan salinan emulator Android 14/API 34 yang sementara, dengan jaringan dimatikan agar tidak memuat iklan produksi. Pengaturan awal berhasil menyimpan “Keluarga Cemara” dan “Alya”, tiga kebiasaan awal, serta momen “Piknik di teras” dan isi cerita tanpa internet. Pemasangan pembaruan APK final berhasil tanpa menghapus data; keluarga dan cerita tetap terbaca, termasuk isi lengkap di halaman detail. Capture nyata: [momen setelah pembaruan](device/moments-after-update.png) dan [detail cerita](device/detail-after-update.png). Pengujian Play Billing, penayangan iklan produksi, dan pengingat pada ponsel fisik belum diklaim lulus; langkah tersebut tetap tercantum di atas.
