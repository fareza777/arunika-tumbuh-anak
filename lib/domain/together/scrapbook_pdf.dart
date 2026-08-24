import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/models/moment.dart';
import '../../data/models/ritual.dart';

class ScrapbookPdf {
  Future<File> export({
    required String familyName,
    required List<Moment> moments,
    required List<Ritual> rituals,
  }) async {
    final document = pw.Document();
    final dateFormat = DateFormat('d MMMM yyyy', 'id_ID');
    final sorted = [...moments]
      ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(42, 46, 42, 42),
          theme: pw.ThemeData.withFont(),
        ),
        build: (context) => [
          pw.Text(
            'ARUNIKA',
            style: pw.TextStyle(
              fontSize: 11,
              letterSpacing: 2,
              color: PdfColors.brown,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Tumbuh Bersama',
            style: pw.TextStyle(
              fontSize: 30,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.brown900,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Scrapbook kecil untuk $familyName',
            style: const pw.TextStyle(fontSize: 13, color: PdfColors.brown),
          ),
          pw.SizedBox(height: 24),
          pw.Container(
            height: 5,
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE4C078),
            ),
          ),
          pw.SizedBox(height: 22),
          pw.Text(
            'Ritual yang dipilih',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.brown900,
            ),
          ),
          pw.SizedBox(height: 8),
          if (rituals.isEmpty)
            pw.Text(
              'Belum ada ritual tersimpan.',
              style: const pw.TextStyle(fontSize: 11),
            )
          else
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: rituals
                  .map(
                    (ritual) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 5),
                      child: pw.Text(
                        '• ${ritual.title} — ${ritual.timeOfDay.label}',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ),
                  )
                  .toList(),
            ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Momen yang ingin diingat',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.brown900,
            ),
          ),
          pw.SizedBox(height: 10),
          if (sorted.isEmpty)
            pw.Text(
              'Belum ada momen tersimpan.',
              style: const pw.TextStyle(fontSize: 11),
            )
          else
            ...sorted
                .take(60)
                .map(
                  (moment) => pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 13),
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(_tagColor(moment.tag)),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(8),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '${moment.tag.label}  •  ${dateFormat.format(moment.capturedAt)}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.brown,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          moment.title,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.brown900,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          moment.note,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.brown,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          pw.SizedBox(height: 26),
          pw.Text(
            'Dibuat dengan Arunika — ruang privat untuk hadir bersama.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    final directory = await getTemporaryDirectory();
    final filename = 'arunika-${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(p.join(directory.path, filename));
    await file.writeAsBytes(await document.save());
    return file;
  }

  int _tagColor(MomentTag tag) {
    switch (tag) {
      case MomentTag.laugh:
        return 0xFFFFEEE5;
      case MomentTag.learn:
        return 0xFFEAF2E9;
      case MomentTag.together:
        return 0xFFFFF4D9;
      case MomentTag.brave:
        return 0xFFEAF0F8;
      case MomentTag.gratitude:
        return 0xFFF4EAF3;
    }
  }
}
