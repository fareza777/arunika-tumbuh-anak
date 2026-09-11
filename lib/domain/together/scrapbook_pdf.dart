import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:uuid/uuid.dart';

import '../../data/models/moment.dart';
import '../../data/models/ritual.dart';
import 'journal_media_store.dart';

class ScrapbookPdf {
  ScrapbookPdf({
    JournalMediaStore? mediaStore,
    AssetBundle? assets,
    Future<Directory> Function()? temporaryDirectory,
  }) : _mediaStore = mediaStore ?? JournalMediaStore(),
       _assets = assets ?? rootBundle,
       _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  final JournalMediaStore _mediaStore;
  final AssetBundle _assets;
  final Future<Directory> Function() _temporaryDirectory;

  Future<File> export({
    required String familyName,
    required List<Moment> moments,
    required List<Ritual> rituals,
    void Function(int missingPhotos)? onMissingPhotos,
  }) async {
    final bodyFont = pw.Font.ttf(
      await _assets.load('assets/fonts/PlusJakartaSans-Regular.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await _assets.load('assets/fonts/PlusJakartaSans-Bold.ttf'),
    );
    final headingFont = pw.Font.ttf(
      await _assets.load('assets/fonts/Fraunces-SemiBold.ttf'),
    );
    final document = pw.Document(
      title: 'Jurnal $familyName',
      author: 'Arunika',
      creator: 'Arunika - jurnal keluarga offline',
    );
    final dateFormat = DateFormat('d MMMM yyyy', 'id_ID');
    final sorted = [...moments]
      ..sort((a, b) {
        final byDate = b.capturedAt.compareTo(a.capturedAt);
        return byDate == 0 ? b.createdAt.compareTo(a.createdAt) : byDate;
      });
    final photos = <String, pw.MemoryImage?>{};
    var missingPhotos = 0;
    for (final moment in sorted) {
      final path = moment.photoPath;
      if (path == null || photos.containsKey(path)) continue;
      try {
        final bytes = await _mediaStore.readPhotoBytes(path);
        photos[path] = pw.MemoryImage(await compute(_preparePhoto, bytes));
      } on FileSystemException {
        photos[path] = null;
        missingPhotos++;
      } on FormatException {
        photos[path] = null;
        missingPhotos++;
      }
    }

    const ink = PdfColor.fromInt(0xFF3F392F);
    const muted = PdfColor.fromInt(0xFF776D5E);
    final heading = pw.TextStyle(font: headingFont, fontSize: 24, color: ink);
    final body = const pw.TextStyle(fontSize: 11, lineSpacing: 4, color: ink);
    document.addPage(
      pw.MultiPage(
        maxPages: 100000,
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(44, 40, 44, 38),
          theme: pw.ThemeData.withFont(base: bodyFont, bold: boldFont),
        ),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 16),
                child: pw.Text(
                  'ARUNIKA  /  $familyName',
                  style: const pw.TextStyle(fontSize: 8, color: muted),
                ),
              ),
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 16),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Kenangan kecil, tersimpan bersama.',
                style: const pw.TextStyle(fontSize: 8, color: muted),
              ),
              pw.Text(
                '${context.pageNumber} / ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: muted),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.Text(
            'ARUNIKA',
            style: const pw.TextStyle(
              fontSize: 10,
              letterSpacing: 2.5,
              color: muted,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Cerita keluarga kita',
            style: heading.copyWith(fontSize: 34),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            familyName,
            style: const pw.TextStyle(fontSize: 15, color: muted),
            overflow: pw.TextOverflow.span,
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            '${sorted.length} momen tersimpan - ${rituals.length} kebiasaan keluarga',
            style: const pw.TextStyle(fontSize: 10, color: muted),
          ),
          pw.SizedBox(height: 22),
          pw.Container(height: 4, color: const PdfColor.fromInt(0xFFE4C078)),
          pw.SizedBox(height: 24),
          if (rituals.isNotEmpty) ...[
            pw.Text(
              'Kebiasaan yang menemani',
              style: heading.copyWith(fontSize: 20),
            ),
            pw.SizedBox(height: 10),
            for (final ritual in rituals) ...[
              pw.Text(
                '${ritual.title} - ${ritual.timeOfDay.label}${ritual.isArchived ? ' (arsip)' : ''}',
                style: body,
                overflow: pw.TextOverflow.span,
              ),
              pw.SizedBox(height: 6),
            ],
            pw.SizedBox(height: 20),
          ],
          pw.Text(
            'Momen yang ingin diingat',
            style: heading.copyWith(fontSize: 20),
          ),
          pw.SizedBox(height: 16),
          if (sorted.isEmpty)
            pw.Text(
              'Belum ada momen tersimpan. Cerita berikutnya menanti.',
              style: body,
            ),
          for (var index = 0; index < sorted.length; index++) ...[
            pw.NewPage(freeSpace: sorted[index].photoPath == null ? 110 : 300),
            pw.Outline(name: 'memory-$index', title: sorted[index].title),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              color: PdfColor.fromInt(_tagColor(sorted[index].tag)),
              child: pw.Text(
                '${sorted[index].tag.label}  /  ${dateFormat.format(sorted[index].capturedAt)}',
                style: const pw.TextStyle(fontSize: 9, color: muted),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              sorted[index].title,
              style: heading.copyWith(fontSize: 21),
              overflow: pw.TextOverflow.span,
            ),
            pw.SizedBox(height: 10),
            if (photos[sorted[index].photoPath] case final photo?) ...[
              pw.Image(photo, width: 507, height: 255, fit: pw.BoxFit.contain),
              pw.SizedBox(height: 12),
            ] else if (sorted[index].photoPath != null) ...[
              pw.Text(
                'Foto ini sudah tidak tersedia di perangkat.',
                style: const pw.TextStyle(fontSize: 9, color: muted),
              ),
              pw.SizedBox(height: 8),
            ],
            // Direct spanning text can continue on the next page. Wrapping the
            // whole memory in a decorated Container makes long notes indivisible.
            pw.Text(
              sorted[index].note,
              style: body,
              overflow: pw.TextOverflow.span,
            ),
            pw.SizedBox(height: 18),
            pw.Divider(
              color: const PdfColor.fromInt(0xFFE7E0D3),
              thickness: 0.6,
            ),
            pw.SizedBox(height: 16),
          ],
        ],
      ),
    );
    final directory = await _temporaryDirectory();
    await directory.create(recursive: true);
    final file = File(
      p.join(directory.path, 'arunika-scrapbook-${const Uuid().v4()}.pdf'),
    );
    try {
      await file.writeAsBytes(await document.save(), flush: true);
    } catch (_) {
      if (await file.exists()) await file.delete();
      rethrow;
    }
    onMissingPhotos?.call(missingPhotos);
    return file;
  }

  int _tagColor(MomentTag tag) => switch (tag) {
    MomentTag.laugh => 0xFFFFEEE5,
    MomentTag.learn => 0xFFEAF2E9,
    MomentTag.together => 0xFFFFF4D9,
    MomentTag.brave => 0xFFEAF0F8,
    MomentTag.gratitude => 0xFFF4EAF3,
  };
}

Uint8List _preparePhoto(Uint8List bytes) {
  final decoded = img.decodeImage(bytes, frame: 0);
  if (decoded == null) throw const FormatException('Foto tidak dapat dibaca.');
  final oriented = img.bakeOrientation(decoded);
  final resized = oriented.width > 1600 || oriented.height > 1600
      ? img.copyResize(
          oriented,
          width: oriented.width >= oriented.height ? 1600 : null,
          height: oriented.height > oriented.width ? 1600 : null,
        )
      : oriented;
  return img.encodeJpg(resized, quality: 90);
}
