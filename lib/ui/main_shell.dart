import 'package:flutter/material.dart';
import 'pos_screen.dart';
import 'history_screen.dart';
import 'stock_screen.dart';
import 'laporan_screen.dart';
import 'manage_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  // GlobalKey untuk memanggil refreshProducts() di PosScreen
  final _posKey = GlobalKey<PosScreenState>();

  late final List<Widget> _screens = [
    PosScreen(key: _posKey),
    const HistoryScreen(),
    const LaporanScreen(),
    const StockScreen(),
  ];

  Future<void> _openManage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManageScreen()),
    );
    // Refresh produk di Kasir setelah kembali dari Kelola Produk
    _posKey.currentState?.refreshProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // rail tidak ikut menyusut saat keyboard muncul
      body: Row(
        children: [
          _buildRail(),
          const VerticalDivider(
              width: 1, thickness: 1, color: Color(0xFF2E7D32)),
          Expanded(
            child: _screens[_index],
          ),
        ],
      ),
    );
  }

  Widget _buildRail() {
    return Column(
      children: [
        Expanded(
          child: NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            backgroundColor: const Color(0xFF1B5E20),
            selectedIconTheme:
                const IconThemeData(color: Colors.white, size: 22),
            unselectedIconTheme:
                const IconThemeData(color: Colors.white60, size: 20),
            selectedLabelTextStyle: const TextStyle(
                color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            unselectedLabelTextStyle:
                const TextStyle(color: Colors.white60, fontSize: 10),
            indicatorColor: Colors.white24,
            labelType: NavigationRailLabelType.all,
            minWidth: 60,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.point_of_sale_outlined),
                selectedIcon: Icon(Icons.point_of_sale),
                label: Text('Kasir'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: Text('Riwayat'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: Text('Laporan'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: Text('Stok'),
              ),
            ],
          ),
        ),
        // Kelola Produk di bawah rail
        Container(
          color: const Color(0xFF1B5E20),
          width: 60,
          child: Tooltip(
            message: 'Kelola Produk',
            preferBelow: false,
            child: InkWell(
              onTap: _openManage,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Divider(color: Colors.white24, height: 1),
                    SizedBox(height: 8),
                    Icon(Icons.tune, color: Colors.white60, size: 20),
                    SizedBox(height: 3),
                    Text('Produk',
                        style:
                            TextStyle(color: Colors.white60, fontSize: 10)),
                    SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
