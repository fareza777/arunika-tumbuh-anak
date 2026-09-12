# Arunika 1.4.1 — materi Google Play

## Metadata

- Nama: **Arunika: Tumbuh Bersama** (23 karakter).
- Package: `id.arunika.arunika_growth`.
- Kategori usulan: Lifestyle; bahasa utama Indonesia.
- Pengguna: orang dewasa, orang tua, wali, pengasuh.
- Monetisasi: banner, interstitial terbatas, dan pembelian satu kali Bebas Iklan. Semua tab dan fitur inti gratis. Harga lokal ditampilkan oleh Google Play.
- Kebijakan privasi: `https://fareza777.github.io/arunika-tumbuh-anak/privacy-policy.html`.

## Deskripsi singkat

Catat momen, rawat kebiasaan, dan simpan cerita keluarga. Bisa offline.

## Deskripsi lengkap

Ada cerita kecil yang sayang terlupa: kalimat lucu saat sarapan, jalan sore, atau buku yang dibaca bersama sebelum tidur.

Arunika: Tumbuh Bersama membantu kamu menyimpan cerita itu sekaligus merawat kebiasaan keluarga. Mulai dari satu kalimat. Tidak perlu akun.

KEBIASAAN KECIL, WAKTU BERSAMA
Buat kebiasaan sesuai hari dan waktu keluarga. Tandai setelah dilakukan. Kebiasaan bisa diarsipkan dan dipulihkan kapan saja, dengan riwayat yang tetap tersimpan.

JURNAL YANG MUDAH DIBUKA KEMBALI
Simpan judul, cerita, suasana, tanggal, anggota yang hadir, dan foto pilihan. Cari judul atau isi catatan, saring berdasarkan suasana, lalu baca cerita lengkapnya. Edit dan bagikan saat kamu menginginkannya.

MULAI DARI HARI INI
Lihat jadwal kebiasaan hari ini dan temukan pertanyaan untuk membantu mulai menulis. Halaman Keluarga merangkum momen, kebiasaan, dan hari aktif dalam tujuh hari terakhir.

PENGINGAT SESUAI PILIHANMU
Aktifkan satu pengingat harian dan pilih waktunya. Kamu bebas mematikannya. Tidak ada keharusan mengisi setiap hari.

KENANGAN BISA DIBAWA
Buat cadangan beserta foto untuk dipulihkan di ponsel lain. Ekspor scrapbook PDF untuk disimpan, dibagikan, atau dicetak. Berkas ekspor hanya dibagikan lewat tindakan yang kamu pilih sendiri.

NYAMAN DIBACA
Tampilan hangat, mode gelap, dukungan ukuran huruf perangkat, serta pilihan untuk mengurangi animasi.

CATATAN INTI DI PERANGKATMU
Jurnal bekerja tanpa internet dan tanpa akun Arunika. Isi catatan dan foto pilihan tersimpan lokal. Tidak ada sinkronisasi cloud otomatis; gunakan cadangan manual sebelum berpindah atau menghapus aplikasi. Cadangan tidak dienkripsi, jadi simpan di tempat yang kamu percayai.

Versi gratis menampilkan banner dan iklan selingan terbatas setelah aktivitas selesai. Halaman menulis bebas iklan. Semua tab dan fitur inti tetap terbuka gratis. Pembelian Bebas Iklan tersedia melalui Google Play dengan harga yang ditampilkan di aplikasi dan bisa dipulihkan memakai akun pembelian yang sama. Layanan iklan dapat memproses data perangkat sesuai kebijakan privasi.

Dibuat untuk orang dewasa, orang tua, wali, dan pengasuh yang ingin mengingat waktu bersama. Arunika adalah jurnal keluarga dan bukan layanan medis.

## Urutan screenshot terbaru

Gunakan screenshot dari UI versi 1.4.1 dengan data contoh, tanpa data keluarga asli:

1. Hari ini: “Satu kebiasaan. Satu cerita.”
2. Momen: “Cari kembali cerita favorit.”
3. Detail cerita: “Baca lengkap. Simpan lebih dekat.”
4. Kebiasaan: “Sesuai ritme keluarga.”
5. Keluarga: “Lihat waktu bersama.”
6. Pengaturan: “Cadangan dan pengingat dalam kendalimu.”

Screenshot verifikasi ada di `docs/qa/2026-09-05/screenshots/`. Gambar diambil dari widget aplikasi sebenarnya menggunakan data sintetis. Pastikan hasil APK final di Play internal testing sesuai sebelum mengunggah materi toko. Foto asli pengguna tidak digunakan. Materi promosi lama termasuk video masih perlu diganti sebelum dipublikasikan.

## Draft Data safety — perlu dicocokkan dengan Play Console

| Bagian | Perilaku versi 1.4.1 |
| --- | --- |
| Isi jurnal, anggota dan foto | Disimpan lokal; tidak dikirim ke server Arunika. Ekspor atau share dipilih pengguna. |
| Pengingat | Izin notifikasi opsional; jadwal lokal mengikuti zona waktu perangkat. |
| Cadangan | Berkas JSON beserta foto, tanpa enkripsi; pemulihan menggabungkan ID baru tanpa menimpa yang ada. |
| Google Mobile Ads | SDK iklan dapat mengumpulkan atau membagikan data perangkat/iklan, interaksi dan diagnostik; isi deklarasi sesuai versi SDK, konfigurasi dan mediation yang dipakai. |
| Pembelian | Google Play memproses pembayaran; aplikasi menerima status pembelian. |

Jangan menjawab “tidak ada pengumpulan data” hanya karena jurnal disimpan lokal. Gunakan [panduan pengungkapan Google Mobile Ads](https://developers.google.com/admob/android/privacy/play-data-disclosure) dan verifikasi konfigurasi akun serta SDK yang benar-benar dirilis.

## Sebelum produksi

Lengkapi URL privasi publik dan kontak pengembang, Data safety, deklarasi iklan, target audiens dan rating konten. Uji pembelian/pemulihan melalui track internal Google Play, persetujuan iklan, notifikasi dan pemulihan antarperangkat. Detail bukti build serta pekerjaan akun yang masih tersisa dicatat dalam laporan audit.
