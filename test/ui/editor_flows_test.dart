import 'dart:async';

import 'package:arunika_growth/core/theme/app_theme.dart';
import 'package:arunika_growth/data/models/family_member.dart';
import 'package:arunika_growth/data/models/moment.dart';
import 'package:arunika_growth/data/models/ritual.dart';
import 'package:arunika_growth/data/repo/family_member_repository.dart';
import 'package:arunika_growth/data/repo/moment_repository.dart';
import 'package:arunika_growth/data/repo/ritual_repository.dart';
import 'package:arunika_growth/state/app_settings.dart';
import 'package:arunika_growth/state/together_providers.dart';
import 'package:arunika_growth/ui/together/family_member_editor_sheet.dart';
import 'package:arunika_growth/ui/together/moment_editor_screen.dart';
import 'package:arunika_growth/ui/together/ritual_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _member = FamilyMember(id: 'member-1', name: 'Nara', createdAt: 1);
const _ritual = Ritual(id: 'ritual-1', title: 'Baca bersama', createdAt: 1);

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets('blank member names show validation without saving', (
    tester,
  ) async {
    final members = _Members();
    await _open(tester, const FamilyMemberEditorSheet(), members: members);
    await tester.enterText(_field('Nama panggilan'), '   ');
    await tester.tap(find.text('Simpan anggota'));
    await tester.pumpAndSettle();

    expect(find.text('Tulis nama panggilan terlebih dahulu.'), findsOneWidget);
    expect(members.records, isEmpty);
    expect(find.byType(FamilyMemberEditorSheet), findsOneWidget);
  });

  testWidgets('member save failure retains input and allows a retry', (
    tester,
  ) async {
    final members = _Members()..failSave = true;
    await _open(tester, const FamilyMemberEditorSheet(), members: members);
    await tester.enterText(_field('Nama panggilan'), 'Kirana');
    await tester.tap(find.text('Simpan anggota'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Belum berhasil menyimpan'), findsOneWidget);
    expect(
      tester.widget<TextField>(_field('Nama panggilan')).controller!.text,
      'Kirana',
    );
    members.failSave = false;
    await tester.tap(find.text('Simpan anggota'));
    await tester.pumpAndSettle();
    expect(find.byType(FamilyMemberEditorSheet), findsNothing);
    expect(members.records.single.name, 'Kirana');
  });

  testWidgets('pending saves cannot add the same member twice', (tester) async {
    final pending = Completer<void>();
    final members = _Members()..pending = pending.future;
    await _open(tester, const FamilyMemberEditorSheet(), members: members);
    await tester.enterText(_field('Nama panggilan'), 'Kirana');
    await tester.tap(find.text('Simpan anggota'));
    await tester.tap(find.text('Simpan anggota'));
    await tester.pump();

    expect(members.saveCalls, 1);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(FamilyMemberEditorSheet), findsOneWidget);
    pending.complete();
    await tester.pumpAndSettle();
    expect(members.records, hasLength(1));
  });

  testWidgets('sheet close protects changed input until discard is confirmed', (
    tester,
  ) async {
    await _open(tester, const FamilyMemberEditorSheet());
    await tester.enterText(_field('Nama panggilan'), 'Kirana');
    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();
    expect(find.text('Buang perubahan?'), findsOneWidget);
    await tester.tap(find.text('Lanjut mengisi'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(_field('Nama panggilan')).controller!.text,
      'Kirana',
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buang perubahan'));
    await tester.pumpAndSettle();
    expect(find.byType(FamilyMemberEditorSheet), findsNothing);
  });

  testWidgets(
    'member removal requires confirmation and retains the editor on failure',
    (tester) async {
      final members = _Members()..records.add(_member);
      await _open(
        tester,
        const FamilyMemberEditorSheet(initial: _member),
        members: members,
      );
      await tester.ensureVisible(find.text('Hapus anggota'));
      await tester.tap(find.text('Hapus anggota'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Momen tetap tersimpan'), findsOneWidget);
      expect(members.records, hasLength(1));
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(members.records, hasLength(1));

      members.failDelete = true;
      await tester.tap(find.text('Hapus anggota'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Hapus anggota').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Belum berhasil menghapus'), findsOneWidget);
      expect(find.byType(FamilyMemberEditorSheet), findsOneWidget);
    },
  );

  testWidgets('editing an archived ritual preserves the archive state', (
    tester,
  ) async {
    final rituals = _Rituals();
    await _open(
      tester,
      RitualEditorSheet(initial: _ritual.copyWith(isArchived: true)),
      rituals: rituals,
    );
    await tester.enterText(_field('Nama ritual'), 'Baca cerita bersama');
    await tester.ensureVisible(find.text('Simpan ritual'));
    await tester.tap(find.text('Simpan ritual'));
    await tester.pumpAndSettle();

    expect(rituals.records.single.title, 'Baca cerita bersama');
    expect(rituals.records.single.isArchived, isTrue);
    expect(find.byType(RitualEditorSheet), findsNothing);
  });

  testWidgets(
    'confirmed member removal closes the editor and removes the member',
    (tester) async {
      final members = _Members()..records.add(_member);
      await _open(
        tester,
        const FamilyMemberEditorSheet(initial: _member),
        members: members,
      );
      await tester.ensureVisible(find.text('Hapus anggota'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus anggota'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog, skipOffstage: false), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Hapus anggota'));
      await tester.pumpAndSettle();
      expect(members.records, isEmpty);
      expect(find.byType(FamilyMemberEditorSheet), findsNothing);
    },
  );

  testWidgets('ritual archive and restore are confirmed actions', (
    tester,
  ) async {
    final rituals = _Rituals()..records.add(_ritual);
    await _open(
      tester,
      const RitualEditorSheet(initial: _ritual),
      rituals: rituals,
    );
    await tester.ensureVisible(find.text('Arsipkan ritual'));
    await tester.tap(find.text('Arsipkan ritual'));
    await tester.pumpAndSettle();
    expect(rituals.records.single.isArchived, isFalse);
    await tester.tap(find.widgetWithText(FilledButton, 'Arsipkan').last);
    await tester.pumpAndSettle();
    expect(rituals.records.single.isArchived, isTrue);

    await _open(
      tester,
      RitualEditorSheet(initial: rituals.records.single),
      rituals: rituals,
    );
    await tester.ensureVisible(find.text('Aktifkan kembali'));
    await tester.tap(find.text('Aktifkan kembali'));
    await tester.pumpAndSettle();
    expect(rituals.records.single.isArchived, isTrue);
    await tester.tap(find.widgetWithText(FilledButton, 'Aktifkan').last);
    await tester.pumpAndSettle();
    expect(rituals.records.single.isArchived, isFalse);
  });

  testWidgets(
    'ritual requires a scheduled day and offers readable day targets',
    (tester) async {
      final rituals = _Rituals();
      await _open(tester, const RitualEditorSheet(), rituals: rituals);
      await tester.enterText(_field('Nama ritual'), 'Jalan pagi');
      for (final day in ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']) {
        await tester.ensureVisible(find.text(day));
        await tester.pumpAndSettle();
        final target = find.ancestor(
          of: find.text(day),
          matching: find.byType(FilterChip),
        );
        expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
        await tester.tap(find.text(day));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Simpan ritual'));
      await tester.tap(find.text('Simpan ritual'));
      await tester.pumpAndSettle();
      expect(find.text('Pilih sedikitnya satu hari.'), findsOneWidget);
      expect(rituals.records, isEmpty);
    },
  );

  testWidgets('moment back protects draft and save failure leaves a retry', (
    tester,
  ) async {
    final moments = _Moments()..failSave = true;
    await _open(
      tester,
      const MomentEditorScreen(),
      moments: moments,
      sheet: false,
    );
    await tester.enterText(_field('Judul momen'), 'Hujan pertama');
    await tester.enterText(
      _field('Ceritakan sedikit'),
      'Kami bermain di teras.',
    );
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Buang perubahan?'), findsOneWidget);
    await tester.tap(find.text('Lanjut mengisi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Belum berhasil menyimpan'), findsOneWidget);
    moments.failSave = false;
    await tester.tap(find.text('Simpan').first);
    await tester.pumpAndSettle();
    expect(moments.records.single.note, 'Kami bermain di teras.');
    expect(find.byType(MomentEditorScreen), findsNothing);
  });

  testWidgets(
    'missing member references are cleared safely when saving a moment',
    (tester) async {
      final moments = _Moments();
      final members = _Members()..records.add(_member);
      final initial = Moment(
        id: 'moment-1',
        title: 'Pagi',
        note: 'Bersama.',
        memberId: 'deleted',
        capturedAt: DateTime(2025),
        createdAt: 1,
      );
      await _open(
        tester,
        MomentEditorScreen(initial: initial),
        moments: moments,
        members: members,
        sheet: false,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Simpan').first);
      await tester.pumpAndSettle();
      expect(moments.records.single.memberId, isNull);
    },
  );

  testWidgets('legacy future moment dates do not crash the date picker', (
    tester,
  ) async {
    final initial = Moment(
      id: 'moment-1',
      title: 'Pagi',
      note: 'Bersama.',
      capturedAt: DateTime.now().add(const Duration(days: 20)),
      createdAt: 1,
    );
    await _open(tester, MomentEditorScreen(initial: initial), sheet: false);
    await tester.ensureVisible(find.text('Tanggal momen'));
    await tester.tap(find.text('Tanggal momen'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'removing an unreadable moment photo saves the cleared attachment',
    (tester) async {
      final moments = _Moments();
      final initial = Moment(
        id: 'moment-1',
        title: 'Pagi',
        note: 'Bersama.',
        photoPath: 'missing-image.jpg',
        capturedAt: DateTime(2025),
        createdAt: 1,
      );
      await _open(
        tester,
        MomentEditorScreen(initial: initial),
        moments: moments,
        sheet: false,
      );
      await tester.tap(find.text('Hapus foto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan').first);
      await tester.pumpAndSettle();
      expect(moments.records.single.photoPath, isNull);
      expect(moments.records.single.note, 'Bersama.');
    },
  );

  testWidgets('sheets remain scrollable with keyboard and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.reset);
    for (final editor in [
      const FamilyMemberEditorSheet(),
      const RitualEditorSheet(),
    ]) {
      await _open(tester, editor, largeText: true, dark: true);
      final save = find.widgetWithText(
        FilledButton,
        editor is FamilyMemberEditorSheet ? 'Simpan anggota' : 'Simpan ritual',
      );
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getRect(save).bottom, lessThanOrEqualTo(380));
      await tester.tap(find.byTooltip('Tutup'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('an unavailable photo grows for large text without overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final initial = Moment(
      id: 'moment-1',
      title: 'Pagi',
      note: 'Bersama.',
      photoPath: 'unavailable.jpg',
      capturedAt: DateTime(2025),
      createdAt: 1,
    );
    await tester.runAsync(() async {
      await _open(
        tester,
        MomentEditorScreen(initial: initial),
        sheet: false,
        largeText: true,
        dark: true,
      );
      final photo = tester.widget<Image>(find.byType(Image));
      final loaded = Completer<void>();
      final stream = photo.image.resolve(ImageConfiguration.empty);
      final listener = ImageStreamListener(
        (_, _) => loaded.complete(),
        onError: (_, _) => loaded.complete(),
      );
      stream.addListener(listener);
      try {
        await loaded.future.timeout(const Duration(seconds: 5));
      } finally {
        stream.removeListener(listener);
      }
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Foto tidak tersedia'), findsOneWidget);
    await tester.ensureVisible(find.text('Hapus foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus foto'));
    await tester.pumpAndSettle();
    expect(find.text('Tambah foto (opsional)'), findsOneWidget);
  });

  testWidgets(
    'photo picker errors preserve the story and allow saving without a photo',
    (tester) async {
      const channel = MethodChannel('plugins.flutter.io/image_picker');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(code: 'photo_access_denied'),
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final moments = _Moments();
      await _open(
        tester,
        const MomentEditorScreen(),
        moments: moments,
        sheet: false,
      );
      await tester.enterText(_field('Judul momen'), 'Di teras');
      await tester.enterText(
        _field('Ceritakan sedikit'),
        'Menunggu hujan reda.',
      );
      await tester.ensureVisible(find.text('Tambah foto (opsional)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tambah foto (opsional)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Foto belum berhasil dibuka'), findsOneWidget);
      expect(
        tester.widget<TextField>(_field('Ceritakan sedikit')).controller!.text,
        'Menunggu hujan reda.',
      );
      await tester.tap(find.text('Simpan').first);
      await tester.pumpAndSettle();
      expect(moments.records.single.photoPath, isNull);
      expect(moments.records.single.note, 'Menunggu hujan reda.');
    },
  );

  testWidgets('moment text bounds prevent oversized pasted content', (
    tester,
  ) async {
    final moments = _Moments();
    await _open(
      tester,
      const MomentEditorScreen(),
      moments: moments,
      sheet: false,
    );
    await tester.enterText(_field('Judul momen'), 'A' * 110);
    await tester.enterText(_field('Ceritakan sedikit'), 'B' * 4010);
    await tester.tap(find.text('Simpan').first);
    await tester.pumpAndSettle();
    expect(moments.records.single.title.length, 100);
    expect(moments.records.single.note.length, 4000);
  });

  testWidgets(
    'legacy long member names can be corrected without losing the saved role',
    (tester) async {
      final members = _Members();
      final initial = _member.copyWith(name: 'N' * 70, role: 'guardian');
      await _open(
        tester,
        FamilyMemberEditorSheet(initial: initial),
        members: members,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Simpan anggota'));
      await tester.pumpAndSettle();
      expect(members.records, isEmpty);
      expect(
        tester
            .widget<TextField>(_field('Nama panggilan'))
            .controller!
            .text
            .length,
        70,
      );
      await tester.enterText(_field('Nama panggilan'), 'Nara');
      await tester.tap(find.text('Simpan anggota'));
      await tester.pumpAndSettle();
      expect(members.records.single.role, 'guardian');
    },
  );

  testWidgets('ritual save errors preserve edited schedule for retry', (
    tester,
  ) async {
    final rituals = _Rituals()..failSave = true;
    await _open(
      tester,
      const RitualEditorSheet(initial: _ritual),
      rituals: rituals,
    );
    await tester.enterText(_field('Nama ritual'), 'Baca cerita');
    await tester.ensureVisible(find.text('Sen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan ritual'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Belum berhasil menyimpan'), findsOneWidget);
    rituals.failSave = false;
    await tester.tap(find.text('Simpan ritual'));
    await tester.pumpAndSettle();
    expect(rituals.records.single.title, 'Baca cerita');
    expect(rituals.records.single.repeatDays, {2, 3, 4, 5, 6, 7});
  });
}

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<void> _open(
  WidgetTester tester,
  Widget editor, {
  bool sheet = true,
  bool largeText = false,
  bool dark = false,
  _Members? members,
  _Rituals? rituals,
  _Moments? moments,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        familyMemberRepositoryProvider.overrideWithValue(members ?? _Members()),
        ritualRepositoryProvider.overrideWithValue(rituals ?? _Rituals()),
        momentRepositoryProvider.overrideWithValue(moments ?? _Moments()),
      ],
      child: MaterialApp(
        theme: AppTheme.build(
          brightness: dark ? Brightness.dark : Brightness.light,
        ),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('id', 'ID')],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(largeText ? 2 : 1)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () {
                  if (sheet) {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      isDismissible: false,
                      enableDrag: false,
                      builder: (_) => editor,
                    );
                  } else {
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute<void>(builder: (_) => editor));
                  }
                },
                child: const Text('Buka editor'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Buka editor'));
  await tester.pumpAndSettle();
}

class _Members extends FamilyMemberRepository {
  final records = <FamilyMember>[];
  bool failSave = false;
  bool failDelete = false;
  int saveCalls = 0;
  Future<void>? pending;

  @override
  Future<List<FamilyMember>> getAll() async => [...records];
  @override
  Future<void> insert(FamilyMember member) async {
    saveCalls++;
    if (pending != null) await pending;
    if (failSave) throw StateError('Storage unavailable');
    records.removeWhere((record) => record.id == member.id);
    records.add(member);
  }

  @override
  Future<void> update(FamilyMember member) => insert(member);
  @override
  Future<void> delete(String id) async {
    if (failDelete) throw StateError('Storage unavailable');
    records.removeWhere((record) => record.id == id);
  }
}

class _Rituals extends RitualRepository {
  final records = <Ritual>[];
  bool failSave = false;
  @override
  Future<List<Ritual>> getAll({bool includeArchived = false}) async =>
      records.where((record) => includeArchived || !record.isArchived).toList();
  @override
  Future<void> save(Ritual ritual) async {
    if (failSave) throw StateError('Storage unavailable');
    records.removeWhere((record) => record.id == ritual.id);
    records.add(ritual);
  }

  @override
  Future<void> archive(String id) async {
    final index = records.indexWhere((record) => record.id == id);
    records[index] = records[index].copyWith(isArchived: true);
  }
}

class _Moments extends MomentRepository {
  final records = <Moment>[];
  bool failSave = false;
  @override
  Future<List<Moment>> getAll() async => [...records];
  @override
  Future<void> save(Moment moment) async {
    if (failSave) throw StateError('Storage unavailable');
    records.removeWhere((record) => record.id == moment.id);
    records.add(moment);
  }
}
