import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/premium_nav.dart';
import '../../state/providers.dart';
import '../charts/growth_charts_screen.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../measure/add_measurement_screen.dart';
import '../menu/menu_screen.dart';
import '../monetization/stable_banner_ad.dart';

/// Kerangka utama: 4 tab + tombol emas tengah untuk tambah pengukuran.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  var _index = 0;

  static const _items = [
    NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Beranda',
    ),
    NavItem(
      icon: Icons.show_chart_rounded,
      activeIcon: Icons.insights_rounded,
      label: 'Grafik',
    ),
    NavItem(
      icon: Icons.history_rounded,
      activeIcon: Icons.history_toggle_off_rounded,
      label: 'Riwayat',
    ),
    NavItem(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'Menu',
    ),
  ];

  static const _pages = [
    HomeScreen(),
    GrowthChartsScreen(),
    HistoryScreen(),
    MenuScreen(),
  ];

  Future<void> _openAddMeasurement() async {
    final child = ref.read(selectedChildProvider);
    if (child == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan profil anak terlebih dahulu.')),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddMeasurementScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(index: _index, children: _pages),
          ),
          const StableBannerAd(placement: BannerPlacement.mainShell),
        ],
      ),
      floatingActionButton: GoldFab(onPressed: _openAddMeasurement),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: PremiumNavBar(
        items: _items,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
