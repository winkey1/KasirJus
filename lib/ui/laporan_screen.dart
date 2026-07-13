import 'package:flutter/material.dart';
import '../database/transaction_dao.dart';
import '../database/stock_dao.dart';
import '../utils/currency.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  final _txDao = TransactionDao();
  final _stockDao = StockDao();

  // Default: kemarin
  late DateTime _selectedDate;

  // Data
  int _totalPendapatan = 0;
  List<Map<String, dynamic>> _itemSummary = [];
  Map<String, int> _cupUsage = {};
  int _indomieUsage = 0;
  int _gulaUsage = 0;
  List<Map<String, dynamic>> _stockLog = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().subtract(const Duration(days: 1));
    _load();
  }

  String get _datePrefix {
    final d = _selectedDate;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _txDao.getTotalByDate(_datePrefix),
      _txDao.getItemSummaryByDate(_datePrefix),
      _txDao.getCupUsageByDate(_datePrefix),
      _txDao.getIndomieUsageByDate(_datePrefix),
      _stockDao.getGulaAddedByDate(_datePrefix),
      _stockDao.getLogByDate(_datePrefix),
    ]);
    if (!mounted) return;
    setState(() {
      _totalPendapatan = results[0] as int;
      _itemSummary = results[1] as List<Map<String, dynamic>>;
      _cupUsage = results[2] as Map<String, int>;
      _indomieUsage = results[3] as int;
      _gulaUsage = results[4] as int;
      _stockLog = results[5] as List<Map<String, dynamic>>;
      _loading = false;
    });
  }

  void _prevDay() {
    setState(() =>
        _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
    _load();
  }

  void _nextDay() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    if (_selectedDate.isBefore(
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day))) {
      setState(() =>
          _selectedDate = _selectedDate.add(const Duration(days: 1)));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F0),
      appBar: AppBar(
        title: const Text('Laporan Harian'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          _buildDateNav(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        _buildRevenueCard(),
                        const SizedBox(height: 10),
                        _buildItemCard(),
                        const SizedBox(height: 10),
                        _buildBahanCard(),
                        if (_stockLog.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _buildStockLogCard(),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Navigasi Tanggal ─────────────────────────────────────────
  Widget _buildDateNav() {
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
    final isYesterday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day - 1;

    String label;
    if (isToday) {
      label = 'Hari Ini';
    } else if (isYesterday) {
      label = 'Kemarin';
    } else {
      label = '${_selectedDate.day.toString().padLeft(2, '0')} '
          '${_bulanSingkat(_selectedDate.month)} '
          '${_selectedDate.year}';
    }

    return Container(
      color: const Color(0xFF2E7D32).withAlpha(15),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: const Color(0xFF2E7D32),
            onPressed: _prevDay,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF1B5E20),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: isToday ? Colors.grey : const Color(0xFF2E7D32),
            onPressed: isToday ? null : _nextDay,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  // ─── Kartu Pendapatan ─────────────────────────────────────────
  Widget _buildRevenueCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.payments_outlined,
                color: Colors.white70, size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Pendapatan',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(
                  formatRupiah(_totalPendapatan),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Item Terjual ─────────────────────────────────────────────
  Widget _buildItemCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.receipt_long,
                    color: Color(0xFF2E7D32), size: 18),
                SizedBox(width: 8),
                Text('Item Terjual',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                        fontSize: 14)),
              ],
            ),
            const Divider(height: 14),
            if (_itemSummary.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Tidak ada transaksi',
                      style: TextStyle(color: Colors.grey)),
                ),
              )
            else ...[
              const _ItemRow(
                  name: 'Produk',
                  qty: 'Qty',
                  harga: 'Total',
                  isHeader: true),
              const Divider(height: 8),
              ..._itemSummary.map((r) => _ItemRow(
                    name: r['product_name'] as String,
                    qty: '${r['total_qty']}x',
                    harga: formatRupiah(r['total_harga'] as int),
                  )),
              const Divider(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(formatRupiah(_totalPendapatan),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                          fontSize: 15)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Penggunaan Bahan ─────────────────────────────────────────
  Widget _buildBahanCard() {
    final totalCup =
        (_cupUsage['J'] ?? 0) + (_cupUsage['M'] ?? 0) + (_cupUsage['S'] ?? 0);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.local_drink,
                    color: Color(0xFF2E7D32), size: 18),
                SizedBox(width: 8),
                Text('Penggunaan Bahan',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                        fontSize: 14)),
              ],
            ),
            const Divider(height: 14),
            // Cup usage
            _BahanRow(
                icon: Icons.local_drink,
                label: 'Cup Jumbo (J)',
                value: '${_cupUsage['J'] ?? 0} pcs'),
            _BahanRow(
                icon: Icons.local_drink,
                label: 'Cup Medium (M)',
                value: '${_cupUsage['M'] ?? 0} pcs'),
            _BahanRow(
                icon: Icons.local_drink,
                label: 'Cup Small (S)',
                value: '${_cupUsage['S'] ?? 0} pcs'),
            _BahanRow(
                icon: Icons.local_drink,
                label: 'Total Cup',
                value: '$totalCup pcs',
                isBold: true),
            const Divider(height: 12),
            _BahanRow(
                icon: Icons.ramen_dining,
                label: 'Mie Indomie',
                value: '$_indomieUsage bungkus'),
            const Divider(height: 12),
            _BahanRow(
                icon: Icons.water_drop,
                label: 'Gula Terpakai',
                value: '$_gulaUsage kg',
                iconColor: Colors.orange),
          ],
        ),
      ),
    );
  }

  // ─── Catatan Stok ─────────────────────────────────────────────
  Widget _buildStockLogCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.edit_note,
                    color: Color(0xFF2E7D32), size: 18),
                SizedBox(width: 8),
                Text('Catatan Stok',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                        fontSize: 14)),
              ],
            ),
            const Divider(height: 14),
            ..._stockLog.map((log) {
              final qty = log['qty'] as int;
              final label = log['stock_label'] as String? ??
                  log['stock_name'] as String;
              final note = log['note'] as String? ?? '';
              final time = DateTime.tryParse(log['created_at'] as String);
              final jam = time != null
                  ? '${time.hour.toString().padLeft(2, '0')}:'
                      '${time.minute.toString().padLeft(2, '0')}'
                  : '';
              final isReduction = qty < 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      isReduction ? Icons.remove_circle : Icons.add_circle,
                      color: isReduction ? Colors.red : Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$label  ${isReduction ? '' : '+'}$qty',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isReduction ? Colors.red : Colors.green,
                            ),
                          ),
                          if (note.isNotEmpty)
                            Text(note,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Text(jam,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _bulanSingkat(int m) {
    const b = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return b[m];
  }
}

// ─── Widgets helper ───────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final String name, qty, harga;
  final bool isHeader;
  const _ItemRow({
    required this.name,
    required this.qty,
    required this.harga,
    this.isHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
      fontSize: isHeader ? 11 : 13,
      color: isHeader ? Colors.grey.shade600 : Colors.black87,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(name, style: style)),
          SizedBox(
              width: 38,
              child: Text(qty,
                  style: style, textAlign: TextAlign.center)),
          SizedBox(
              width: 90,
              child: Text(harga,
                  style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _BahanRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool isBold;
  final Color iconColor;
  const _BahanRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isBold = false,
    this.iconColor = const Color(0xFF2E7D32),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontWeight:
                        isBold ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13)),
          ),
          Text(value,
              style: TextStyle(
                  fontWeight:
                      isBold ? FontWeight.bold : FontWeight.w600,
                  color: iconColor,
                  fontSize: 13)),
        ],
      ),
    );
  }
}
