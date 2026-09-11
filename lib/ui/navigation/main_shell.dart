import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/together_providers.dart';
import '../../state/journal_reminder_provider.dart';
import '../../state/monetization_provider.dart';
import '../monetization/stable_banner_ad.dart';
import '../together/garden_screen.dart';
import '../together/moment_editor_screen.dart';
import '../together/moments_screen.dart';
import '../together/ritual_editor_sheet.dart';
import '../together/rituals_screen.dart';
import '../together/today_screen.dart';
import '../widgets/journal_components.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});
  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  var _index = 0;
  Timer? _dayTimer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleDayRefresh();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncReminder());
  }

  Future<void> _syncReminder() async {
    try {
      await ref.read(journalReminderProvider).sync();
    } catch (_) {
      /* Settings exposes a retry and keeps the user's preference. */
    }
  }

  void _scheduleDayRefresh() {
    _dayTimer?.cancel();
    final now = DateTime.now();
    _dayTimer = Timer(
      DateTime(now.year, now.month, now.day + 1).difference(now),
      () {
        _refreshDate();
        _scheduleDayRefresh();
      },
    );
  }

  void _refreshDate() {
    ref.invalidate(journalTodayProvider);
    ref.invalidate(todayRitualsProvider);
    ref.invalidate(todayCompletedRitualIdsProvider);
    ref.invalidate(recapProvider);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshDate();
      _scheduleDayRefresh();
      _syncReminder();
      ref.read(monetizationProvider.notifier).refreshAdPause();
    }
  }

  @override
  void dispose() {
    _dayTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _select(int index) => setState(() => _index = index);
  Future<void> _openMoment() async {
    final selectedTab = _index;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const MomentEditorScreen()),
    );
    if (!mounted || saved != true) return;
    await ref
        .read(monetizationProvider.notifier)
        .onMomentSavedAndReturned(
          canPresent: () =>
              mounted &&
              _index == selectedTab &&
              (ModalRoute.of(context)?.isCurrent ?? false) &&
              WidgetsBinding.instance.lifecycleState ==
                  AppLifecycleState.resumed,
        );
  }

  void _openRitual() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    enableDrag: false,
    isDismissible: false,
    builder: (_) => const RitualEditorSheet(),
  );
  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(journalStorageWarningProvider, (_, warning) {
      if (warning == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        journalMessage(context, warning);
        ref.read(journalStorageWarningProvider.notifier).state = null;
      });
    });
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(0);
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: MainShellLayout(
            banner: const StableBannerAd(placement: BannerPlacement.mainShell),
            content: IndexedStack(
              index: _index,
              children: [
                TodayScreen(
                  onOpenMoment: _openMoment,
                  onOpenRitual: _openRitual,
                  onOpenRituals: () => _select(1),
                  onOpenMoments: () => _select(2),
                  onOpenGarden: () => _select(3),
                ),
                RitualsScreen(onOpenRitual: _openRitual),
                MomentsScreen(onOpenMoment: _openMoment),
                const GardenScreen(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _select,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.wb_sunny_outlined),
              selectedIcon: Icon(Icons.wb_sunny_rounded),
              label: 'Hari ini',
            ),
            NavigationDestination(
              icon: Icon(Icons.checklist_rounded),
              label: 'Kebiasaan',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_stories_outlined),
              selectedIcon: Icon(Icons.auto_stories),
              label: 'Momen',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Keluarga',
            ),
          ],
        ),
      ),
    );
  }
}

class MainShellLayout extends StatelessWidget {
  const MainShellLayout({
    super.key,
    required this.banner,
    required this.content,
  });
  final Widget banner;
  final Widget content;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      banner,
      Expanded(child: content),
    ],
  );
}
