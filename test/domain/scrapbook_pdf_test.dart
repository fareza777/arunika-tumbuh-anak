import 'dart:convert';
import 'dart:io';

import 'package:arunika_growth/data/models/moment.dart';
import 'package:arunika_growth/domain/together/scrapbook_pdf.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;

  setUpAll(() => initializeDateFormatting('id_ID'));
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('arunika-scrapbook-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => directory.path,
        );
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    await directory.delete(recursive: true);
  });

  test('scrapbook includes moments beyond the previous 60 item cap', () async {
    final moments = List.generate(
      70,
      (index) => Moment(
        id: 'm-$index',
        title: 'Memory $index',
        note: 'ReadableMark${index.toString().padLeft(3, '0')}',
        capturedAt: DateTime(2026, 1, 1).add(Duration(days: index)),
        createdAt: index,
      ),
    );

    final file = await ScrapbookPdf().export(
      familyName: 'Keluarga Awan',
      moments: moments,
      rituals: [],
    );

    final text = _readPdfText(await file.readAsBytes());
    expect(text, contains('ReadableMark000'));
    expect(text, contains('ReadableMark069'));
  });

  test(
    'long notes span pages and preserve the final sentence and selected photo',
    () async {
      final photo = File(p.join(directory.path, 'photo.png'));
      final picture = img.Image(width: 320, height: 180);
      img.fill(picture, color: img.ColorRgb8(106, 146, 114));
      img.fillRect(
        picture,
        x1: 75,
        y1: 40,
        x2: 245,
        y2: 140,
        color: img.ColorRgb8(235, 205, 134),
      );
      await photo.writeAsBytes(img.encodePng(picture));
      final note =
          '${List.filled(500, 'Hari ini kami membaca buku dan tertawa bersama.').join(' ')} FinalSentenceVisible';

      final file = await ScrapbookPdf().export(
        familyName: 'Keluarga Awan',
        moments: [
          Moment(
            id: 'long',
            title: 'Satu sore yang ingin diingat',
            note: note,
            photoPath: photo.path,
            capturedAt: DateTime(2026, 9, 1),
            createdAt: 1,
          ),
        ],
        rituals: [],
      );

      final bytes = await file.readAsBytes();
      expect(_readPdfText(bytes), contains('FinalSentenceVisible'));
      final raw = latin1.decode(bytes);
      expect(RegExp(r'/Subtype\s*/Image\b').hasMatch(raw), isTrue);
      expect(raw, contains('/FontFile2'));
      expect(RegExp(r'/Type\s*/Page\b').allMatches(raw).length, greaterThan(2));
      const qaDirectory = String.fromEnvironment('SCRAPBOOK_QA_DIR');
      if (qaDirectory.isNotEmpty) {
        await Directory(qaDirectory).create(recursive: true);
        await file.copy(p.join(qaDirectory, 'scrapbook-long-note.pdf'));
      }
    },
  );
}

/// Read text from the actual generated PDF, including embedded Unicode fonts.
/// This deliberately inspects content streams, not the source widget tree.
String _readPdfText(List<int> bytes) {
  final raw = latin1.decode(bytes);
  final streams = RegExp(r'stream\r?\n([\s\S]*?)\r?\nendstream')
      .allMatches(raw)
      .map((match) {
        final data = latin1.encode(match.group(1)!);
        try {
          return latin1.decode(zlib.decode(data));
        } catch (_) {
          return latin1.decode(data);
        }
      })
      .toList();
  final mappings = <Map<int, int>>[];
  for (final stream in streams) {
    if (!stream.contains('beginbfchar')) continue;
    final map = <int, int>{};
    for (final block in RegExp(
      r'beginbfchar([\s\S]*?)endbfchar',
    ).allMatches(stream)) {
      for (final pair in RegExp(
        r'<([0-9a-fA-F]+)>\s*<([0-9a-fA-F]+)>',
      ).allMatches(block.group(1)!)) {
        map[int.parse(pair.group(1)!, radix: 16)] = int.parse(
          pair.group(2)!,
          radix: 16,
        );
      }
    }
    mappings.add(map);
  }
  final result = StringBuffer();
  for (final stream in streams.where(
    (item) => item.contains('TJ') || item.contains('Tj'),
  )) {
    // Built-in fonts in the old exporter use PDF literal strings.
    for (final literal in RegExp(r'\(([^()]*)\)').allMatches(stream)) {
      result.write(literal.group(1));
    }
    for (final mapping in mappings) {
      for (final encoded in RegExp(r'<([0-9a-fA-F]+)>').allMatches(stream)) {
        final hex = encoded.group(1)!;
        for (var offset = 0; offset + 4 <= hex.length; offset += 4) {
          final code = int.parse(hex.substring(offset, offset + 4), radix: 16);
          final point = mapping[code];
          if (point != null && point <= 0x10ffff) result.writeCharCode(point);
        }
      }
    }
  }
  return result.toString();
}
