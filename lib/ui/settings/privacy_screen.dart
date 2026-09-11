import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/journal_components.dart';

Future<void> openArunikaLink(BuildContext context, String url) async {
  try {
    if (!await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        ) &&
        context.mounted) {
      journalMessage(
        context,
        'Tautan belum dapat dibuka. Coba lagi setelah terhubung ke internet.',
      );
    }
  } catch (_) {
    if (context.mounted) {
      journalMessage(context, 'Browser belum dapat dibuka. Coba lagi.');
    }
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kebijakan privasi')),
    body: JournalPage(
      slivers: [
        const JournalBlock(
          child: JournalHeader(
            eyebrow: 'DIPERBARUI 5 SEPTEMBER 2026',
            title: 'Cerita milik kalian',
            subtitle:
                'Arunika: Tumbuh Bersama tidak memerlukan akun dan tidak mengoperasikan server untuk catatan keluarga.',
          ),
        ),
        const _PolicyBlock(
          title: 'Data di perangkat',
          body:
              'Nama keluarga dan anggota, kebiasaan, hari pelaksanaan, judul dan isi momen, suasana, tanggal, serta foto pilihan disimpan di penyimpanan privat aplikasi. Data ini dipakai untuk jurnal, ringkasan, dan scrapbook. Arunika tidak mengirim isi cerita atau foto kepada pengiklan. Data tidak dicadangkan otomatis oleh aplikasi ke cloud.',
        ),
        const _PolicyBlock(
          title: 'Foto dan pengingat',
          body:
              'Foto dipilih melalui pemilih foto perangkat dan disalin ke penyimpanan aplikasi. Arunika tidak memerlukan akses ke seluruh galeri. Pengingat harian bersifat opsional, memerlukan izin notifikasi, dan dijadwalkan mengikuti zona waktu perangkat. Kamu bisa mematikannya di Pengaturan.',
        ),
        const _PolicyBlock(
          title: 'Iklan Google AdMob',
          body:
              'Versi gratis menampilkan banner dan interstitial terbatas setelah aktivitas selesai. Semua tab dan fitur inti tetap terbuka gratis. Google Mobile Ads dapat memproses pengenal iklan atau perangkat, alamat IP (termasuk perkiraan lokasi umum), informasi perangkat dan jaringan, diagnostik kinerja, serta interaksi iklan untuk penayangan, pengukuran, dan pencegahan penyalahgunaan. Pilihan persetujuan yang diwajibkan disediakan melalui Google. Opsi yang tersedia dapat dibuka dari Pengaturan → Pilihan privasi iklan.',
        ),
        JournalBlock(
          child: TextButton(
            onPressed: () => openArunikaLink(
              context,
              'https://policies.google.com/technologies/partner-sites',
            ),
            child: const Text('Pelajari penggunaan data oleh Google ↗'),
          ),
        ),
        const _PolicyBlock(
          title: 'Pembelian Bebas Iklan',
          body:
              'Pembayaran diproses Google Play. Arunika menerima informasi status pembelian untuk mengaktifkan Bebas Iklan, tanpa menerima nomor kartu atau kredensial pembayaran. Pembelian bisa dipulihkan menggunakan akun Google Play yang sama.',
        ),
        const _PolicyBlock(
          title: 'Cadangan dan berbagi',
          body:
              'Cadangan menyertakan cerita dan foto dalam berkas yang tidak dienkripsi. Kamu memilih sendiri tempat penyimpanan atau aplikasi tujuan. Jaga berkas ini seperti data pribadi lainnya. Scrapbook PDF dan cerita hanya dibagikan ketika kamu memilih tindakan berbagi. Berkas yang sudah diekspor berada di luar kendali Arunika.',
        ),
        const _PolicyBlock(
          title: 'Mengubah dan menghapus data',
          body:
              'Momen bisa diedit dan dihapus dari halaman cerita. Anggota bisa dihapus tanpa menghapus momen mereka. Kebiasaan bisa diarsipkan agar riwayatnya tetap tersimpan. Untuk menghapus seluruh data lokal, gunakan Hapus penyimpanan di Pengaturan Android untuk Arunika atau hapus aplikasi. Cadangan, scrapbook, dan foto asli di galeri tidak ikut terhapus.',
        ),
        const _PolicyBlock(
          title: 'Siapa yang menggunakan Arunika',
          body:
              'Arunika dirancang untuk orang dewasa, orang tua, wali, dan pengasuh. Tidak ada akun anak atau ruang publik. Lindungi perangkat dengan kunci layar. Arunika adalah jurnal keluarga, tanpa diagnosis atau penilaian kesehatan.',
        ),
        const _PolicyBlock(
          title: 'Perubahan dan kontak',
          body:
              'Kebijakan dapat diperbarui saat fitur atau layanan pendukung berubah. Kamu dapat menghubungi pengelola melalui halaman bantuan Arunika. Halaman tersebut bersifat publik; jangan menyertakan foto atau isi catatan keluarga.',
        ),
        JournalBlock(
          child: OutlinedButton.icon(
            onPressed: () => openArunikaLink(
              context,
              'https://github.com/fareza777/arunika-tumbuh-anak/issues',
            ),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Hubungi pengelola'),
          ),
        ),
      ],
    ),
  );
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Panduan & bantuan')),
    body: JournalPage(
      slivers: [
        const JournalBlock(
          child: JournalHeader(
            title: 'Mulai dari yang kecil',
            subtitle:
                'Tidak harus setiap hari. Arunika membantu mengingat, tanpa mengejar kesempurnaan.',
          ),
        ),
        const _PolicyBlock(
          title: '1. Pilih satu kebiasaan',
          body:
              'Buka Kebiasaan, ketuk +, lalu tentukan nama, waktu, dan hari. Centang setelah dilakukan. Kebiasaan pada hari lain tetap bisa dilihat melalui tab Semua. Arsipkan saat ingin berhenti; pulihkan kapan saja dari Arsip.',
        ),
        const _PolicyBlock(
          title: '2. Simpan cerita',
          body:
              'Ketuk Catat momen dari Hari ini atau + pada Momen. Tulis judul dan satu cerita, pilih suasana, lalu tambahkan foto jika ingin. Ketuk sebuah momen untuk membaca, mengedit, membagikan, atau menghapusnya.',
        ),
        const _PolicyBlock(
          title: '3. Baca kembali bersama',
          body:
              'Gunakan pencarian dan filter suasana di Momen. Halaman Keluarga merangkum tujuh hari terakhir dan mengelola nama anggota. Cerita lebih berguna saat dibaca bersama.',
        ),
        const _PolicyBlock(
          title: 'Pindah ponsel',
          body:
              'Di ponsel lama, buka Pengaturan → Buat cadangan dan simpan berkas. Di ponsel baru, pilih Pulihkan cadangan. Data dengan ID sama dilewati agar tidak terduplikasi. Pembelian Bebas Iklan dipulihkan terpisah melalui Google Play.',
        ),
        const _PolicyBlock(
          title: 'Pengingat belum muncul',
          body:
              'Pastikan pengingat aktif dan izin notifikasi Arunika diizinkan di Pengaturan Android. Mode hemat baterai bisa menunda pengingat. Buka Arunika kembali setelah mengganti zona waktu atau izin perangkat.',
        ),
        const _PolicyBlock(
          title: 'Bantuan lebih lanjut',
          body:
              'Sertakan versi aplikasi, model ponsel, dan langkah sebelum masalah muncul. Halaman bantuan bersifat publik; jangan kirim catatan pribadi atau foto keluarga.',
        ),
        JournalBlock(
          child: OutlinedButton.icon(
            onPressed: () => openArunikaLink(
              context,
              'https://github.com/fareza777/arunika-tumbuh-anak/issues',
            ),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Buka halaman bantuan'),
          ),
        ),
      ],
    ),
  );
}

class _PolicyBlock extends StatelessWidget {
  const _PolicyBlock({required this.title, required this.body});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => JournalBlock(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.serif(size: 24)),
        const SizedBox(height: 10),
        SelectableText(
          body,
          style: TextStyle(
            height: 1.75,
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
