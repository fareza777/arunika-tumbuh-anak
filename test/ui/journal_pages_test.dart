import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:arunika_growth/core/theme/app_theme.dart';
import 'package:arunika_growth/data/models/family_member.dart';
import 'package:arunika_growth/data/models/moment.dart';
import 'package:arunika_growth/data/models/ritual.dart';
import 'package:arunika_growth/data/models/ritual_check_in.dart';
import 'package:arunika_growth/data/repo/family_member_repository.dart';
import 'package:arunika_growth/data/repo/moment_repository.dart';
import 'package:arunika_growth/data/repo/ritual_repository.dart';
import 'package:arunika_growth/domain/monetization/monetization_state.dart';
import 'package:arunika_growth/state/app_settings.dart';
import 'package:arunika_growth/state/journal_reminder_provider.dart';
import 'package:arunika_growth/state/monetization_provider.dart';
import 'package:arunika_growth/state/together_providers.dart';
import 'package:arunika_growth/ui/navigation/main_shell.dart';
import 'package:arunika_growth/ui/onboarding/onboarding_screen.dart';
import 'package:arunika_growth/ui/settings/privacy_screen.dart';
import 'package:arunika_growth/ui/settings/settings_screen.dart';
import 'package:arunika_growth/ui/together/family_member_editor_sheet.dart';
import 'package:arunika_growth/ui/together/garden_screen.dart';
import 'package:arunika_growth/ui/together/moment_detail_screen.dart';
import 'package:arunika_growth/ui/together/moment_editor_screen.dart';
import 'package:arunika_growth/ui/together/moments_screen.dart';
import 'package:arunika_growth/ui/together/rituals_screen.dart';
import 'package:arunika_growth/ui/together/today_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _screenshots = bool.fromEnvironment('JOURNAL_SCREENSHOTS');
const _screenshotDirectory = 'docs/qa/2026-09-05/screenshots';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
    for (final family in {
      'Fraunces': [
        'assets/fonts/Fraunces-Medium.ttf',
        'assets/fonts/Fraunces-SemiBold.ttf',
      ],
      'PlusJakartaSans': [
        'assets/fonts/PlusJakartaSans-Regular.ttf',
        'assets/fonts/PlusJakartaSans-Medium.ttf',
        'assets/fonts/PlusJakartaSans-SemiBold.ttf',
        'assets/fonts/PlusJakartaSans-Bold.ttf',
        'assets/fonts/PlusJakartaSans-ExtraBold.ttf',
      ],
      'MaterialIcons': ['fonts/MaterialIcons-Regular.otf'],
    }.entries) {
      final loader = FontLoader(family.key);
      for (final asset in family.value) {
        loader.addFont(rootBundle.load(asset));
      }
      await loader.load();
    }
  });

  testWidgets(
    'Today counts only scheduled habits and opens the requested lists',
    (tester) async {
      final data = _JournalData.sample();
      var compose = 0;
      var createHabit = 0;
      var habits = 0;
      var moments = 0;
      var family = 0;
      await _mount(
        tester,
        TodayScreen(
          onOpenMoment: () => compose++,
          onOpenRitual: () => createHabit++,
          onOpenRituals: () => habits++,
          onOpenMoments: () => moments++,
          onOpenGarden: () => family++,
        ),
        data: data,
      );
      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.text('Jalan sebentar'), findsWidgets);
      expect(find.text('Tiga hal yang disyukuri'), findsWidgets);
      await _tap(tester, find.text('Lihat semua kebiasaan'));
      await _tap(tester, find.text('Ringkasan'));
      await _tap(tester, find.text('Lihat semua'));
      expect([habits, moments, family, compose, createHabit], [1, 1, 1, 0, 0]);
    },
  );

  testWidgets('an empty schedule is not presented as a completed day', (
    tester,
  ) async {
    final data = _JournalData.sample();
    data.rituals.records.removeWhere((ritual) => ritual.id != 'off-day');
    var opened = 0;
    await _mount(
      tester,
      TodayScreen(
        onOpenMoment: () {},
        onOpenRitual: () {},
        onOpenRituals: () => opened++,
      ),
      data: data,
    );
    expect(find.text('Hari ini tanpa jadwal'), findsOneWidget);
    expect(
      find.textContaining('Semua jadwal hari ini sudah dilakukan'),
      findsNothing,
    );
    expect(find.text('0 / 0'), findsNothing);
    await _tap(tester, find.text('Lihat kebiasaan'));
    expect(opened, 1);
  });

  testWidgets(
    'timeline search distinguishes no matches from an empty journal',
    (tester) async {
      final data = _JournalData.sample();
      await _mount(tester, MomentsScreen(onOpenMoment: () {}), data: data);
      await tester.enterText(find.byType(TextField), 'pesawat antariksa');
      await tester.pumpAndSettle();
      await _reveal(tester, find.text('Belum ada yang cocok'));
      expect(find.text('Cerita pertama dimulai di sini'), findsNothing);
      await _tap(tester, find.text('Reset pencarian'));
      await _reveal(tester, find.text('Piknik kecil di teras'));
      expect(find.text('Belum ada yang cocok'), findsNothing);

      var compose = 0;
      await _mount(
        tester,
        MomentsScreen(onOpenMoment: () => compose++),
        data: _JournalData.empty(),
      );
      await _reveal(tester, find.text('Cerita pertama dimulai di sini'));
      expect(find.text('Belum ada yang cocok'), findsNothing);
      await _tap(tester, find.text('Catat momen pertama'));
      expect(compose, 1);
    },
  );

  testWidgets(
    'mood filtering returns its matching story and a card opens read detail',
    (tester) async {
      final data = _JournalData.sample();
      await _mount(tester, MomentsScreen(onOpenMoment: () {}), data: data);
      await _tap(tester, find.widgetWithText(ChoiceChip, 'Syukur'));
      await _reveal(tester, find.text('Terima kasih untuk hari ini'));
      expect(find.text('Piknik kecil di teras'), findsNothing);
      await _tap(tester, find.text('Terima kasih untuk hari ini'));
      expect(find.byType(MomentDetailScreen), findsOneWidget);
      expect(find.byType(MomentEditorScreen), findsNothing);
      expect(
        find.widgetWithText(SelectableText, data.moments.records[1].note),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Edit momen'));
      await tester.pumpAndSettle();
      expect(find.byType(MomentEditorScreen), findsOneWidget);
    },
  );

  testWidgets(
    'off-day habits cannot be checked and archive filters stay separate',
    (tester) async {
      final data = _JournalData.sample();
      await _mount(tester, RitualsScreen(onOpenRitual: () {}), data: data);
      expect(find.text('Rapikan kebun bersama'), findsNothing);
      await _tap(tester, find.widgetWithText(ChoiceChip, 'Semua'));
      await _reveal(tester, find.text('Rapikan kebun bersama'));
      final row = find.ancestor(
        of: find.text('Rapikan kebun bersama'),
        matching: find.byType(RitualRow),
      );
      final check = find.descendant(of: row, matching: find.byType(Checkbox));
      expect(tester.widget<Checkbox>(check).onChanged, isNull);
      expect(find.text('Tidak dijadwalkan hari ini'), findsOneWidget);
      await _tap(tester, find.widgetWithText(ChoiceChip, 'Arsip'));
      await _reveal(tester, find.text('Menyiram tanaman pagi'));
      expect(find.text('Jalan sebentar'), findsNothing);
      expect(find.text('Rapikan kebun bersama'), findsNothing);
      await _tap(tester, find.text('Pulihkan kebiasaan'));
      expect(
        data.rituals.records.singleWhere((r) => r.id == 'archived').isArchived,
        isFalse,
      );
      await _reveal(tester, find.text('Belum ada arsip'));
    },
  );

  testWidgets('failed completion keeps a habit unchecked and can be retried', (
    tester,
  ) async {
    final data = _JournalData.sample(today: DateTime.now());
    data.rituals.failCheck = true;
    await _mount(tester, RitualsScreen(onOpenRitual: () {}), data: data);
    final row = find.ancestor(
      of: find.text('Jalan sebentar'),
      matching: find.byType(RitualRow),
    );
    final check = find.descendant(of: row, matching: find.byType(Checkbox));
    await _tap(tester, check);
    expect(find.text('Tanda belum tersimpan. Coba lagi.'), findsOneWidget);
    expect(tester.widget<Checkbox>(check).value, isFalse);
    data.rituals.failCheck = false;
    await _tap(tester, check);
    expect(tester.widget<Checkbox>(check).value, isTrue);
    expect(
      data.rituals.checkIns.where(
        (c) => c.ritualId == 'walk' && c.dayKey == ritualDayKey(data.today),
      ),
      hasLength(1),
    );
  });

  testWidgets(
    'family rows show complete association counts and open member editing',
    (tester) async {
      final data = _JournalData.sample();
      await _mount(tester, const GardenScreen(), data: data);
      await _reveal(tester, find.text('3 momen tersimpan di perangkat ini'));
      await _reveal(tester, find.text('Keluarga · 2 momen'));
      await _tap(tester, find.text('Nara'));
      expect(find.byType(FamilyMemberEditorSheet), findsOneWidget);
      expect(
        tester.widget<TextField>(_field('Nama panggilan')).controller!.text,
        'Nara',
      );
    },
  );

  testWidgets('onboarding failure retains input and retry creates one member', (
    tester,
  ) async {
    final data = _JournalData.empty();
    data.rituals.failSave = true;
    final harness = await _mount(tester, const OnboardingScreen(), data: data);
    await _tap(tester, find.text('Buat ruang keluarga'));
    await tester.enterText(_field('Nama keluarga (opsional)'), 'Keluarga Awan');
    await tester.enterText(_field('Nama panggilan anggota (opsional)'), 'Nara');
    await _tap(tester, find.text('Mulai cerita keluarga'));
    expect(
      find.textContaining('Ruang keluarga belum selesai disimpan'),
      findsOneWidget,
    );
    expect(harness.prefs.getBool('together_onboarding_done'), isNot(true));
    expect(
      tester
          .widget<TextField>(_field('Nama keluarga (opsional)'))
          .controller!
          .text,
      'Keluarga Awan',
    );
    data.rituals.failSave = false;
    await _tap(tester, find.text('Mulai cerita keluarga'));
    expect(harness.prefs.getBool('together_onboarding_done'), isTrue);
    expect(data.members.records, hasLength(1));
    expect(data.members.insertCalls, 1);
    expect(data.rituals.records, hasLength(3));
    expect(find.byType(MainShell), findsOneWidget);
  });

  testWidgets(
    'reading the welcome page to the end opens setup at its beginning',
    (tester) async {
      await _mount(
        tester,
        const OnboardingScreen(),
        config: const _Layout(Size(320, 640), Brightness.light, 1),
      );
      await _sweep(tester, 'onboarding welcome');
      await _tap(tester, find.text('Buat ruang keluarga'));
      expect(find.text('Untuk keluarga kalian').hitTestable(), findsOneWidget);
    },
  );

  testWidgets(
    'settings saves a family name and opens the in-app privacy policy',
    (tester) async {
      final harness = await _mount(tester, const SettingsScreen());
      await _tap(tester, find.text('Nama ruang keluarga'));
      await tester.enterText(_field('Nama keluarga'), 'Ruang Nara');
      await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
      await tester.pumpAndSettle();
      expect(harness.prefs.getString('family_name'), 'Ruang Nara');
      expect(find.text('Ruang Nara'), findsOneWidget);
      await _tap(tester, find.text('Mode gelap'));
      expect(harness.prefs.getBool('dark_mode'), isTrue);
      await _tap(tester, find.text('Kebijakan privasi'));
      expect(find.byType(PrivacyScreen), findsOneWidget);
      expect(find.text('Cerita milik kalian'), findsOneWidget);
    },
  );

  testWidgets(
    'deleting a read story requires confirmation and updates the timeline',
    (tester) async {
      final data = _JournalData.sample();
      await _mount(tester, MomentsScreen(onOpenMoment: () {}), data: data);
      await _tap(tester, find.text('Piknik kecil di teras'));
      await _tap(tester, find.text('Hapus momen'));
      expect(data.moments.records, hasLength(3));
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.byType(MomentDetailScreen), findsOneWidget);
      await _tap(tester, find.text('Hapus momen'));
      await tester.tap(find.widgetWithText(FilledButton, 'Hapus momen'));
      await tester.pumpAndSettle();
      expect(data.moments.records, hasLength(2));
      expect(find.byType(MomentDetailScreen), findsNothing);
      expect(find.text('Piknik kecil di teras'), findsNothing);
    },
  );

  testWidgets(
    'shell offers one ad boundary after a new story is saved and returned',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final data = _JournalData.sample();
      final pending = Completer<void>();
      data.moments.saveBarrier = pending.future;
      final monetization = _RecordingMonetization();
      await _mount(
        tester,
        const MainShell(),
        data: data,
        monetization: monetization,
      );
      await _tap(tester, find.text('Catat momen'));
      await tester.enterText(_field('Judul momen'), 'Langit senja bersama');
      await tester.enterText(
        _field('Ceritakan sedikit'),
        'Kami mencari bentuk awan.',
      );
      await tester.tap(find.widgetWithText(TextButton, 'Simpan'));
      await tester.pump();
      expect(data.moments.saveCalls, 1);
      expect(find.byType(MomentEditorScreen), findsOneWidget);
      expect(monetization.boundaryCalls, 0);

      pending.complete();
      await tester.pumpAndSettle();
      expect(data.moments.records, hasLength(4));
      expect(find.byType(MomentEditorScreen), findsNothing);
      expect(monetization.boundaryCalls, 1);
      expect(monetization.presentationChecks, [true]);
      await tester.pump(const Duration(seconds: 1));
      expect(monetization.boundaryCalls, 1);
      await _selectTab(tester, 'Momen');
      expect(monetization.canPresent!(), isFalse);
    },
  );

  testWidgets(
    'shell skips ad boundaries for canceled invalid and failed stories',
    (tester) async {
      final data = _JournalData.sample();
      final monetization = _RecordingMonetization();
      await _mount(
        tester,
        const MainShell(),
        data: data,
        monetization: monetization,
      );
      await _tap(tester, find.text('Catat momen'));
      await _tap(tester, find.byTooltip('Kembali'));
      expect(monetization.boundaryCalls, 0);

      await _tap(tester, find.text('Catat momen'));
      await _tap(tester, find.widgetWithText(TextButton, 'Simpan'));
      expect(find.text('Tulis judul untuk momen ini.'), findsOneWidget);
      expect(data.moments.saveCalls, 0);
      expect(monetization.boundaryCalls, 0);
      await _tap(tester, find.byTooltip('Kembali'));

      data.moments.failSave = true;
      await _tap(tester, find.text('Catat momen'));
      await tester.enterText(_field('Judul momen'), 'Langit senja bersama');
      await tester.enterText(
        _field('Ceritakan sedikit'),
        'Kami mencari bentuk awan.',
      );
      await _tap(tester, find.widgetWithText(TextButton, 'Simpan'));
      expect(
        find.textContaining('Belum berhasil menyimpan momen.'),
        findsOneWidget,
      );
      expect(find.byType(MomentEditorScreen), findsOneWidget);
      expect(data.moments.records, hasLength(3));
      expect(data.moments.saveCalls, 1);
      expect(monetization.boundaryCalls, 0);
      await _tap(tester, find.byTooltip('Kembali'));
      await _tap(tester, find.text('Buang perubahan'));
      expect(find.byType(MomentEditorScreen), findsNothing);
      expect(monetization.boundaryCalls, 0);
    },
  );

  testWidgets('shell skips ad boundaries when an existing story is edited', (
    tester,
  ) async {
    final data = _JournalData.sample();
    final monetization = _RecordingMonetization();
    await _mount(
      tester,
      const MainShell(),
      data: data,
      monetization: monetization,
    );
    await _selectTab(tester, 'Momen');
    await _tap(tester, find.text('Piknik kecil di teras'));
    await _tap(tester, find.byTooltip('Edit momen'));
    await tester.enterText(_field('Judul momen'), 'Piknik dan cerita sore');
    await _tap(tester, find.widgetWithText(TextButton, 'Simpan'));
    expect(find.byType(MomentEditorScreen), findsNothing);
    expect(find.byType(MomentDetailScreen), findsOneWidget);
    expect(find.text('Piknik dan cerita sore'), findsOneWidget);
    expect(data.moments.records, hasLength(3));
    expect(monetization.boundaryCalls, 0);
  });

  for (final config in [
    const _Layout(Size(320, 640), Brightness.dark, 2),
    const _Layout(Size(390, 844), Brightness.light, 1),
  ]) {
    testWidgets(
      'shell keeps all tabs usable without a purchase ${config.label}',
      (tester) async {
        final originalPlatform = debugDefaultTargetPlatformOverride;
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        try {
          final monetization = _RecordingMonetization(adsRemoved: false);
          await _mount(
            tester,
            const MainShell(),
            config: config,
            monetization: monetization,
          );
          for (final (index, label, pageType, title) in [
            (1, 'Kebiasaan', RitualsScreen, 'Kebiasaan'),
            (2, 'Momen', MomentsScreen, 'Momen'),
            (3, 'Keluarga', GardenScreen, 'Keluarga'),
            (0, 'Hari ini', TodayScreen, 'Keluarga Awan'),
          ]) {
            await _selectTab(tester, label);
            expect(
              tester
                  .widget<NavigationBar>(find.byType(NavigationBar))
                  .selectedIndex,
              index,
            );
            expect(
              find
                  .descendant(
                    of: find.byType(pageType),
                    matching: find.text(title),
                  )
                  .hitTestable(),
              findsWidgets,
            );
            _expectNoErrors(tester, 'free shell $label ${config.label}');
          }
          expect(monetization.adsRemoved, isFalse);
          expect(monetization.boundaryCalls, 0);
        } finally {
          debugDefaultTargetPlatformOverride = originalPlatform;
        }
      },
    );
  }

  for (final (name, page, title, word) in [
    (
      'today',
      TodayScreen(onOpenMoment: () {}, onOpenRitual: () {}),
      'Keluarga Awan',
      'Keluarga',
    ),
    ('rituals', RitualsScreen(onOpenRitual: () {}), 'Kebiasaan', 'Kebiasaan'),
    ('family', const GardenScreen(), 'Keluarga', 'Keluarga'),
  ]) {
    testWidgets('responsive $name heading keeps words whole at doubled text', (
      tester,
    ) async {
      await _mount(
        tester,
        page,
        config: const _Layout(Size(320, 640), Brightness.dark, 2),
      );
      _expectUnbrokenWord(tester, find.text(title), word);
    });
  }

  testWidgets('responsive family hero keeps its name whole at doubled text', (
    tester,
  ) async {
    await _mount(
      tester,
      const GardenScreen(),
      config: const _Layout(Size(320, 640), Brightness.dark, 2),
    );
    _expectUnbrokenWord(tester, find.text('Keluarga Awan'), 'Keluarga');
  });

  testWidgets('responsive onboarding preserves whole branding and headlines', (
    tester,
  ) async {
    await _mount(
      tester,
      const OnboardingScreen(),
      config: const _Layout(Size(320, 640), Brightness.dark, 2),
    );
    _expectUnbrokenWord(tester, find.text('Arunika'), 'Arunika');
    final welcome = find.text('Simpan yang kecil.\nIngat bersama.');
    _expectUnbrokenWord(tester, welcome, 'Simpan');
    _expectUnbrokenWord(tester, welcome, 'bersama.');
    await _tap(tester, find.text('Buat ruang keluarga'));
    _expectUnbrokenWord(tester, find.text('Arunika'), 'Arunika');
    _expectUnbrokenWord(tester, find.text('Untuk keluarga kalian'), 'keluarga');
  });

  final pages = <String, Widget Function(_JournalData)>{
    'today': (_) => TodayScreen(
      onOpenMoment: () {},
      onOpenRitual: () {},
      onOpenRituals: () {},
      onOpenMoments: () {},
      onOpenGarden: () {},
    ),
    'rituals': (_) => RitualsScreen(onOpenRitual: () {}),
    'moments': (_) => MomentsScreen(onOpenMoment: () {}),
    'family': (_) => const GardenScreen(),
    'onboarding': (_) => const OnboardingScreen(),
    'onboarding-setup': (_) => const OnboardingScreen(),
    'settings': (_) => const SettingsScreen(),
    'privacy': (_) => const PrivacyScreen(),
    'help': (_) => const HelpScreen(),
    'moment-detail': (data) =>
        MomentDetailScreen(moment: data.moments.records.first),
    'main-shell': (_) => const MainShell(),
  };
  for (final size in [const Size(320, 640), const Size(390, 844)]) {
    for (final brightness in Brightness.values) {
      for (final scale in [1.0, 2.0]) {
        final config = _Layout(size, brightness, scale);
        for (final page in pages.entries) {
          testWidgets('layout ${page.key} ${config.label}', (tester) async {
            final data = _JournalData.sample();
            final harness = await _mount(
              tester,
              page.value(data),
              data: data,
              config: config,
            );
            if (page.key == 'onboarding-setup') {
              await _tap(tester, find.text('Buat ruang keluarga'));
            }
            if (_screenshots &&
                ((size.width == 390 &&
                        brightness == Brightness.light &&
                        scale == 1) ||
                    (size.width == 320 &&
                        brightness == Brightness.dark &&
                        scale == 2))) {
              await harness.capture(tester, '${page.key}-${config.label}');
            }
            _expectNoErrors(tester, '${page.key} ${config.label} initial');
            await _sweep(tester, '${page.key} ${config.label}');
          });
        }
      }
    }
  }
}

class _Layout {
  const _Layout(this.size, this.brightness, this.scale);
  final Size size;
  final Brightness brightness;
  final double scale;
  String get label =>
      '${size.width.toInt()}x${size.height.toInt()}-${brightness.name}-${scale.toInt()}x';
}

class _Harness {
  _Harness(this.prefs, this.boundary);
  final SharedPreferences prefs;
  final GlobalKey boundary;

  Future<void> capture(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    final renderer =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final png = renderer.toImageSync(pixelRatio: 2);
      final bytes = await png.toByteData(format: ui.ImageByteFormat.png);
      png.dispose();
      final directory = Directory(_screenshotDirectory);
      await directory.create(recursive: true);
      await File(
        '${directory.path}/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
    });
    await tester.pump();
  }
}

Future<_Harness> _mount(
  WidgetTester tester,
  Widget page, {
  _JournalData? data,
  MonetizationController? monetization,
  _Layout config = const _Layout(Size(390, 844), Brightness.light, 1),
}) async {
  final fixture = data ?? _JournalData.sample();
  tester.view.physicalSize = config.size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({
    'family_name': 'Keluarga Awan',
    'dark_mode': config.brightness == Brightness.dark,
    'reduced_motion': true,
    'journal_reminder_hour': 19,
    'journal_reminder_minute': 30,
  });
  final prefs = await SharedPreferences.getInstance();
  final boundary = GlobalKey();
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        journalTodayProvider.overrideWithValue(fixture.today),
        familyMemberRepositoryProvider.overrideWithValue(fixture.members),
        ritualRepositoryProvider.overrideWithValue(fixture.rituals),
        momentRepositoryProvider.overrideWithValue(fixture.moments),
        monetizationProvider.overrideWith(
          () => monetization ?? _NoNativeMonetization(),
        ),
        journalReminderProvider.overrideWith(_NoNativeReminder.new),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final settings = ref.watch(settingsProvider);
          return RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.build(
                brightness: settings.darkMode
                    ? Brightness.dark
                    : Brightness.light,
              ),
              locale: const Locale('id', 'ID'),
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              supportedLocales: const [Locale('id', 'ID')],
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(config.scale)),
                child: child!,
              ),
              home: Scaffold(body: page),
            ),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  return _Harness(prefs, boundary);
}

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

void _expectUnbrokenWord(WidgetTester tester, Finder finder, String word) {
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  final start = paragraph.text.toPlainText().indexOf(word);
  expect(start, greaterThanOrEqualTo(0));
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: start + word.length),
  );
  expect(
    boxes.map((box) => box.top).toSet(),
    hasLength(1),
    reason: '$word must stay on one line without splitting inside the word.',
  );
  expect(paragraph.didExceedMaxLines, isFalse);
  expect(paragraph.textScaler.scale(14), 28);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _reveal(tester, finder);
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

Future<void> _selectTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 60; attempt++) {
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder.first);
      await tester.pumpAndSettle();
      if (finder.hitTestable().evaluate().isNotEmpty) return;
    }
    final scroll = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    final next = math.min(
      scroll.maxScrollExtent,
      scroll.pixels + scroll.viewportDimension * .65,
    );
    if (next == scroll.pixels) break;
    scroll.jumpTo(next);
    await tester.pumpAndSettle();
  }
  expect(
    finder.hitTestable(),
    findsWidgets,
    reason: 'Control must be reachable by scrolling.',
  );
}

Future<void> _sweep(WidgetTester tester, String description) async {
  final candidates = tester.stateList<ScrollableState>(find.byType(Scrollable));
  if (candidates.isEmpty) return;
  final scroll = candidates.first.position;
  var step = 0;
  while (step++ < 80) {
    final next = math.min(
      scroll.maxScrollExtent,
      scroll.pixels + scroll.viewportDimension * .7,
    );
    if (next <= scroll.pixels) break;
    scroll.jumpTo(next);
    await tester.pumpAndSettle();
    _expectNoErrors(tester, '$description at scroll ${scroll.pixels.toInt()}');
  }
}

void _expectNoErrors(WidgetTester tester, String description) {
  expect(tester.takeException(), isNull, reason: description);
}

class _NoNativeMonetization extends MonetizationController {
  @override
  MonetizationState build() => const MonetizationState(
    adsRemoved: true,
    isVerifying: false,
    storeAvailable: false,
  );
  @override
  Future<void> showPrivacyOptions() async {}
}

class _RecordingMonetization extends _NoNativeMonetization {
  _RecordingMonetization({this.adsRemoved = true});
  final bool adsRemoved;
  var boundaryCalls = 0;
  final presentationChecks = <bool>[];
  bool Function()? canPresent;

  @override
  MonetizationState build() => MonetizationState(
    adsRemoved: adsRemoved,
    isVerifying: false,
    storeAvailable: false,
  );

  @override
  Future<bool> onMomentSavedAndReturned({
    required bool Function() canPresent,
  }) async {
    boundaryCalls++;
    this.canPresent = canPresent;
    presentationChecks.add(canPresent());
    return false;
  }
}

class _NoNativeReminder extends JournalReminderController {
  _NoNativeReminder(super.ref);
  @override
  Future<void> sync() async {}
  @override
  Future<bool> setEnabled(bool enabled) async => true;
  @override
  Future<bool> setTime({required int hour, required int minute}) async => true;
}

class _JournalData {
  _JournalData.empty({DateTime? today})
    : today = DateUtils.dateOnly(today ?? DateTime(2026, 9, 5));
  factory _JournalData.sample({DateTime? today}) {
    final data = _JournalData.empty(today: today);
    final day = data.today.weekday;
    final otherDay = day == 7 ? 1 : day + 1;
    data.members.records.addAll(const [
      FamilyMember(id: 'nara', name: 'Nara', createdAt: 1),
      FamilyMember(id: 'ibu', name: 'Ibu', role: 'parent', createdAt: 2),
      FamilyMember(id: 'ayah', name: 'Ayah', role: 'parent', createdAt: 3),
    ]);
    data.rituals.records.addAll([
      Ritual(
        id: 'walk',
        title: 'Jalan sebentar',
        description: 'Menghirup udara sore dan mencari bentuk awan bersama.',
        timeOfDay: RitualTimeOfDay.afternoon,
        repeatDays: {day},
        createdAt: 1,
      ),
      Ritual(
        id: 'gratitude',
        title: 'Tiga hal yang disyukuri',
        description:
            'Masing-masing bercerita tentang satu hal kecil yang terasa baik.',
        timeOfDay: RitualTimeOfDay.evening,
        createdAt: 2,
      ),
      Ritual(
        id: 'off-day',
        title: 'Rapikan kebun bersama',
        description: 'Memberi ruang bagi daun dan cerita baru.',
        repeatDays: {otherDay},
        createdAt: 3,
      ),
      Ritual(
        id: 'archived',
        title: 'Menyiram tanaman pagi',
        isArchived: true,
        createdAt: 4,
      ),
    ]);
    data.rituals.checkIns.addAll([
      RitualCheckIn(
        ritualId: 'gratitude',
        dayKey: ritualDayKey(data.today),
        completedAt: data.today.add(const Duration(hours: 8)),
      ),
      RitualCheckIn(
        ritualId: 'walk',
        dayKey: ritualDayKey(data.today.subtract(const Duration(days: 1))),
        completedAt: data.today.subtract(const Duration(hours: 8)),
      ),
    ]);
    data.moments.records.addAll([
      Moment(
        id: 'picnic',
        title: 'Piknik kecil di teras',
        note:
            'Hujan mengubah rencana, jadi kami menggelar tikar di teras. Nara membagi potongan mangga dan menamai setiap awan yang lewat. Ternyata sore yang sederhana bisa terasa seperti liburan.',
        tag: MomentTag.together,
        memberId: 'nara',
        capturedAt: data.today.add(const Duration(hours: 9)),
        createdAt: 3,
      ),
      Moment(
        id: 'thanks',
        title: 'Terima kasih untuk hari ini',
        note:
            'Sebelum tidur, kami bergantian mengucapkan terima kasih. Ibu bersyukur untuk meja makan yang ramai. Nara bersyukur karena masih ada satu cerita lagi.',
        tag: MomentTag.gratitude,
        memberId: 'ibu',
        capturedAt: data.today.subtract(const Duration(days: 1)),
        createdAt: 2,
      ),
      Moment(
        id: 'laugh',
        title: 'Pancake berbentuk bulan',
        note:
            'Pancake pertama bentuknya miring. Kami menamainya bulan sabit dan tertawa sampai adonan berikutnya hampir lupa dibalik.',
        tag: MomentTag.laugh,
        memberId: 'nara',
        capturedAt: data.today.subtract(const Duration(days: 3)),
        createdAt: 1,
      ),
    ]);
    return data;
  }
  final DateTime today;
  final members = _MemoryMembers();
  final rituals = _MemoryRituals();
  final moments = _MemoryMoments();
}

class _MemoryMembers extends FamilyMemberRepository {
  final records = <FamilyMember>[];
  int insertCalls = 0;
  @override
  Future<List<FamilyMember>> getAll() async => [...records];
  @override
  Future<void> insert(FamilyMember member) async {
    insertCalls++;
    records.removeWhere((record) => record.id == member.id);
    records.add(member);
  }

  @override
  Future<void> update(FamilyMember member) async {
    records.removeWhere((record) => record.id == member.id);
    records.add(member);
  }

  @override
  Future<void> delete(String id) async =>
      records.removeWhere((record) => record.id == id);
}

class _MemoryRituals extends RitualRepository {
  final records = <Ritual>[];
  final checkIns = <RitualCheckIn>[];
  bool failCheck = false;
  bool failSave = false;
  @override
  Future<List<Ritual>> getAll({bool includeArchived = false}) async =>
      records.where((record) => includeArchived || !record.isArchived).toList();
  @override
  Future<List<RitualCheckIn>> getCheckIns({int? limit}) async =>
      limit == null ? [...checkIns] : checkIns.take(limit).toList();
  @override
  Future<Set<String>> getCompletedIdsFor(DateTime date) async => checkIns
      .where((entry) => entry.dayKey == ritualDayKey(date))
      .map((entry) => entry.ritualId)
      .toSet();
  @override
  Future<void> save(Ritual ritual) async {
    if (failSave) throw StateError('Synthetic storage failure');
    records.removeWhere((record) => record.id == ritual.id);
    records.add(ritual);
  }

  @override
  Future<void> insertStartersIfMissing(List<Ritual> starters) async {
    if (failSave) throw StateError('Synthetic storage failure');
    for (final starter in starters) {
      if (records.any(
        (record) =>
            record.id == starter.id ||
            record.title.trim().toLowerCase() ==
                starter.title.trim().toLowerCase(),
      )) {
        continue;
      }
      records.add(starter);
    }
  }

  @override
  Future<void> setCheckIn(
    String ritualId,
    DateTime date,
    bool completed,
  ) async {
    if (failCheck) throw StateError('Synthetic storage failure');
    final key = ritualDayKey(date);
    checkIns.removeWhere(
      (entry) => entry.ritualId == ritualId && entry.dayKey == key,
    );
    if (completed) {
      checkIns.add(
        RitualCheckIn(ritualId: ritualId, dayKey: key, completedAt: date),
      );
    }
  }
}

class _MemoryMoments extends MomentRepository {
  final records = <Moment>[];
  var failSave = false;
  var saveCalls = 0;
  Future<void>? saveBarrier;
  @override
  Future<List<Moment>> getAll() async =>
      [...records]..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
  @override
  Future<List<Moment>> getRecent({int? limit}) async {
    final all = await getAll();
    return limit == null ? all : all.take(limit).toList();
  }

  @override
  Future<void> save(Moment moment) async {
    saveCalls++;
    if (failSave) throw StateError('Synthetic storage failure');
    await saveBarrier;
    records.removeWhere((record) => record.id == moment.id);
    records.add(moment);
  }

  @override
  Future<void> delete(String id) async =>
      records.removeWhere((record) => record.id == id);
}
